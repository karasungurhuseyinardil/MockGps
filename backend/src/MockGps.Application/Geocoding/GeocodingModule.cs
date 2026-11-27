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
    Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, CancellationToken ct);
    Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct);
}

public record GeocodingSearchQuery(string Q, string? Lang, int Limit = 5);
public record GeocodingReverseQuery(double Lat, double Lng, string? Lang);

public class GeocodingSearchValidator : AbstractValidator<GeocodingSearchQuery>
{
    public GeocodingSearchValidator()
    {
        RuleFor(x => x.Q).NotEmpty().MinimumLength(2).MaximumLength(200);
        RuleFor(x => x.Lang).OneOf(Languages.All);
        RuleFor(x => x.Limit).InclusiveBetween(1, 10);
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
        var key = $"geo:s:{provider.Name}:{lang}:{query.Limit}:{normalized}";
        if (cache.TryGetValue(key, out IReadOnlyList<GeocodingResult>? cached) && cached is not null) return cached;

        var results = await provider.SearchAsync(normalized, lang, query.Limit, ct);
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

    private async Task EnsureEnabledAsync(CancellationToken ct)
    {
        if (!(await systemSettings.GetAsync(ct)).GeocodingEnabled)
            throw new ServiceUnavailableException("Address search is temporarily disabled.", "geocoding_disabled");
    }
}
