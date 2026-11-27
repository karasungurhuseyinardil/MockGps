using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MockGps.Application.Common;
using MockGps.Domain;

namespace MockGps.Application.SystemSettings;

public sealed record RuntimeSettings(
    bool MaintenanceMode,
    bool GeocodingEnabled,
    int HistoryMaxCloudItems,
    string SupportEmail);

public interface ISystemSettingsProvider
{
    Task<RuntimeSettings> GetAsync(CancellationToken ct);
    void Invalidate();
}

public sealed class SystemSettingsProvider(IAppDbContext db, IMemoryCache cache) : ISystemSettingsProvider
{
    private const string CacheKey = "system-settings";

    public async Task<RuntimeSettings> GetAsync(CancellationToken ct)
    {
        if (cache.TryGetValue(CacheKey, out RuntimeSettings? cached) && cached is not null) return cached;

        var rows = await db.SystemSettings.AsNoTracking().ToDictionaryAsync(s => s.Key, s => s.Value, ct);

        var settings = new RuntimeSettings(
            MaintenanceMode: Read(rows, SystemSettingKeys.MaintenanceMode, e => e.GetBoolean(), false),
            GeocodingEnabled: Read(rows, SystemSettingKeys.GeocodingEnabled, e => e.GetBoolean(), true),
            HistoryMaxCloudItems: Read(rows, SystemSettingKeys.HistoryMaxCloudItems, e => e.GetInt32(), 1000),
            SupportEmail: Read(rows, SystemSettingKeys.SupportEmail, e => e.GetString() ?? string.Empty, string.Empty));

        cache.Set(CacheKey, settings, TimeSpan.FromSeconds(30));
        return settings;
    }

    public void Invalidate() => cache.Remove(CacheKey);

    private static T Read<T>(Dictionary<string, string> rows, string key, Func<JsonElement, T> read, T fallback)
    {
        if (!rows.TryGetValue(key, out var json)) return fallback;
        try
        {
            using var doc = JsonDocument.Parse(json);
            return read(doc.RootElement);
        }
        catch (Exception e) when (e is JsonException or InvalidOperationException or FormatException)
        {
            return fallback;
        }
    }
}
