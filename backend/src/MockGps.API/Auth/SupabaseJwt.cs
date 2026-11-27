using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using MockGps.Infrastructure.Supabase;

namespace MockGps.API.Auth;

/// <summary>
/// Caches Supabase Auth signing keys from <c>/auth/v1/.well-known/jwks.json</c> (asymmetric keys) and
/// optionally adds the legacy HS256 secret. Unknown key ids trigger a throttled refresh (key rotation).
/// </summary>
public sealed class SupabaseSigningKeys(IHttpClientFactory httpFactory, IOptions<SupabaseOptions> options, ILogger<SupabaseSigningKeys> logger)
{
    private static readonly TimeSpan RefreshInterval = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan MinRefreshGap = TimeSpan.FromSeconds(30);

    private readonly SemaphoreSlim _lock = new(1, 1);
    private IReadOnlyList<SecurityKey> _jwks = [];
    private DateTimeOffset _loadedAt = DateTimeOffset.MinValue;
    private DateTimeOffset _lastAttempt = DateTimeOffset.MinValue;

    public IEnumerable<SecurityKey> Resolve(string? kid)
    {
        var now = DateTimeOffset.UtcNow;
        var unknownKid = kid is not null && _jwks.All(k => k.KeyId != kid);
        if ((now - _loadedAt > RefreshInterval || unknownKid) && now - _lastAttempt > MinRefreshGap)
        {
            // Block only on the very first load; later refreshes happen in the background.
            var refresh = RefreshAsync();
            if (_loadedAt == DateTimeOffset.MinValue) refresh.GetAwaiter().GetResult();
        }

        var keys = new List<SecurityKey>(_jwks);
        if (!string.IsNullOrWhiteSpace(options.Value.JwtSecret))
        {
            keys.Add(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(options.Value.JwtSecret)));
        }
        return keys;
    }

    public async Task RefreshAsync()
    {
        if (!await _lock.WaitAsync(0)) return;
        try
        {
            _lastAttempt = DateTimeOffset.UtcNow;
            var http = httpFactory.CreateClient(nameof(SupabaseSigningKeys));
            var json = await http.GetStringAsync($"{options.Value.BaseUrl}/auth/v1/.well-known/jwks.json");
            _jwks = new JsonWebKeySet(json).GetSigningKeys().ToList();
            _loadedAt = DateTimeOffset.UtcNow;
            logger.LogInformation("Loaded {Count} Supabase signing key(s)", _jwks.Count);
        }
        catch (Exception e)
        {
            logger.LogWarning(e, "Could not load Supabase JWKS; falling back to configured secret if any");
        }
        finally
        {
            _lock.Release();
        }
    }
}

public sealed class ConfigureJwtBearer(IOptions<SupabaseOptions> supabase, SupabaseSigningKeys keys)
    : IConfigureNamedOptions<JwtBearerOptions>
{
    public void Configure(string? name, JwtBearerOptions options) => Configure(options);

    public void Configure(JwtBearerOptions options)
    {
        var o = supabase.Value;
        options.MapInboundClaims = false;
        options.RequireHttpsMetadata = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = o.Issuer,
            ValidateAudience = true,
            ValidAudience = o.JwtAudience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            ValidateIssuerSigningKey = true,
            RequireSignedTokens = true,
            NameClaimType = "sub",
            RoleClaimType = "role",
            IssuerSigningKeyResolver = (_, _, kid, _) => keys.Resolve(kid),
        };
    }
}
