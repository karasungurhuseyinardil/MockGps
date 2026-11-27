using System.Globalization;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MockGps.Application.Common;
using MockGps.Application.Geocoding;

namespace MockGps.Infrastructure.Geocoding;

public class GeocodingOptions
{
    public const string Section = "Geocoding";
    /// <summary><c>photon</c> (default), <c>nominatim</c> or <c>maptiler</c>.</summary>
    public string Provider { get; set; } = "photon";
    public string PhotonUrl { get; set; } = "https://photon.komoot.io";
    public string NominatimUrl { get; set; } = "https://nominatim.openstreetmap.org";
    public string MapTilerUrl { get; set; } = "https://api.maptiler.com";
    public string? MapTilerKey { get; set; }
    /// <summary>Identifies this application to public geocoding services (required by Nominatim policy).</summary>
    public string UserAgent { get; set; } = "MockGPS-LocationSimulation/1.0";
}

internal abstract class HttpGeocodingProvider(HttpClient http, ILogger logger) : IGeocodingProvider
{
    public abstract string Name { get; }
    public abstract Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, GeoPoint? near, CancellationToken ct);
    public abstract Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct);

    protected async Task<JsonDocument> GetJsonAsync(string url, CancellationToken ct)
    {
        try
        {
            using var response = await http.GetAsync(url, ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("{Provider} geocoding returned {Status}", Name, (int)response.StatusCode);
                throw new ExternalServiceException("Address search", string.Empty);
            }
            return await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        }
        catch (Exception e) when (e is HttpRequestException or JsonException || (e is TaskCanceledException && !ct.IsCancellationRequested))
        {
            logger.LogWarning(e, "{Provider} geocoding request failed", Name);
            throw new ExternalServiceException("Address search", string.Empty);
        }
    }

    protected static string Inv(double v) => v.ToString("0.######", CultureInfo.InvariantCulture);

    protected static string? Str(JsonElement e, string name) =>
        e.ValueKind == JsonValueKind.Object && e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;

    protected static string Label(params string?[] parts) =>
        string.Join(", ", parts.Where(p => !string.IsNullOrWhiteSpace(p)).Select(p => p!.Trim()).Distinct());
}

/// <summary>Photon (komoot) — OSM based, free, fair-use public instance or self-hosted.</summary>
internal sealed class PhotonGeocodingProvider(HttpClient http, IOptions<GeocodingOptions> options, ILogger<PhotonGeocodingProvider> logger)
    : HttpGeocodingProvider(http, logger)
{
    public override string Name => "photon";
    private string Base => options.Value.PhotonUrl.TrimEnd('/');
    // Photon supports a small set of languages; others fall back to local names.
    private static string Lang(string l) => l == "en" ? "en" : "default";

    public override async Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, GeoPoint? near, CancellationToken ct)
    {
        // zoom=10 biases towards the surrounding region (~city scale) instead of the immediate street.
        var bias = near is { } n ? $"&lat={Inv(n.Latitude)}&lon={Inv(n.Longitude)}&zoom=10" : string.Empty;
        using var doc = await GetJsonAsync($"{Base}/api/?q={Uri.EscapeDataString(query)}&limit={limit}&lang={Lang(language)}{bias}", ct);
        return Parse(doc.RootElement);
    }

    public override async Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct)
    {
        using var doc = await GetJsonAsync($"{Base}/reverse?lat={Inv(latitude)}&lon={Inv(longitude)}&lang={Lang(language)}&limit=1", ct);
        return Parse(doc.RootElement).FirstOrDefault();
    }

    private static List<GeocodingResult> Parse(JsonElement root)
    {
        var results = new List<GeocodingResult>();
        if (!root.TryGetProperty("features", out var features)) return results;
        foreach (var f in features.EnumerateArray())
        {
            if (!f.TryGetProperty("geometry", out var g) || !g.TryGetProperty("coordinates", out var c) || c.GetArrayLength() < 2) continue;
            var p = f.GetProperty("properties");
            var street = Label(Str(p, "street"), Str(p, "housenumber")).Replace(", ", " ");
            var city = Str(p, "city") ?? Str(p, "town") ?? Str(p, "village");
            var name = Str(p, "name") ?? (street.Length > 0 ? street : city) ?? "Unnamed place";
            results.Add(new GeocodingResult(
                name,
                Label(name, street, Str(p, "district"), city, Str(p, "state"), Str(p, "country")),
                c[1].GetDouble(), c[0].GetDouble(), city, Str(p, "country"), Str(p, "osm_value") ?? Str(p, "type")));
        }
        return results;
    }
}

