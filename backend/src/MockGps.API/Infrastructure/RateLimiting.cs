using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace MockGps.API.Infrastructure;

public static class RateLimitPolicies
{
    public const string Public = "public";
    public const string Contact = "contact";
    public const string Geocoding = "geocoding";
    public const string Usage = "usage";

    public static IServiceCollection AddApiRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(o =>
        {
            o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            o.OnRejected = async (context, ct) =>
            {
                if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retry))
                    context.HttpContext.Response.Headers.RetryAfter = ((int)retry.TotalSeconds).ToString();
                var problem = new ProblemDetails
                {
                    Status = 429,
                    Title = "Too many requests",
                    Detail = "You are sending requests too quickly. Please wait a moment and try again.",
                };
                problem.Extensions["code"] = "rate_limited";
                await context.HttpContext.Response.WriteAsJsonAsync(problem, ct);
            };

            // Global safety net per user (or IP for anonymous calls).
            o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(http =>
                RateLimitPartition.GetFixedWindowLimiter(Partition(http), _ => Window(300, TimeSpan.FromMinutes(1))));

            o.AddPolicy(Public, http => RateLimitPartition.GetFixedWindowLimiter(Partition(http), _ => Window(60, TimeSpan.FromMinutes(1))));
            o.AddPolicy(Contact, http => RateLimitPartition.GetFixedWindowLimiter(Partition(http), _ => Window(5, TimeSpan.FromMinutes(10))));
            o.AddPolicy(Geocoding, http => RateLimitPartition.GetFixedWindowLimiter(Partition(http), _ => Window(30, TimeSpan.FromMinutes(1))));
            o.AddPolicy(Usage, http => RateLimitPartition.GetFixedWindowLimiter(Partition(http), _ => Window(30, TimeSpan.FromMinutes(1))));
        });
        return services;
    }

    private static FixedWindowRateLimiterOptions Window(int permits, TimeSpan window) =>
        new() { PermitLimit = permits, Window = window, QueueLimit = 0, AutoReplenishment = true };

    private static string Partition(HttpContext http) =>
        http.User.FindFirst("sub")?.Value is { } sub
            ? $"u:{sub}"
            : $"ip:{http.Connection.RemoteIpAddress}";
}
