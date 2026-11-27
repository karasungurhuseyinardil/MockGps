using FluentValidation;
using MockGps.Application.Common;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Usage;

/// <summary>Anonymous-by-design usage events: no coordinates, only event type, platform and version.</summary>
public record UsageEventsRequest(string Platform, string? AppVersion, IReadOnlyList<string> Events);

public class UsageEventsValidator : AbstractValidator<UsageEventsRequest>
{
    public const int MaxEvents = 50;

    public UsageEventsValidator()
    {
        RuleFor(x => x.Platform).OneOfRequired(Platforms.All);
        RuleFor(x => x.AppVersion).MaximumLength(32);
        RuleFor(x => x.Events).NotNull().Must(e => e.Count is > 0 and <= MaxEvents)
            .WithMessage($"Send between 1 and {MaxEvents} events.");
        RuleForEach(x => x.Events).Must(e => UsageEventTypes.All.Contains(e))
            .WithMessage($"Unknown event type. Allowed: {string.Join(", ", UsageEventTypes.All)}.");
    }
}

public interface IUsageService
{
    Task<int> RecordAsync(UsageEventsRequest request, CancellationToken ct);
}

public sealed class UsageService(IAppDbContext db, ICurrentUser currentUser, IRequestValidator validator) : IUsageService
{
    public async Task<int> RecordAsync(UsageEventsRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        db.UsageEvents.AddRange(request.Events.Select(e => new UsageEvent
        {
            Id = Guid.NewGuid(),
            UserId = uid,
            EventType = e,
            Platform = request.Platform,
            AppVersion = request.AppVersion,
        }));
        await db.SaveChangesAsync(ct);
        return request.Events.Count;
    }
}
