using System.Globalization;
using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using MockGps.Application.Common;
using MockGps.Application.SystemSettings;
using MockGps.Domain;

namespace MockGps.Application.Geocoding;

public record GeocodingResult(
    string Name,
    string Label,
    double Latitude,
    double Longitude,
    string? City,
    string? Country,
    string? Type);

public interface IGeocodingProvider
{
    string Name { get; }
    /// <param name="near">Optional bias point: results close to it rank higher. Providers without support ignore it.</param>
    Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, GeoPoint? near, CancellationToken ct);
    Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct);
}

public readonly record struct GeoPoint(double Latitude, double Longitude);

public record GeocodingSearchQuery(string Q, string? Lang, int Limit = 5, double? Lat = null, double? Lng = null);
public record GeocodingReverseQuery(double Lat, double Lng, string? Lang);

public class GeocodingSearchValidator : AbstractValidator<GeocodingSearchQuery>
{
    public GeocodingSearchValidator()
    {
        RuleFor(x => x.Q).NotEmpty().MinimumLength(2).MaximumLength(200);
        RuleFor(x => x.Lang).OneOf(Languages.All);
        RuleFor(x => x.Limit).InclusiveBetween(1, 10);
        RuleFor(x => x.Lat).InclusiveBetween(-90, 90).WithMessage("Latitude must be between -90 and 90.");
        RuleFor(x => x.Lng).InclusiveBetween(-180, 180).WithMessage("Longitude must be between -180 and 180.");
        RuleFor(x => x.Lng).NotNull().When(x => x.Lat is not null).WithMessage("Pass lat and lng together.");
        RuleFor(x => x.Lat).NotNull().When(x => x.Lng is not null).WithMessage("Pass lat and lng together.");
    }
}

public class GeocodingReverseValidator : AbstractValidator<GeocodingReverseQuery>
{
    public GeocodingReverseValidator()
    {
        RuleFor(x => x.Lat).ValidLatitude();
        RuleFor(x => x.Lng).ValidLongitude();
        RuleFor(x => x.Lang).OneOf(Languages.All);
    }
}

public interface IGeocodingService
{
    Task<IReadOnlyList<GeocodingResult>> SearchAsync(GeocodingSearchQuery query, CancellationToken ct);
    Task<GeocodingResult?> ReverseAsync(GeocodingReverseQuery query, CancellationToken ct);
}

/// <summary>Cached proxy in front of the configured geocoding provider.</summary>
public sealed class GeocodingService(
    IGeocodingProvider provider,
    IMemoryCache cache,
    ISystemSettingsProvider systemSettings,
    IRequestValidator validator) : IGeocodingService
{
    private static readonly TimeSpan Ttl = TimeSpan.FromHours(24);

    public async Task<IReadOnlyList<GeocodingResult>> SearchAsync(GeocodingSearchQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        await EnsureEnabledAsync(ct);
        var lang = query.Lang ?? Languages.English;
        var normalized = string.Join(' ', query.Q.Trim().ToLowerInvariant().Split(' ', StringSplitOptions.RemoveEmptyEntries));
        // The bias point is rounded to ~10 km: precise enough to rank nearby places first, coarse enough to keep the cache useful.
        GeoPoint? near = query is { Lat: { } lat, Lng: { } lng } ? new GeoPoint(Math.Round(lat, 1), Math.Round(lng, 1)) : null;
        var nearKey = near is { } n ? string.Create(CultureInfo.InvariantCulture, $"{n.Latitude}:{n.Longitude}") : "-";
        var key = $"geo:s:{provider.Name}:{lang}:{query.Limit}:{nearKey}:{normalized}";
        if (cache.TryGetValue(key, out IReadOnlyList<GeocodingResult>? cached) && cached is not null) return cached;

        // Over-fetch so that removing duplicates still fills the requested limit.
        var raw = await provider.SearchAsync(normalized, lang, Math.Min(query.Limit * 2, 20), near, ct);
        var results = Deduplicate(raw).Take(query.Limit).ToList();
        cache.Set(key, results, new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = Ttl, Size = 1 });
        return results;
    }

    public async Task<GeocodingResult?> ReverseAsync(GeocodingReverseQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        await EnsureEnabledAsync(ct);
        var lang = query.Lang ?? Languages.English;
        // ~1 m precision is enough for an address and makes the cache effective.
        var lat = Math.Round(query.Lat, 5);
        var lng = Math.Round(query.Lng, 5);
        var key = string.Create(CultureInfo.InvariantCulture, $"geo:r:{provider.Name}:{lang}:{lat}:{lng}");
        if (cache.TryGetValue(key, out GeocodingResult? cached)) return cached;

        var result = await provider.ReverseAsync(lat, lng, lang, ct);
        cache.Set(key, result, new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = Ttl, Size = 1 });
        return result;
    }

    /// <summary>
    /// OSM often has the same place as a node and a relation (e.g. a town's centre point and its boundary).
    /// Entries with the same label are kept once, in provider order.
    /// </summary>
    internal static IEnumerable<GeocodingResult> Deduplicate(IEnumerable<GeocodingResult> results)
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in results)
            if (seen.Add(r.Label.Length > 0 ? r.Label : r.Name)) yield return r;
    }

    private async Task EnsureEnabledAsync(CancellationToken ct)
    {
        if (!(await systemSettings.GetAsync(ct)).GeocodingEnabled)
            throw new ServiceUnavailableException("Address search is temporarily disabled.", "geocoding_disabled");
    }
}
