using Microsoft.EntityFrameworkCore;
using MockGps.Domain.Entities;

namespace MockGps.Application.Common;

public interface IAppDbContext
{
    DbSet<Profile> Profiles { get; }
    DbSet<Role> Roles { get; }
    DbSet<RolePermission> RolePermissions { get; }
    DbSet<UserRole> UserRoles { get; }
    DbSet<UserSettings> UserSettings { get; }
    DbSet<LocationCategory> LocationCategories { get; }
    DbSet<FavoriteLocation> FavoriteLocations { get; }
    DbSet<LocationHistoryEntry> LocationHistory { get; }
    DbSet<SavedRoute> SavedRoutes { get; }
    DbSet<UsageEvent> UsageEvents { get; }
    DbSet<SystemSetting> SystemSettings { get; }
    DbSet<AppVersion> AppVersions { get; }
    DbSet<Announcement> Announcements { get; }
    DbSet<ContactMessage> ContactMessages { get; }
    DbSet<AuditLog> AuditLogs { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// <summary>Runs a raw SQL query mapped to an unmapped type (reporting queries).</summary>
    IQueryable<T> SqlQuery<T>(FormattableString sql);
}

/// <summary>
/// Runs work on behalf of the current user inside a transaction where Postgres executes as the
/// <c>authenticated</c> role with the caller's JWT claims, so Row Level Security is enforced.
/// </summary>
public interface IUserDataScope
{
    Task<T> RunAsync<T>(Func<IAppDbContext, Task<T>> work, CancellationToken ct);
    Task RunAsync(Func<IAppDbContext, Task> work, CancellationToken ct);
}

public interface ICurrentUser
{
    bool IsAuthenticated { get; }
    /// <summary>Supabase Auth user id (JWT <c>sub</c>). Throws when not authenticated.</summary>
    Guid UserId { get; }
    string? Email { get; }
    string? IpAddress { get; }
}

public interface IAuditLogger
{
    /// <summary>Adds an audit row to the privileged context. Persisted by the next SaveChanges.</summary>
    void Add(string action, string entity, string? entityId, string? description, object? metadata = null);
}

public interface IAuthAdminClient
{
    Task DeleteUserAsync(Guid userId, CancellationToken ct);
    Task SetBannedAsync(Guid userId, bool banned, CancellationToken ct);
    Task<bool> IsHealthyAsync(CancellationToken ct);
}

public interface IStorageClient
{
    Task UploadAsync(string bucket, string path, Stream content, string contentType, CancellationToken ct);
    Task DeleteAsync(string bucket, IEnumerable<string> paths, CancellationToken ct);
    Task<string> CreateSignedUrlAsync(string bucket, string path, TimeSpan expiresIn, CancellationToken ct);
    string GetPublicUrl(string bucket, string path);
}

public static class StorageBuckets
{
    public const string Avatars = "avatars";
    public const string Releases = "releases";
}
