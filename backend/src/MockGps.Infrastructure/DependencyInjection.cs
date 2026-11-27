using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MockGps.Application.Common;
using MockGps.Application.Geocoding;
using MockGps.Application.Public;
using MockGps.Infrastructure.Geocoding;
using MockGps.Infrastructure.Persistence;
using MockGps.Infrastructure.Supabase;

namespace MockGps.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Resolved lazily so configuration added later (tests, hosting overrides) is respected.
        services.AddDbContext<AppDbContext>((sp, o) =>
        {
            var connectionString = sp.GetRequiredService<IConfiguration>().GetConnectionString("Database");
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new InvalidOperationException("ConnectionStrings:Database is not configured.");
            o.UseNpgsql(connectionString, npgsql => npgsql.CommandTimeout(30)).UseSnakeCaseNamingConvention();
        });
        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());
        services.AddScoped<IUserDataScope, UserDataScope>();
        services.AddScoped<IAuditLogger, AuditLogger>();

        services.AddMemoryCache();

        services.AddOptions<SupabaseOptions>().Bind(configuration.GetSection(SupabaseOptions.Section))
            .Validate(o => Uri.TryCreate(o.Url, UriKind.Absolute, out _), "Supabase:Url must be an absolute URL.")
            .Validate(o => !string.IsNullOrWhiteSpace(o.SecretKey), "Supabase:SecretKey is required.")
            .ValidateOnStart();
        services.AddOptions<MapOptions>().Bind(configuration.GetSection(MapOptions.Section));
        services.AddOptions<GeocodingOptions>().Bind(configuration.GetSection(GeocodingOptions.Section))
            .Validate(o => o.Provider is "photon" or "nominatim" or "maptiler", "Geocoding:Provider must be photon, nominatim or maptiler.")
            .Validate(o => o.Provider != "maptiler" || !string.IsNullOrWhiteSpace(o.MapTilerKey), "Geocoding:MapTilerKey is required for maptiler.")
            .ValidateOnStart();

        services.AddHttpClient<IAuthAdminClient, SupabaseAuthAdminClient>((sp, c) =>
            SupabaseHttp.Configure(c, sp.GetRequiredService<IOptions<SupabaseOptions>>().Value));
        services.AddHttpClient<IStorageClient, SupabaseStorageClient>((sp, c) =>
        {
            SupabaseHttp.Configure(c, sp.GetRequiredService<IOptions<SupabaseOptions>>().Value);
            c.Timeout = TimeSpan.FromMinutes(5); // APK uploads
        });

        var provider = configuration.GetSection(GeocodingOptions.Section)["Provider"] ?? "photon";
        void ConfigureGeo(IServiceProvider sp, HttpClient c)
        {
            c.Timeout = TimeSpan.FromSeconds(8);
            c.DefaultRequestHeaders.UserAgent.ParseAdd(sp.GetRequiredService<IOptions<GeocodingOptions>>().Value.UserAgent);
        }
        _ = provider switch
        {
            "nominatim" => services.AddHttpClient<IGeocodingProvider, NominatimGeocodingProvider>(ConfigureGeo),
            "maptiler" => services.AddHttpClient<IGeocodingProvider, MapTilerGeocodingProvider>(ConfigureGeo),
            _ => services.AddHttpClient<IGeocodingProvider, PhotonGeocodingProvider>(ConfigureGeo),
        };

        return services;
    }
}
