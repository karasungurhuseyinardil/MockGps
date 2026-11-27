using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MockGps.Application.Common;

namespace MockGps.Application.Access;

public sealed record UserAccess(Guid UserId, bool IsActive, IReadOnlyList<string> Roles, IReadOnlyList<string> Permissions)
{
    public bool Has(string permission) => Permissions.Contains(permission);
    public bool IsAdmin => Permissions.Count > 0;
}

public interface IUserAccessService
{
    /// <summary>Returns roles/permissions/status from the database (cached 60s). Null when no profile exists.</summary>
    Task<UserAccess?> GetAsync(Guid userId, CancellationToken ct);
    void Invalidate(Guid userId);
}

public sealed class UserAccessService(IAppDbContext db, IMemoryCache cache) : IUserAccessService
{
    private static readonly TimeSpan Ttl = TimeSpan.FromSeconds(60);
    private static string Key(Guid id) => $"access:{id}";

    public async Task<UserAccess?> GetAsync(Guid userId, CancellationToken ct)
    {
        if (cache.TryGetValue(Key(userId), out UserAccess? cached)) return cached;

        var profile = await db.Profiles.AsNoTracking()
            .Where(p => p.Id == userId)
            .Select(p => new { p.IsActive })
            .FirstOrDefaultAsync(ct);
        if (profile is null) return null;

        var roles = await db.UserRoles.AsNoTracking()
            .Where(ur => ur.UserId == userId)
            .Select(ur => ur.Role!.Name)
            .ToListAsync(ct);

        var permissions = await db.RolePermissions.AsNoTracking()
            .Where(rp => db.UserRoles.Any(ur => ur.UserId == userId && ur.RoleId == rp.RoleId))
            .Select(rp => rp.Permission)
            .Distinct()
            .ToListAsync(ct);

        var access = new UserAccess(userId, profile.IsActive, roles.Order().ToList(), permissions.Order().ToList());
        cache.Set(Key(userId), access, Ttl);
        return access;
    }

    public void Invalidate(Guid userId) => cache.Remove(Key(userId));
}