/// <summary>Nominatim — public instance allows max 1 request/second; caching in front is mandatory.</summary>
internal sealed class NominatimGeocodingProvider(HttpClient http, IOptions<GeocodingOptions> options, ILogger<NominatimGeocodingProvider> logger)
    : HttpGeocodingProvider(http, logger)
{
    public override string Name => "nominatim";
    private string Base => options.Value.NominatimUrl.TrimEnd('/');

    public override async Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, GeoPoint? near, CancellationToken ct)
    {
        using var doc = await GetJsonAsync(
            $"{Base}/search?q={Uri.EscapeDataString(query)}&format=jsonv2&addressdetails=1&limit={limit}&accept-language={language}", ct);
        return doc.RootElement.EnumerateArray().Select(Parse).OfType<GeocodingResult>().ToList();
    }

    public override async Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct)
    {
        using var doc = await GetJsonAsync(
            $"{Base}/reverse?lat={Inv(latitude)}&lon={Inv(longitude)}&format=jsonv2&addressdetails=1&accept-language={language}", ct);
        return doc.RootElement.TryGetProperty("error", out _) ? null : Parse(doc.RootElement);
    }

    private static GeocodingResult? Parse(JsonElement e)
    {
        if (!double.TryParse(Str(e, "lat"), NumberStyles.Float, CultureInfo.InvariantCulture, out var lat) ||
            !double.TryParse(Str(e, "lon"), NumberStyles.Float, CultureInfo.InvariantCulture, out var lon)) return null;
        var address = e.TryGetProperty("address", out var a) ? a : default;
        var city = Str(address, "city") ?? Str(address, "town") ?? Str(address, "village");
        var label = Str(e, "display_name") ?? string.Empty;
        var name = Str(e, "name") is { Length: > 0 } n ? n : label.Split(',')[0];
        return new GeocodingResult(name, label, lat, lon, city, Str(address, "country"), Str(e, "type"));
    }
}

/// <summary>MapTiler Cloud geocoding — requires an API key.</summary>
internal sealed class MapTilerGeocodingProvider(HttpClient http, IOptions<GeocodingOptions> options, ILogger<MapTilerGeocodingProvider> logger)
    : HttpGeocodingProvider(http, logger)
{
    public override string Name => "maptiler";
    private string Base => options.Value.MapTilerUrl.TrimEnd('/');
    private string Key => Uri.EscapeDataString(options.Value.MapTilerKey ?? string.Empty);

    public override async Task<IReadOnlyList<GeocodingResult>> SearchAsync(string query, string language, int limit, GeoPoint? near, CancellationToken ct)
    {
        var proximity = near is { } n ? $"&proximity={Inv(n.Longitude)},{Inv(n.Latitude)}" : string.Empty;
        using var doc = await GetJsonAsync($"{Base}/geocoding/{Uri.EscapeDataString(query)}.json?key={Key}&language={language}&limit={limit}{proximity}", ct);
        return Parse(doc.RootElement);
    }

    public override async Task<GeocodingResult?> ReverseAsync(double latitude, double longitude, string language, CancellationToken ct)
    {
        using var doc = await GetJsonAsync($"{Base}/geocoding/{Inv(longitude)},{Inv(latitude)}.json?key={Key}&language={language}&limit=1", ct);
        return Parse(doc.RootElement).FirstOrDefault();
    }

    private static List<GeocodingResult> Parse(JsonElement root)
    {
        var results = new List<GeocodingResult>();
        if (!root.TryGetProperty("features", out var features)) return results;
        foreach (var f in features.EnumerateArray())
        {
            if (!f.TryGetProperty("center", out var c) || c.GetArrayLength() < 2) continue;
            string? Context(string prefix) => f.TryGetProperty("context", out var ctx)
                ? ctx.EnumerateArray().Where(x => (Str(x, "id") ?? "").StartsWith(prefix, StringComparison.Ordinal)).Select(x => Str(x, "text")).FirstOrDefault()
                : null;
            var type = f.TryGetProperty("place_type", out var pt) && pt.GetArrayLength() > 0 ? pt[0].GetString() : null;
            results.Add(new GeocodingResult(
                Str(f, "text") ?? "Unnamed place", Str(f, "place_name") ?? string.Empty,
                c[1].GetDouble(), c[0].GetDouble(), Context("municipality") ?? Context("place"), Context("country"), type));
        }
        return results;
    }
}
