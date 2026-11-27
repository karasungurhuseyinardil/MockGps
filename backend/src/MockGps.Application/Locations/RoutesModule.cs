using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Locations;

public record RouteDto(
    Guid Id,
    string Name,
    IReadOnlyList<RoutePoint> Points,
    double SpeedKmh,
    bool Loop,
    double DistanceMeters,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record RouteRequest(string Name, IReadOnlyList<RoutePoint> Points, double SpeedKmh, bool Loop);

public class RouteRequestValidator : AbstractValidator<RouteRequest>
{
    public const int MaxPoints = 500;

    public RouteRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(80);
        RuleFor(x => x.SpeedKmh).GreaterThan(0).LessThanOrEqualTo(1000);
        RuleFor(x => x.Points).NotNull().Must(p => p.Count is >= 2 and <= MaxPoints)
            .WithMessage($"A route needs between 2 and {MaxPoints} points.");
        RuleForEach(x => x.Points).ChildRules(p =>
        {
            p.RuleFor(x => x.Lat).ValidLatitude();
            p.RuleFor(x => x.Lng).ValidLongitude();
        });
    }
}

public interface IRouteService
{
    Task<IReadOnlyList<RouteDto>> ListAsync(CancellationToken ct);
    Task<RouteDto> GetAsync(Guid id, CancellationToken ct);
    Task<RouteDto> CreateAsync(RouteRequest request, CancellationToken ct);
    Task<RouteDto> UpdateAsync(Guid id, RouteRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}

public sealed class RouteService(IUserDataScope scope, ICurrentUser currentUser, IRequestValidator validator) : IRouteService
{
    public const int MaxRoutesPerUser = 200;

    public Task<IReadOnlyList<RouteDto>> ListAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync<IReadOnlyList<RouteDto>>(async ctx =>
        {
            var routes = await ctx.SavedRoutes.AsNoTracking().Where(r => r.UserId == uid)
                .OrderByDescending(r => r.UpdatedAt).ToListAsync(ct);
            return routes.Select(ToDto).ToList();
        }, ct);
    }

    public Task<RouteDto> GetAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(async ctx => ToDto(
            await ctx.SavedRoutes.AsNoTracking().FirstOrDefaultAsync(r => r.Id == id && r.UserId == uid, ct)
            ?? throw new NotFoundException("Route")), ct);
    }

    public async Task<RouteDto> CreateAsync(RouteRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        var id = Guid.NewGuid();
        await scope.RunAsync(async ctx =>
        {
            if (await ctx.SavedRoutes.CountAsync(r => r.UserId == uid, ct) >= MaxRoutesPerUser)
                throw new BusinessRuleException($"You can save up to {MaxRoutesPerUser} routes.", "route_limit");
            var route = new SavedRoute { Id = id, UserId = uid };
            Apply(route, request);
            ctx.SavedRoutes.Add(route);
            await ctx.SaveChangesAsync(ct);
        }, ct);
        return await GetAsync(id, ct);
    }

    public async Task<RouteDto> UpdateAsync(Guid id, RouteRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        await scope.RunAsync(async ctx =>
        {
            var route = await ctx.SavedRoutes.FirstOrDefaultAsync(r => r.Id == id && r.UserId == uid, ct)
                ?? throw new NotFoundException("Route");
            Apply(route, request);
            await ctx.SaveChangesAsync(ct);
        }, ct);
        return await GetAsync(id, ct);
    }

    public Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(async ctx =>
        {
            var deleted = await ctx.SavedRoutes.Where(r => r.Id == id && r.UserId == uid).ExecuteDeleteAsync(ct);
            if (deleted == 0) throw new NotFoundException("Route");
        }, ct);
    }

    private static void Apply(SavedRoute route, RouteRequest r)
    {
        route.Name = r.Name.Trim();
        route.Points = r.Points.Select(p => new RoutePoint(Math.Round(p.Lat, 7), Math.Round(p.Lng, 7))).ToList();
        route.SpeedKmh = r.SpeedKmh;
        route.Loop = r.Loop;
    }

    private static RouteDto ToDto(SavedRoute r) =>
        new(r.Id, r.Name, r.Points, r.SpeedKmh, r.Loop, Math.Round(Geo.PathLengthMeters(r.Points), 1), r.CreatedAt, r.UpdatedAt);
}
