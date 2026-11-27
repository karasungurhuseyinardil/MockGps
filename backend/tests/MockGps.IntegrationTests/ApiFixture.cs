using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace MockGps.IntegrationTests;

/// <summary>
/// Runs the real API in-process against a running local Supabase stack (<c>npx supabase start</c>).
/// Keys come from MOCKGPS_TEST_* environment variables (CI) or, when unset, from
/// <c>supabase status -o env</c> of the local stack. No keys are stored in the repository.
/// </summary>
public sealed class ApiFixture : WebApplicationFactory<Program>
{
    private static readonly Lazy<IReadOnlyDictionary<string, string>> LocalStatus = new(ReadLocalSupabaseStatus);

    public static readonly string SupabaseUrl = Env("MOCKGPS_TEST_SUPABASE_URL", "API_URL");
    public static readonly string PublishableKey = Env("MOCKGPS_TEST_PUBLISHABLE_KEY", "PUBLISHABLE_KEY");
    public static readonly string SecretKey = Env("MOCKGPS_TEST_SECRET_KEY", "SECRET_KEY");
    public static readonly string JwtSecret = Env("MOCKGPS_TEST_JWT_SECRET", "JWT_SECRET");
    public static readonly string Database = Environment.GetEnvironmentVariable("MOCKGPS_TEST_DATABASE") is { Length: > 0 } db
        ? db
        : ToNpgsql(LocalStatus.Value["DB_URL"]);

    private readonly HttpClient _supabase = new() { BaseAddress = new Uri(SupabaseUrl + "/") };

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ConnectionStrings:Database"] = Database,
            ["Supabase:Url"] = SupabaseUrl,
            ["Supabase:SecretKey"] = SecretKey,
            ["Supabase:JwtSecret"] = JwtSecret,
            ["Serilog:MinimumLevel:Default"] = "Warning",
        }));
    }

    /// <summary>Creates a confirmed Supabase Auth user and returns an API client authenticated as them.</summary>
    public async Task<TestUser> CreateUserAsync(string prefix)
    {
        var email = $"{prefix}-{Guid.NewGuid():N}@test.local";
        const string password = "Passw0rd123";

        using var create = new HttpRequestMessage(HttpMethod.Post, "auth/v1/admin/users")
        {
            Content = JsonContent.Create(new { email, password, email_confirm = true }),
        };
        create.Headers.Add("apikey", SecretKey);
        (await _supabase.SendAsync(create)).EnsureSuccessStatusCode();

        using var token = new HttpRequestMessage(HttpMethod.Post, "auth/v1/token?grant_type=password")
        {
            Content = JsonContent.Create(new { email, password }),
        };
        token.Headers.Add("apikey", PublishableKey);
        var response = await _supabase.SendAsync(token);
        response.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());

        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", doc.RootElement.GetProperty("access_token").GetString());
        var id = Guid.Parse(doc.RootElement.GetProperty("user").GetProperty("id").GetString()!);
        return new TestUser(id, email, client);
    }

    public async Task GrantRoleAsync(Guid userId, string role)
    {
        await using var conn = new NpgsqlConnection(Database);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(
            "insert into app.user_roles (user_id, role_id) select @u, id from app.roles where name = @r on conflict do nothing", conn);
        cmd.Parameters.AddWithValue("u", userId);
        cmd.Parameters.AddWithValue("r", role);
        await cmd.ExecuteNonQueryAsync();
        Services.GetRequiredService<IMemoryCache>().Remove($"access:{userId}");
    }

    private static string Env(string name, string statusKey) =>
        Environment.GetEnvironmentVariable(name) is { Length: > 0 } v
            ? v
            : LocalStatus.Value.TryGetValue(statusKey, out var s) ? s : throw new InvalidOperationException($"{name} is not set and `supabase status` has no {statusKey}.");

    /// <summary>Reads KEY="value" lines from `npx supabase status -o env` (run from the repository root).</summary>
    private static IReadOnlyDictionary<string, string> ReadLocalSupabaseStatus()
    {
        var root = AppContext.BaseDirectory;
        while (root is not null && !Directory.Exists(Path.Combine(root, "supabase"))) root = Path.GetDirectoryName(root.TrimEnd(Path.DirectorySeparatorChar));
        var start = new System.Diagnostics.ProcessStartInfo
        {
            FileName = OperatingSystem.IsWindows() ? "cmd.exe" : "npx",
            Arguments = OperatingSystem.IsWindows() ? "/c npx supabase status -o env" : "supabase status -o env",
            WorkingDirectory = root ?? Directory.GetCurrentDirectory(),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        using var process = System.Diagnostics.Process.Start(start)!;
        var output = process.StandardOutput.ReadToEnd();
        process.WaitForExit();
        var values = output.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(line => line.Split('=', 2))
            .Where(p => p.Length == 2)
            .ToDictionary(p => p[0], p => p[1].Trim('"'));
        if (values.Count == 0) throw new InvalidOperationException("Local Supabase is not running. Start it with `npx supabase start`.");
        return values;
    }

    /// <summary>postgresql://user:pass@host:port/db → Npgsql connection string.</summary>
    private static string ToNpgsql(string url)
    {
        var uri = new Uri(url);
        var userInfo = uri.UserInfo.Split(':', 2);
        return $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};Username={Uri.UnescapeDataString(userInfo[0])};Password={Uri.UnescapeDataString(userInfo[1])}";
    }
}

public sealed record TestUser(Guid Id, string Email, HttpClient Http);

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFixture>
{
    public const string Name = "api";
}
