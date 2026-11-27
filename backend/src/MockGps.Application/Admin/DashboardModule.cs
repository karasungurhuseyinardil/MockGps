using System.Diagnostics;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Application.Geocoding;
using MockGps.Application.SystemSettings;
using MockGps.Domain;

namespace MockGps.Application.Admin;

public record DashboardSummary(
    int TotalUsers,
    int NewUsersToday,
    int ActiveUsers24h,
    int ActiveUsers30d,
    int InactiveUsers,
    long TotalSimulations,
    long SimulationsToday,
    int TotalFavorites,
    int TotalRoutes,
    int NewContactMessages);

public record TimeseriesPoint(DateTime Bucket, long Value);

public record FeatureUsageItem(string EventType, long Count);

public record HealthCheckItem(string Name, string Status, long? LatencyMs, string? Detail);

public record SystemHealth(string Status, IReadOnlyList<HealthCheckItem> Checks, string ApiVersion, DateTimeOffset ServerTime, TimeSpan Uptime, bool MaintenanceMode);

public class TimeseriesQuery
{
    public string Metric { get; set; } = "new_users";
    public string Granularity { get; set; } = "day";
    public DateTimeOffset? From { get; set; }
    public DateTimeOffset? To { get; set; }
}

public class TimeseriesQueryValidator : AbstractValidator<TimeseriesQuery>
{
    public static readonly IReadOnlyList<string> Metrics = ["new_users", "active_users", "simulations"];
    public static readonly IReadOnlyList<string> Granularities = ["day", "month"];

    public TimeseriesQueryValidator()
    {
        RuleFor(x => x.Metric).OneOfRequired(Metrics);
        RuleFor(x => x.Granularity).OneOfRequired(Granularities);
        RuleFor(x => x).Must(x => x.From is null || x.To is null || x.From <= x.To).WithMessage("'from' must be before 'to'.");
    }
}

public interface IDashboardService
{
    Task<DashboardSummary> GetSummaryAsync(CancellationToken ct);
    Task<IReadOnlyList<TimeseriesPoint>> GetTimeseriesAsync(TimeseriesQuery query, CancellationToken ct);
    Task<IReadOnlyList<FeatureUsageItem>> GetFeatureUsageAsync(DateTimeOffset? from, DateTimeOffset? to, CancellationToken ct);
    Task<SystemHealth> GetSystemHealthAsync(CancellationToken ct);
}

