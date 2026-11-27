using System.Linq.Expressions;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Domain.Entities;

namespace MockGps.Application.Locations;

public record FavoriteDto(
    Guid Id,
    string Name,
    string? Description,
    double Latitude,
    double Longitude,
    string? Address,
    Guid? CategoryId,
    string? CategoryName,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record FavoriteRequest(
    string Name,
    string? Description,
    double Latitude,
    double Longitude,
    string? Address,
    Guid? CategoryId);

public class FavoriteQuery : PageQuery
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
}

public class FavoriteRequestValidator : AbstractValidator<FavoriteRequest>
{
    public FavoriteRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(80);
        RuleFor(x => x.Description).MaximumLength(500);
        RuleFor(x => x.Address).MaximumLength(300);
        RuleFor(x => x.Latitude).ValidLatitude();
        RuleFor(x => x.Longitude).ValidLongitude();
    }
}

public class FavoriteQueryValidator : PageQueryValidator<FavoriteQuery>
{
    public FavoriteQueryValidator() => RuleFor(x => x.Search).MaximumLength(100);
}

public interface IFavoriteService
{
    Task<PagedResult<FavoriteDto>> ListAsync(FavoriteQuery query, CancellationToken ct);
    Task<FavoriteDto> GetAsync(Guid id, CancellationToken ct);
    Task<FavoriteDto> CreateAsync(FavoriteRequest request, CancellationToken ct);
    Task<FavoriteDto> UpdateAsync(Guid id, FavoriteRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}

public sealed class FavoriteService(IUserDataScope scope, ICurrentUser currentUser, IRequestValidator validator) : IFavoriteService
{
    public const int MaxFavoritesPerUser = 1000;

    private static readonly Dictionary<string, Expression<Func<FavoriteLocation, object?>>> Sorts = new()
    {
        ["name"] = f => f.Name,
        ["created_at"] = f => f.CreatedAt,
        ["updated_at"] = f => f.UpdatedAt,
    };

    private static readonly Expression<Func<FavoriteLocation, FavoriteDto>> ToDto = f => new FavoriteDto(
        f.Id, f.Name, f.Description, f.Latitude, f.Longitude, f.Address, f.CategoryId,
        f.Category != null ? f.Category.Name : null, f.CreatedAt, f.UpdatedAt);

    public async Task<PagedResult<FavoriteDto>> ListAsync(FavoriteQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var uid = currentUser.UserId;
        var search = Text.Clean(query.Search);

        return await scope.RunAsync(ctx =>
        {
            var q = ctx.FavoriteLocations.AsNoTracking().Where(f => f.UserId == uid);
            if (query.CategoryId is { } categoryId) q = q.Where(f => f.CategoryId == categoryId);
            if (search is not null)
            {
                var pattern = Text.LikePattern(search);
                q = q.Where(f => EF.Functions.ILike(f.Name, pattern, "\\")
                              || EF.Functions.ILike(f.Description ?? "", pattern, "\\")
                              || EF.Functions.ILike(f.Address ?? "", pattern, "\\"));
            }
            return q.ApplySort(query.Sort, Sorts, "created_at:desc").ToPagedAsync(query, ToDto, ct);
        }, ct);
    }

    public Task<FavoriteDto> GetAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(async ctx =>
            await ctx.FavoriteLocations.AsNoTracking().Where(f => f.Id == id && f.UserId == uid).Select(ToDto).FirstOrDefaultAsync(ct)
            ?? throw new NotFoundException("Favorite"), ct);
    }

    public async Task<FavoriteDto> CreateAsync(FavoriteRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        var id = Guid.NewGuid();
        await scope.RunAsync(async ctx =>
        {
            if (await ctx.FavoriteLocations.CountAsync(f => f.UserId == uid, ct) >= MaxFavoritesPerUser)
                throw new BusinessRuleException($"You can save up to {MaxFavoritesPerUser} favorites.", "favorite_limit");
            await EnsureCategoryAsync(ctx, uid, request.CategoryId, ct);

            var favorite = new FavoriteLocation { Id = id, UserId = uid };
            Apply(favorite, request);
            ctx.FavoriteLocations.Add(favorite);
            await ctx.SaveChangesAsync(ct);
        }, ct);
        return await GetAsync(id, ct);
    }

    public async Task<FavoriteDto> UpdateAsync(Guid id, FavoriteRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        await scope.RunAsync(async ctx =>
        {
            var favorite = await ctx.FavoriteLocations.FirstOrDefaultAsync(f => f.Id == id && f.UserId == uid, ct)
                ?? throw new NotFoundException("Favorite");
            await EnsureCategoryAsync(ctx, uid, request.CategoryId, ct);
            Apply(favorite, request);
            await ctx.SaveChangesAsync(ct);
        }, ct);
        return await GetAsync(id, ct);
    }

    public Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(async ctx =>
        {
            var deleted = await ctx.FavoriteLocations.Where(f => f.Id == id && f.UserId == uid).ExecuteDeleteAsync(ct);
            if (deleted == 0) throw new NotFoundException("Favorite");
        }, ct);
    }

    private static void Apply(FavoriteLocation f, FavoriteRequest r)
    {
        f.Name = r.Name.Trim();
        f.Description = Text.Clean(r.Description);
        f.Latitude = Math.Round(r.Latitude, 7);
        f.Longitude = Math.Round(r.Longitude, 7);
        f.Address = Text.Clean(r.Address);
        f.CategoryId = r.CategoryId;
    }

    private static async Task EnsureCategoryAsync(IAppDbContext ctx, Guid uid, Guid? categoryId, CancellationToken ct)
    {
        if (categoryId is null) return;
        if (!await ctx.LocationCategories.AnyAsync(c => c.Id == categoryId && c.UserId == uid, ct))
            throw new BusinessRuleException("The selected category does not exist.", "invalid_category");
    }
}
