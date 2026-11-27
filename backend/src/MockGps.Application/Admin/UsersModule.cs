using System.Linq.Expressions;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Access;
using MockGps.Application.Common;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Admin;

public record AdminUserListItem(
    Guid Id,
    string Email,
    string? DisplayName,
    bool IsActive,
    IReadOnlyList<string> Roles,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastSeenAt);

public record AdminUserDetail(
    Guid Id,
    string Email,
    string? DisplayName,
    bool IsActive,
    IReadOnlyList<string> Roles,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastSeenAt,
    string Language,
    bool HistoryCloudSync);

public record AdminUserStats(
    int Favorites,
    int Categories,
    int Routes,
    int CloudHistoryItems,
    long SimulationsTotal,
    long Simulations30d,
    DateTimeOffset? LastActivityAt,
    IReadOnlyList<FeatureUsageItem> EventsByType);

public class AdminUserQuery : PageQuery
{
    public string? Search { get; set; }
    public string? Role { get; set; }
    /// <summary><c>active</c> or <c>inactive</c>.</summary>
    public string? Status { get; set; }
}

public record UpdateUserStatusRequest(bool IsActive, string? Reason);
public record UpdateUserRolesRequest(IReadOnlyList<string> Roles);

public class AdminUserQueryValidator : PageQueryValidator<AdminUserQuery>
{
    public AdminUserQueryValidator()
    {
        RuleFor(x => x.Search).MaximumLength(100);
        RuleFor(x => x.Status).OneOf(["active", "inactive"]);
        RuleFor(x => x.Role).MaximumLength(32);
    }
}

public class UpdateUserStatusValidator : AbstractValidator<UpdateUserStatusRequest>
{
    public UpdateUserStatusValidator() => RuleFor(x => x.Reason).MaximumLength(500);
}

public class UpdateUserRolesValidator : AbstractValidator<UpdateUserRolesRequest>
{
    public UpdateUserRolesValidator() =>
        RuleFor(x => x.Roles).NotNull().Must(r => r.Count <= 20).WithMessage("Too many roles.");
}

public interface IAdminUserService
{
    Task<PagedResult<AdminUserListItem>> ListAsync(AdminUserQuery query, CancellationToken ct);
    Task<PagedResult<AdminUserListItem>> ListAdminsAsync(PageQuery query, CancellationToken ct);
    Task<AdminUserDetail> GetAsync(Guid id, CancellationToken ct);
    Task<AdminUserStats> GetStatsAsync(Guid id, CancellationToken ct);
    Task<AdminUserDetail> UpdateStatusAsync(Guid id, UpdateUserStatusRequest request, CancellationToken ct);
    Task<AdminUserDetail> UpdateRolesAsync(Guid id, UpdateUserRolesRequest request, CancellationToken ct);
}

