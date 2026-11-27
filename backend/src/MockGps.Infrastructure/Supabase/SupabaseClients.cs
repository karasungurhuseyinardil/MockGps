using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MockGps.Application.Common;

namespace MockGps.Infrastructure.Supabase;

public class SupabaseOptions
{
    public const string Section = "Supabase";

    /// <summary>URL the backend uses to reach Supabase (may be internal).</summary>
    public string Url { get; set; } = string.Empty;
    /// <summary>Optional client-facing URL used when building public/signed URLs. Defaults to <see cref="Url"/>.</summary>
    public string? PublicUrl { get; set; }
    /// <summary>Secret (service role) key. Backend only — never ship it to clients.</summary>
    public string SecretKey { get; set; } = string.Empty;
    /// <summary>Optional legacy HS256 JWT secret (local CLI / legacy projects).</summary>
    public string? JwtSecret { get; set; }
    /// <summary>Optional issuer override. Defaults to {Url}/auth/v1.</summary>
    public string? JwtIssuer { get; set; }
    public string JwtAudience { get; set; } = "authenticated";

    public string BaseUrl => Url.TrimEnd('/');
    public string ClientBaseUrl => (string.IsNullOrWhiteSpace(PublicUrl) ? Url : PublicUrl).TrimEnd('/');
    public string Issuer => string.IsNullOrWhiteSpace(JwtIssuer) ? $"{BaseUrl}/auth/v1" : JwtIssuer.TrimEnd('/');
}

internal static class SupabaseHttp
{
    public static void Configure(HttpClient client, SupabaseOptions o)
    {
        client.BaseAddress = new Uri(o.BaseUrl + "/");
        client.Timeout = TimeSpan.FromSeconds(30);
        client.DefaultRequestHeaders.Add("apikey", o.SecretKey);
        // Legacy service_role keys are JWTs and also go in Authorization. New sb_secret_ keys only use apikey.
        if (o.SecretKey.StartsWith("eyJ", StringComparison.Ordinal))
        {
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", o.SecretKey);
        }
    }

    public static async Task EnsureOkAsync(HttpResponseMessage response, string service, ILogger logger, CancellationToken ct)
    {
        if (response.IsSuccessStatusCode) return;
        var body = await response.Content.ReadAsStringAsync(ct);
        logger.LogError("{Service} returned {Status}: {Body}", service, (int)response.StatusCode, body.Length > 500 ? body[..500] : body);
        throw new ExternalServiceException(service, string.Empty);
    }

    public static string EscapePath(string path) =>
        string.Join('/', path.Split('/', StringSplitOptions.RemoveEmptyEntries).Select(Uri.EscapeDataString));
}

public sealed class SupabaseAuthAdminClient(HttpClient http, ILogger<SupabaseAuthAdminClient> logger) : IAuthAdminClient
{
    // ~100 years: effectively permanent until an admin re-activates the user.
    private const string PermanentBan = "876000h";

    public async Task DeleteUserAsync(Guid userId, CancellationToken ct)
    {
        using var response = await http.DeleteAsync($"auth/v1/admin/users/{userId}", ct);
        if (response.StatusCode == HttpStatusCode.NotFound) return;
        await SupabaseHttp.EnsureOkAsync(response, "Authentication service", logger, ct);
    }

    public async Task SetBannedAsync(Guid userId, bool banned, CancellationToken ct)
    {
        using var response = await http.PutAsJsonAsync($"auth/v1/admin/users/{userId}",
            new { ban_duration = banned ? PermanentBan : "none" }, ct);
        await SupabaseHttp.EnsureOkAsync(response, "Authentication service", logger, ct);
    }

    public async Task<bool> IsHealthyAsync(CancellationToken ct)
    {
        try
        {
            using var response = await http.GetAsync("auth/v1/health", ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception e) when (e is HttpRequestException or TaskCanceledException)
        {
            return false;
        }
    }
}

public sealed class SupabaseStorageClient(HttpClient http, IOptions<SupabaseOptions> options, ILogger<SupabaseStorageClient> logger) : IStorageClient
{
    public async Task UploadAsync(string bucket, string path, Stream content, string contentType, CancellationToken ct)
    {
        using var body = new StreamContent(content);
        body.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        using var request = new HttpRequestMessage(HttpMethod.Post, $"storage/v1/object/{bucket}/{SupabaseHttp.EscapePath(path)}") { Content = body };
        request.Headers.Add("x-upsert", "true");
        using var response = await Send(request, ct);
        await SupabaseHttp.EnsureOkAsync(response, "File storage", logger, ct);
    }

    public async Task DeleteAsync(string bucket, IEnumerable<string> paths, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, $"storage/v1/object/{bucket}")
        {
            Content = JsonContent.Create(new { prefixes = paths.ToArray() }),
        };
        using var response = await Send(request, ct);
        await SupabaseHttp.EnsureOkAsync(response, "File storage", logger, ct);
    }

    public async Task<string> CreateSignedUrlAsync(string bucket, string path, TimeSpan expiresIn, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, $"storage/v1/object/sign/{bucket}/{SupabaseHttp.EscapePath(path)}")
        {
            Content = JsonContent.Create(new { expiresIn = (int)expiresIn.TotalSeconds }),
        };
        using var response = await Send(request, ct);
        await SupabaseHttp.EnsureOkAsync(response, "File storage", logger, ct);
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        var signed = doc.RootElement.TryGetProperty("signedURL", out var s) ? s.GetString() : null;
        if (string.IsNullOrEmpty(signed)) throw new ExternalServiceException("File storage", string.Empty);
        return $"{options.Value.ClientBaseUrl}/storage/v1{(signed.StartsWith('/') ? signed : "/" + signed)}";
    }

    public string GetPublicUrl(string bucket, string path) =>
        $"{options.Value.ClientBaseUrl}/storage/v1/object/public/{bucket}/{SupabaseHttp.EscapePath(path)}";

    private async Task<HttpResponseMessage> Send(HttpRequestMessage request, CancellationToken ct)
    {
        try
        {
            return await http.SendAsync(request, ct);
        }
        catch (HttpRequestException e)
        {
            logger.LogError(e, "Storage request failed");
            throw new ExternalServiceException("File storage", string.Empty);
        }
    }
}
