using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MockGps.Application.Access;
using MockGps.Application.Common;
using MockGps.Application.SystemSettings;
using MockGps.Infrastructure.Persistence;

namespace MockGps.API.Infrastructure;

/// <summary>
/// Runs after authentication for every authenticated request:
/// rejects deleted or deactivated accounts, enforces maintenance mode for non-admins and
/// records <c>last_seen_at</c> (at most every 5 minutes per user).
/// </summary>
public sealed class UserAccessMiddleware(RequestDelegate next)
{
    private static readonly TimeSpan LastSeenThrottle = TimeSpan.FromMinutes(5);

    public async Task InvokeAsync(
        HttpContext http,
        ICurrentUser currentUser,
        IUserAccessService accessService,
        ISystemSettingsProvider systemSettings,
        AppDbContext db,
        IMemoryCache cache,
        IProblemDetailsService problems)
    {
        if (!currentUser.IsAuthenticated)
        {
            await next(http);
            return;
        }

        var ct = http.RequestAborted;
        var access = await accessService.GetAsync(currentUser.UserId, ct);
        if (access is null)
        {
            await WriteAsync(http, problems, 401, "account_not_found", "This account no longer exists.");
            return;
        }
        if (!access.IsActive)
        {
            await WriteAsync(http, problems, 403, "account_disabled", "This account has been disabled. Contact support for help.");
            return;
        }

        var path = http.Request.Path;
        var exempt = path.StartsWithSegments("/api/v1/me") && HttpMethods.IsGet(http.Request.Method);
        if (!access.IsAdmin && !exempt && (await systemSettings.GetAsync(ct)).MaintenanceMode)
        {
            await WriteAsync(http, problems, 503, "maintenance", "The service is under maintenance. Please try again later.");
            return;
        }

        var key = $"last-seen:{access.UserId}";
        if (!cache.TryGetValue(key, out _))
        {
            cache.Set(key, true, LastSeenThrottle);
            var now = DateTimeOffset.UtcNow;
            await db.Profiles.Where(p => p.Id == access.UserId).ExecuteUpdateAsync(s => s.SetProperty(p => p.LastSeenAt, now), ct);
        }

        await next(http);
    }

    private static async Task WriteAsync(HttpContext http, IProblemDetailsService problems, int status, string code, string detail)
    {
        http.Response.StatusCode = status;
        var problem = new ProblemDetails { Status = status, Title = detail, Detail = detail };
        problem.Extensions["code"] = code;
        await problems.WriteAsync(new ProblemDetailsContext { HttpContext = http, ProblemDetails = problem });
    }
}