public sealed class AdminUserService(
    IAppDbContext db,
    ICurrentUser currentUser,
    IUserAccessService access,
    IAuthAdminClient authAdmin,
    IAuditLogger audit,
    IRequestValidator validator,
    TimeProvider clock) : IAdminUserService
{
    private static readonly Dictionary<string, Expression<Func<Profile, object?>>> Sorts = new()
    {
        ["created_at"] = p => p.CreatedAt,
        ["email"] = p => p.Email,
        ["last_seen_at"] = p => p.LastSeenAt,
        ["display_name"] = p => p.DisplayName,
    };

    private static readonly Expression<Func<Profile, AdminUserListItem>> ToListItem = p => new AdminUserListItem(
        p.Id, p.Email, p.DisplayName, p.IsActive,
        p.UserRoles.Select(ur => ur.Role!.Name).OrderBy(n => n).ToList(),
        p.CreatedAt, p.LastSeenAt);

    public async Task<PagedResult<AdminUserListItem>> ListAsync(AdminUserQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var q = db.Profiles.AsNoTracking();

        if (Text.Clean(query.Search) is { } search)
        {
            var pattern = Text.LikePattern(search);
            q = q.Where(p => EF.Functions.ILike(p.Email, pattern, "\\") || EF.Functions.ILike(p.DisplayName ?? "", pattern, "\\"));
        }
        if (Text.Clean(query.Role) is { } role) q = q.Where(p => p.UserRoles.Any(ur => ur.Role!.Name == role));
        if (query.Status == "active") q = q.Where(p => p.IsActive);
        if (query.Status == "inactive") q = q.Where(p => !p.IsActive);

        return await q.ApplySort(query.Sort, Sorts, "created_at:desc").ToPagedAsync(query, ToListItem, ct);
    }

    public async Task<PagedResult<AdminUserListItem>> ListAdminsAsync(PageQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        return await db.Profiles.AsNoTracking()
            .Where(p => p.UserRoles.Any(ur => ur.Role!.Permissions.Any()))
            .ApplySort(query.Sort, Sorts, "email:asc")
            .ToPagedAsync(query, ToListItem, ct);
    }

    public async Task<AdminUserDetail> GetAsync(Guid id, CancellationToken ct) =>
        await db.Profiles.AsNoTracking().Where(p => p.Id == id)
            .Select(p => new AdminUserDetail(
                p.Id, p.Email, p.DisplayName, p.IsActive,
                p.UserRoles.Select(ur => ur.Role!.Name).OrderBy(n => n).ToList(),
                p.CreatedAt, p.LastSeenAt,
                p.Settings != null ? p.Settings.Language : Languages.English,
                p.Settings != null && p.Settings.HistoryCloudSync))
            .FirstOrDefaultAsync(ct)
        ?? throw new NotFoundException("User");

    public async Task<AdminUserStats> GetStatsAsync(Guid id, CancellationToken ct)
    {
        if (!await db.Profiles.AnyAsync(p => p.Id == id, ct)) throw new NotFoundException("User");
        var since = clock.GetUtcNow().AddDays(-30);
        var events = db.UsageEvents.AsNoTracking().Where(e => e.UserId == id);

        return new AdminUserStats(
            Favorites: await db.FavoriteLocations.CountAsync(f => f.UserId == id, ct),
            Categories: await db.LocationCategories.CountAsync(c => c.UserId == id, ct),
            Routes: await db.SavedRoutes.CountAsync(r => r.UserId == id, ct),
            CloudHistoryItems: await db.LocationHistory.CountAsync(h => h.UserId == id, ct),
            SimulationsTotal: await events.LongCountAsync(e => e.EventType == UsageEventTypes.SimulationStarted, ct),
            Simulations30d: await events.LongCountAsync(e => e.EventType == UsageEventTypes.SimulationStarted && e.CreatedAt >= since, ct),
            LastActivityAt: await events.MaxAsync(e => (DateTimeOffset?)e.CreatedAt, ct),
            EventsByType: (await events.GroupBy(e => e.EventType)
                .Select(g => new { g.Key, Count = g.LongCount() })
                .OrderByDescending(x => x.Count).ToListAsync(ct))
                .Select(x => new FeatureUsageItem(x.Key, x.Count)).ToList());
    }

    public async Task<AdminUserDetail> UpdateStatusAsync(Guid id, UpdateUserStatusRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        if (id == currentUser.UserId)
            throw new BusinessRuleException("You cannot change the status of your own account.", "self_status_change");

        var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == id, ct) ?? throw new NotFoundException("User");
        if (profile.IsActive == request.IsActive) return await GetAsync(id, ct);

        if (!request.IsActive && await IsLastSuperAdminAsync(id, ct))
            throw new BusinessRuleException("The last superadmin cannot be deactivated.", "last_superadmin");

        // Ban in Supabase Auth first so refresh tokens stop working, then persist.
        await authAdmin.SetBannedAsync(id, !request.IsActive, ct);
        profile.IsActive = request.IsActive;
        audit.Add(request.IsActive ? "user.activated" : "user.deactivated", "user", id.ToString(),
            Text.Clean(request.Reason) ?? (request.IsActive ? "User activated" : "User deactivated"),
            new { profile.Email });
        await db.SaveChangesAsync(ct);
        access.Invalidate(id);
        return await GetAsync(id, ct);
    }

    public async Task<AdminUserDetail> UpdateRolesAsync(Guid id, UpdateUserRolesRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        if (!await db.Profiles.AnyAsync(p => p.Id == id, ct)) throw new NotFoundException("User");

        var wanted = request.Roles.Select(r => r.Trim().ToLowerInvariant()).Distinct().ToList();
        if (!wanted.Contains(SystemRoles.User)) wanted.Add(SystemRoles.User);

        var roles = await db.Roles.Where(r => wanted.Contains(r.Name)).ToListAsync(ct);
        var unknown = wanted.Except(roles.Select(r => r.Name)).ToList();
        if (unknown.Count > 0)
            throw new BusinessRuleException($"Unknown role(s): {string.Join(", ", unknown)}.", "unknown_role");

        var current = await db.UserRoles.Include(ur => ur.Role).Where(ur => ur.UserId == id).ToListAsync(ct);
        var currentNames = current.Select(ur => ur.Role!.Name).ToHashSet();

        var removingSuper = currentNames.Contains(SystemRoles.SuperAdmin) && !wanted.Contains(SystemRoles.SuperAdmin);
        if (removingSuper && await IsLastSuperAdminAsync(id, ct))
            throw new BusinessRuleException("The last superadmin cannot lose the superadmin role.", "last_superadmin");

        db.UserRoles.RemoveRange(current.Where(ur => !wanted.Contains(ur.Role!.Name)));
        foreach (var role in roles.Where(r => !currentNames.Contains(r.Name)))
        {
            db.UserRoles.Add(new UserRole { Id = Guid.NewGuid(), UserId = id, RoleId = role.Id });
        }

        audit.Add("user.roles_updated", "user", id.ToString(), "User roles updated",
            new { before = currentNames.Order().ToList(), after = wanted.Order().ToList() });
        await db.SaveChangesAsync(ct);
        access.Invalidate(id);
        return await GetAsync(id, ct);
    }

    private async Task<bool> IsLastSuperAdminAsync(Guid userId, CancellationToken ct)
    {
        var superAdmins = await db.UserRoles
            .Where(ur => ur.Role!.Name == SystemRoles.SuperAdmin && ur.User!.IsActive)
            .Select(ur => ur.UserId).ToListAsync(ct);
        return superAdmins.Count == 1 && superAdmins[0] == userId;
    }
}
