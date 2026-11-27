using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MockGps.Application.Common;
using MockGps.Application.SystemSettings;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Public;

/// <summary>Map style configuration served to clients, so styles can change without an app release.</summary>
public class MapOptions
{
    public const string Section = "Map";
    public string StyleLightUrl { get; set; } = "https://tiles.openfreemap.org/styles/liberty";
    public string StyleDarkUrl { get; set; } = "https://tiles.openfreemap.org/styles/dark";
    public string StyleMinimalUrl { get; set; } = "https://tiles.openfreemap.org/styles/positron";
    /// <summary>Optional. Only set when a satellite provider key (e.g. MapTiler) is configured.</summary>
    public string? StyleSatelliteUrl { get; set; }
    public string Attribution { get; set; } = "© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors";
}

public record ReleaseDto(
    string Platform,
    string Version,
    int BuildNumber,
    int MinSupportedBuild,
    string? DownloadUrl,
    long? FileSizeBytes,
    string? ReleaseNotes,
    DateTimeOffset? PublishedAt);

public record AnnouncementDto(Guid Id, string Title, string Body, string Level, string Audience, DateTimeOffset StartsAt, DateTimeOffset? EndsAt);

public record MapConfigDto(string StyleLightUrl, string StyleDarkUrl, string StyleMinimalUrl, string? StyleSatelliteUrl, string Attribution);

public record AppConfigDto(
    bool MaintenanceMode,
    bool UpdateRequired,
    bool UpdateAvailable,
    ReleaseDto? LatestRelease,
    IReadOnlyList<AnnouncementDto> Announcements,
    MapConfigDto Map,
    bool GeocodingEnabled,
    string SupportEmail);

public record AppConfigQuery(string Platform, int? Build);

public record ContactRequest(string Name, string Email, string Subject, string Message, string? Website);

public class AppConfigQueryValidator : AbstractValidator<AppConfigQuery>
{
    public AppConfigQueryValidator()
    {
        RuleFor(x => x.Platform).OneOfRequired(Platforms.All);
        RuleFor(x => x.Build).GreaterThan(0).When(x => x.Build is not null);
    }
}

public class ContactRequestValidator : AbstractValidator<ContactRequest>
{
    public ContactRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(254);
        RuleFor(x => x.Subject).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Message).NotEmpty().MinimumLength(10).MaximumLength(5000);
    }
}

public interface IPublicService
{
    Task<AppConfigDto> GetAppConfigAsync(AppConfigQuery query, CancellationToken ct);
    Task<ReleaseDto?> GetLatestReleaseAsync(string platform, CancellationToken ct);
    Task SubmitContactAsync(ContactRequest request, CancellationToken ct);
}

public sealed class PublicService(
    IAppDbContext db,
    ISystemSettingsProvider systemSettings,
    IOptions<MapOptions> mapOptions,
    IRequestValidator validator,
    TimeProvider clock) : IPublicService
{
    public async Task<AppConfigDto> GetAppConfigAsync(AppConfigQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var settings = await systemSettings.GetAsync(ct);
        var latest = Platforms.Mobile.Contains(query.Platform) ? await GetLatestReleaseAsync(query.Platform, ct) : null;
        var now = clock.GetUtcNow();

        var announcements = await db.Announcements.AsNoTracking()
            .Where(a => a.IsActive && a.StartsAt <= now && (a.EndsAt == null || a.EndsAt > now)
                        && (a.Audience == AnnouncementAudiences.All || a.Audience == query.Platform))
            .OrderByDescending(a => a.StartsAt)
            .Take(5)
            .Select(a => new AnnouncementDto(a.Id, a.Title, a.Body, a.Level, a.Audience, a.StartsAt, a.EndsAt))
            .ToListAsync(ct);

        var map = mapOptions.Value;
        return new AppConfigDto(
            settings.MaintenanceMode,
            UpdateRequired: latest is not null && query.Build is { } b1 && b1 < latest.MinSupportedBuild,
            UpdateAvailable: latest is not null && query.Build is { } b2 && b2 < latest.BuildNumber,
            latest,
            announcements,
            new MapConfigDto(map.StyleLightUrl, map.StyleDarkUrl, map.StyleMinimalUrl, map.StyleSatelliteUrl, map.Attribution),
            settings.GeocodingEnabled,
            settings.SupportEmail);
    }

    public Task<ReleaseDto?> GetLatestReleaseAsync(string platform, CancellationToken ct) =>
        db.AppVersions.AsNoTracking()
            .Where(v => v.Platform == platform && v.IsPublished)
            .OrderByDescending(v => v.BuildNumber)
            .Select(v => new ReleaseDto(v.Platform, v.Version, v.BuildNumber, v.MinSupportedBuild, v.DownloadUrl,
                v.FileSizeBytes, v.ReleaseNotes, v.PublishedAt))
            .FirstOrDefaultAsync(ct);

    public async Task SubmitContactAsync(ContactRequest request, CancellationToken ct)
    {
        // Honeypot: real users never fill the hidden "website" field. Pretend success for bots.
        if (!string.IsNullOrWhiteSpace(request.Website)) return;

        await validator.ValidateAsync(request, ct);
        db.ContactMessages.Add(new ContactMessage
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Email = request.Email.Trim(),
            Subject = request.Subject.Trim(),
            Message = request.Message.Trim(),
        });
        await db.SaveChangesAsync(ct);
    }
}
