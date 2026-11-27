using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Domain.Entities;

namespace MockGps.Application.Locations;

public record CategoryDto(Guid Id, string Name, string Icon, string Color, int SortOrder, int FavoriteCount);

public record CategoryRequest(string Name, string? Icon, string? Color, int? SortOrder);

public class CategoryRequestValidator : AbstractValidator<CategoryRequest>
{
    public CategoryRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(40);
        RuleFor(x => x.Icon).MaximumLength(32).Matches("^[a-z0-9_-]+$").When(x => x.Icon is not null);
        RuleFor(x => x.Color).Matches("^#[0-9A-Fa-f]{6}$").When(x => x.Color is not null)
            .WithMessage("Color must be a hex value like #3457F5.");
        RuleFor(x => x.SortOrder).InclusiveBetween(0, 10_000).When(x => x.SortOrder is not null);
    }
}

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryDto>> ListAsync(CancellationToken ct);
    Task<CategoryDto> CreateAsync(CategoryRequest request, CancellationToken ct);
    Task<CategoryDto> UpdateAsync(Guid id, CategoryRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}

public sealed class CategoryService(IUserDataScope scope, ICurrentUser currentUser, IRequestValidator validator) : ICategoryService
{
    public const int MaxCategoriesPerUser = 50;

    public Task<IReadOnlyList<CategoryDto>> ListAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync<IReadOnlyList<CategoryDto>>(async ctx => await ctx.LocationCategories.AsNoTracking()
            .Where(c => c.UserId == uid)
            .OrderBy(c => c.SortOrder).ThenBy(c => c.Name)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Color, c.SortOrder,
                ctx.FavoriteLocations.Count(f => f.CategoryId == c.Id)))
            .ToListAsync(ct), ct);
    }

    public async Task<CategoryDto> CreateAsync(CategoryRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        var name = request.Name.Trim();
        return await scope.RunAsync(async ctx =>
        {
            var existing = await ctx.LocationCategories.Where(c => c.UserId == uid).Select(c => c.Name).ToListAsync(ct);
            if (existing.Count >= MaxCategoriesPerUser)
                throw new BusinessRuleException($"You can create up to {MaxCategoriesPerUser} categories.", "category_limit");
            if (existing.Any(n => string.Equals(n, name, StringComparison.OrdinalIgnoreCase)))
                throw new ConflictException("A category with this name already exists.", "category_exists");

            var category = new LocationCategory
            {
                Id = Guid.NewGuid(),
                UserId = uid,
                Name = name,
                Icon = request.Icon ?? "pin",
                Color = request.Color?.ToUpperInvariant() ?? "#3457F5",
                SortOrder = request.SortOrder ?? existing.Count,
            };
            ctx.LocationCategories.Add(category);
            await ctx.SaveChangesAsync(ct);
            return new CategoryDto(category.Id, category.Name, category.Icon, category.Color, category.SortOrder, 0);
        }, ct);
    }

    public async Task<CategoryDto> UpdateAsync(Guid id, CategoryRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        var name = request.Name.Trim();
        return await scope.RunAsync(async ctx =>
        {
            var category = await ctx.LocationCategories.FirstOrDefaultAsync(c => c.Id == id && c.UserId == uid, ct)
                ?? throw new NotFoundException("Category");

            var duplicate = await ctx.LocationCategories
                .AnyAsync(c => c.UserId == uid && c.Id != id && c.Name.ToLower() == name.ToLower(), ct);
            if (duplicate) throw new ConflictException("A category with this name already exists.", "category_exists");

            category.Name = name;
            if (request.Icon is not null) category.Icon = request.Icon;
            if (request.Color is not null) category.Color = request.Color.ToUpperInvariant();
            if (request.SortOrder is not null) category.SortOrder = request.SortOrder.Value;
            await ctx.SaveChangesAsync(ct);

            var count = await ctx.FavoriteLocations.CountAsync(f => f.CategoryId == id, ct);
            return new CategoryDto(category.Id, category.Name, category.Icon, category.Color, category.SortOrder, count);
        }, ct);
    }

    public Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        // Favorites in this category are kept; their category becomes empty (FK ON DELETE SET NULL).
        return scope.RunAsync(async ctx =>
        {
            var deleted = await ctx.LocationCategories.Where(c => c.Id == id && c.UserId == uid).ExecuteDeleteAsync(ct);
            if (deleted == 0) throw new NotFoundException("Category");
        }, ct);
    }
}
