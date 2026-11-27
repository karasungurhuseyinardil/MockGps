using System.Linq.Expressions;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Application.SystemSettings;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Locations;

public record HistoryDto(Guid Id, Guid ClientId, double Latitude, double Longitude, string? Address, string Source, DateTimeOffset CreatedAt);

public record HistoryItemRequest(Guid ClientId, double Latitude, double Longitude, string? Address, string? Source, DateTimeOffset? CreatedAt);

public record HistoryBatchRequest(IReadOnlyList<HistoryItemRequest> Items);

public record HistoryBatchResult(int Received, int Inserted);

public class HistoryQuery : PageQuery
{
    public DateTimeOffset? From { get; set; }
    public DateTimeOffset? To { get; set; }
}

public class HistoryQueryValidator : PageQueryValidator<HistoryQuery>
{
    public HistoryQueryValidator() =>
        RuleFor(x => x).Must(x => x.From is null || x.To is null || x.From <= x.To)
            .WithMessage("'from' must be before 'to'.");
}

public class HistoryBatchValidator : AbstractValidator<HistoryBatchRequest>
{
    public const int MaxItems = 200;

    public HistoryBatchValidator(TimeProvider clock)
    {
        RuleFor(x => x.Items).NotNull().Must(i => i.Count is > 0 and <= MaxItems)
            .WithMessage($"Send between 1 and {MaxItems} items.");
        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ClientId).NotEmpty();
            item.RuleFor(i => i.Latitude).ValidLatitude();
            item.RuleFor(i => i.Longitude).ValidLongitude();
            item.RuleFor(i => i.Address).MaximumLength(300);
            item.RuleFor(i => i.Source).OneOf(HistorySources.All);
            item.RuleFor(i => i.CreatedAt)
                .Must(d => d is null || (d <= clock.GetUtcNow().AddMinutes(5) && d >= clock.GetUtcNow().AddYears(-1)))
                .WithMessage("createdAt must be within the last year.");
        });
    }
}

public interface IHistoryService
{
    Task<PagedResult<HistoryDto>> ListAsync(HistoryQuery query, CancellationToken ct);
    Task<HistoryBatchResult> AddBatchAsync(HistoryBatchRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
    Task DeleteByClientIdAsync(Guid clientId, CancellationToken ct);
    Task<int> ClearAsync(CancellationToken ct);
}

/// <summary>
/// Cloud copy of the location history. History is local-first on the device; this service is only
/// used when the user enabled cloud sync.
/// </summary>
public sealed class HistoryService(
    IUserDataScope scope,
    ICurrentUser currentUser,
    IRequestValidator validator,
    ISystemSettingsProvider systemSettings,
    TimeProvider clock) : IHistoryService
{
    private static readonly Dictionary<string, Expression<Func<LocationHistoryEntry, object?>>> Sorts = new()
    {
        ["created_at"] = h => h.CreatedAt,
    };

    public async Task<PagedResult<HistoryDto>> ListAsync(HistoryQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var uid = currentUser.UserId;
        return await scope.RunAsync(ctx =>
        {
            var q = ctx.LocationHistory.AsNoTracking().Where(h => h.UserId == uid);
            if (query.From is { } from) q = q.Where(h => h.CreatedAt >= from);
            if (query.To is { } to) q = q.Where(h => h.CreatedAt <= to);
            return q.ApplySort(query.Sort, Sorts, "created_at:desc")
                .ToPagedAsync(query, h => new HistoryDto(h.Id, h.ClientId, h.Latitude, h.Longitude, h.Address, h.Source, h.CreatedAt), ct);
        }, ct);
    }

    public async Task<HistoryBatchResult> AddBatchAsync(HistoryBatchRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        var maxItems = (await systemSettings.GetAsync(ct)).HistoryMaxCloudItems;

        return await scope.RunAsync(async ctx =>
        {
            var syncEnabled = await ctx.UserSettings.Where(s => s.UserId == uid)
                .Select(s => s.HistoryEnabled && s.HistoryCloudSync).FirstOrDefaultAsync(ct);
            if (!syncEnabled)
                throw new BusinessRuleException("Cloud history sync is turned off in your settings.", "history_sync_disabled");

            // Idempotent: items already uploaded (same client id) are skipped.
            var items = request.Items.DistinctBy(i => i.ClientId).ToList();
            var clientIds = items.Select(i => i.ClientId).ToList();
            var existing = await ctx.LocationHistory
                .Where(h => h.UserId == uid && clientIds.Contains(h.ClientId))
                .Select(h => h.ClientId).ToListAsync(ct);
            var known = existing.ToHashSet();

            var now = clock.GetUtcNow();
            var toInsert = items.Where(i => !known.Contains(i.ClientId)).Select(i => new LocationHistoryEntry
            {
                Id = Guid.NewGuid(),
                UserId = uid,
                ClientId = i.ClientId,
                Latitude = Math.Round(i.Latitude, 7),
                Longitude = Math.Round(i.Longitude, 7),
                Address = Text.Clean(i.Address),
                Source = i.Source ?? HistorySources.Map,
                CreatedAt = i.CreatedAt ?? now,
            }).ToList();

            ctx.LocationHistory.AddRange(toInsert);
            await ctx.SaveChangesAsync(ct);

            // Keep only the newest N rows per user.
            var cutoff = await ctx.LocationHistory.Where(h => h.UserId == uid)
                .OrderByDescending(h => h.CreatedAt)
                .Skip(maxItems)
                .Select(h => (DateTimeOffset?)h.CreatedAt)
                .FirstOrDefaultAsync(ct);
            if (cutoff is { } c)
            {
                await ctx.LocationHistory.Where(h => h.UserId == uid && h.CreatedAt <= c).ExecuteDeleteAsync(ct);
            }

            return new HistoryBatchResult(request.Items.Count, toInsert.Count);
        }, ct);
    }

    public Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(async ctx =>
        {
            var deleted = await ctx.LocationHistory.Where(h => h.Id == id && h.UserId == uid).ExecuteDeleteAsync(ct);
            if (deleted == 0) throw new NotFoundException("History entry");
        }, ct);
    }

    public Task DeleteByClientIdAsync(Guid clientId, CancellationToken ct)
    {
        var uid = currentUser.UserId;
        // Idempotent: the device may delete an entry that was never uploaded.
        return scope.RunAsync(ctx => ctx.LocationHistory.Where(h => h.ClientId == clientId && h.UserId == uid).ExecuteDeleteAsync(ct), ct);
    }

    public Task<int> ClearAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        return scope.RunAsync(ctx => ctx.LocationHistory.Where(h => h.UserId == uid).ExecuteDeleteAsync(ct), ct);
    }
}