public sealed class DashboardService(
    IAppDbContext db,
    IAuthAdminClient authAdmin,
    IGeocodingProvider geocodingProvider,
    ISystemSettingsProvider systemSettings,
    IRequestValidator validator,
    TimeProvider clock) : IDashboardService
{
    // Process start, not first use of this class (static fields initialise lazily).
    private static readonly DateTimeOffset StartedAt = new(Process.GetCurrentProcess().StartTime.ToUniversalTime(), TimeSpan.Zero);

    public async Task<DashboardSummary> GetSummaryAsync(CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var today = new DateTimeOffset(now.UtcDateTime.Date, TimeSpan.Zero);
        var day = now.AddHours(-24);
        var month = now.AddDays(-30);

        return new DashboardSummary(
            TotalUsers: await db.Profiles.CountAsync(ct),
            NewUsersToday: await db.Profiles.CountAsync(p => p.CreatedAt >= today, ct),
            ActiveUsers24h: await db.Profiles.CountAsync(p => p.LastSeenAt >= day, ct),
            ActiveUsers30d: await db.Profiles.CountAsync(p => p.LastSeenAt >= month, ct),
            InactiveUsers: await db.Profiles.CountAsync(p => !p.IsActive, ct),
            TotalSimulations: await db.UsageEvents.LongCountAsync(e => e.EventType == UsageEventTypes.SimulationStarted, ct),
            SimulationsToday: await db.UsageEvents.LongCountAsync(e => e.EventType == UsageEventTypes.SimulationStarted && e.CreatedAt >= today, ct),
            TotalFavorites: await db.FavoriteLocations.CountAsync(ct),
            TotalRoutes: await db.SavedRoutes.CountAsync(ct),
            NewContactMessages: await db.ContactMessages.CountAsync(m => m.Status == ContactStatuses.New, ct));
    }

    public async Task<IReadOnlyList<TimeseriesPoint>> GetTimeseriesAsync(TimeseriesQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var now = clock.GetUtcNow();
        var isDay = query.Granularity == "day";
        var to = (query.To ?? now).UtcDateTime;
        var from = (query.From ?? (isDay ? now.AddDays(-29) : now.AddMonths(-11))).UtcDateTime;

        // Cap the range so a single request cannot generate huge series.
        var maxSpan = isDay ? TimeSpan.FromDays(366) : TimeSpan.FromDays(366 * 5);
        if (to - from > maxSpan) from = to - maxSpan;

        var g = query.Granularity;
        var step = isDay ? "1 day" : "1 month";

        FormattableString sql = query.Metric switch
        {
            "new_users" => $"""
                with b as (select generate_series(date_trunc({g}, {from}::timestamp), date_trunc({g}, {to}::timestamp), {step}::interval) as bucket)
                select b.bucket as bucket, count(p.id)::bigint as value
                from b left join app.profiles p on date_trunc({g}, p.created_at at time zone 'UTC') = b.bucket
                group by b.bucket order by b.bucket
                """,
            "active_users" => $"""
                with b as (select generate_series(date_trunc({g}, {from}::timestamp), date_trunc({g}, {to}::timestamp), {step}::interval) as bucket)
                select b.bucket as bucket, count(distinct e.user_id)::bigint as value
                from b left join app.usage_events e on date_trunc({g}, e.created_at at time zone 'UTC') = b.bucket
                group by b.bucket order by b.bucket
                """,
            _ => $"""
                with b as (select generate_series(date_trunc({g}, {from}::timestamp), date_trunc({g}, {to}::timestamp), {step}::interval) as bucket)
                select b.bucket as bucket, count(e.id)::bigint as value
                from b left join app.usage_events e
                  on e.event_type = 'simulation_started' and date_trunc({g}, e.created_at at time zone 'UTC') = b.bucket
                group by b.bucket order by b.bucket
                """,
        };

        return await db.SqlQuery<TimeseriesPoint>(sql).ToListAsync(ct);
    }

    public async Task<IReadOnlyList<FeatureUsageItem>> GetFeatureUsageAsync(DateTimeOffset? from, DateTimeOffset? to, CancellationToken ct)
    {
        var start = from ?? clock.GetUtcNow().AddDays(-30);
        var end = to ?? clock.GetUtcNow();
        var rows = await db.UsageEvents.AsNoTracking()
            .Where(e => e.CreatedAt >= start && e.CreatedAt <= end)
            .GroupBy(e => e.EventType)
            .Select(g => new { g.Key, Count = g.LongCount() })
            .OrderByDescending(x => x.Count)
            .ToListAsync(ct);
        return rows.Select(x => new FeatureUsageItem(x.Key, x.Count)).ToList();
    }

    public async Task<SystemHealth> GetSystemHealthAsync(CancellationToken ct)
    {
        var checks = new List<HealthCheckItem>();

        var sw = Stopwatch.StartNew();
        try
        {
            await db.Roles.AnyAsync(ct);
            checks.Add(new("database", "healthy", sw.ElapsedMilliseconds, null));
        }
        catch (Exception e) when (e is not OperationCanceledException)
        {
            checks.Add(new("database", "unhealthy", sw.ElapsedMilliseconds, "Database query failed."));
        }

        sw.Restart();
        var authOk = await authAdmin.IsHealthyAsync(ct);
        checks.Add(new("auth", authOk ? "healthy" : "unhealthy", sw.ElapsedMilliseconds, null));
        checks.Add(new("geocoding", "configured", null, geocodingProvider.Name));

        var settings = await systemSettings.GetAsync(ct);
        var status = checks.Any(c => c.Status == "unhealthy") ? "degraded" : "healthy";
        var version = typeof(DashboardService).Assembly.GetName().Version?.ToString() ?? "1.0.0";
        return new SystemHealth(status, checks, version, clock.GetUtcNow(), DateTimeOffset.UtcNow - StartedAt, settings.MaintenanceMode);
    }
}
