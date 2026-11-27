using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Admin;

public record RoleDto(Guid Id, string Name, string? Description, bool IsSystem, IReadOnlyList<string> Permissions, int UserCount);

public record RoleRequest(string Name, string? Description, IReadOnlyList<string> Permissions);

public class RoleRequestValidator : AbstractValidator<RoleRequest>
{
    public RoleRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().Matches("^[a-z][a-z0-9_]{1,31}$")
            .WithMessage("Role name must be 2-32 lowercase letters, digits or underscores.");
        RuleFor(x => x.Description).MaximumLength(200);
        RuleFor(x => x.Permissions).NotNull();
        RuleForEach(x => x.Permissions).Must(p => Permissions.All.Contains(p)).WithMessage("Unknown permission '{PropertyValue}'.");
    }
}

public interface IRoleService
{
    Task<IReadOnlyList<RoleDto>> ListAsync(CancellationToken ct);
    Task<RoleDto> CreateAsync(RoleRequest request, CancellationToken ct);
    Task<RoleDto> UpdateAsync(Guid id, RoleRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}

public sealed class RoleService(IAppDbContext db, IAuditLogger audit, IRequestValidator validator, Access.IUserAccessService access) : IRoleService
{
    public async Task<IReadOnlyList<RoleDto>> ListAsync(CancellationToken ct) =>
        await db.Roles.AsNoTracking()
            .OrderByDescending(r => r.IsSystem).ThenBy(r => r.Name)
            .Select(r => new RoleDto(r.Id, r.Name, r.Description, r.IsSystem,
                r.Permissions.Select(p => p.Permission).OrderBy(p => p).ToList(), r.UserRoles.Count))
            .ToListAsync(ct);

    public async Task<RoleDto> CreateAsync(RoleRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        if (await db.Roles.AnyAsync(r => r.Name == request.Name, ct))
            throw new ConflictException("A role with this name already exists.", "role_exists");

        var role = new Role { Id = Guid.NewGuid(), Name = request.Name, Description = Text.Clean(request.Description) };
        role.Permissions = request.Permissions.Distinct().Select(p => new RolePermission { Id = Guid.NewGuid(), RoleId = role.Id, Permission = p }).ToList();
        db.Roles.Add(role);
        audit.Add("role.created", "role", role.Id.ToString(), $"Role '{role.Name}' created", new { request.Permissions });
        await db.SaveChangesAsync(ct);
        return await GetAsync(role.Id, ct);
    }

    public async Task<RoleDto> UpdateAsync(Guid id, RoleRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var role = await db.Roles.Include(r => r.Permissions).FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundException("Role");

        if (role.IsSystem && role.Name != request.Name)
            throw new BusinessRuleException("System roles cannot be renamed.", "system_role");
        if (role.Name == SystemRoles.SuperAdmin && !Permissions.All.All(request.Permissions.Contains))
            throw new BusinessRuleException("The superadmin role must keep all permissions.", "system_role");
        if (role.Name == SystemRoles.User && request.Permissions.Count > 0)
            throw new BusinessRuleException("The user role cannot have admin permissions.", "system_role");
        if (role.Name != request.Name && await db.Roles.AnyAsync(r => r.Name == request.Name, ct))
            throw new ConflictException("A role with this name already exists.", "role_exists");

        var before = role.Permissions.Select(p => p.Permission).Order().ToList();
        role.Name = request.Name;
        role.Description = Text.Clean(request.Description);
        var wanted = request.Permissions.Distinct().ToHashSet();
        db.RolePermissions.RemoveRange(role.Permissions.Where(p => !wanted.Contains(p.Permission)));
        foreach (var p in wanted.Where(w => role.Permissions.All(x => x.Permission != w)))
        {
            db.RolePermissions.Add(new RolePermission { Id = Guid.NewGuid(), RoleId = role.Id, Permission = p });
        }

        audit.Add("role.updated", "role", id.ToString(), $"Role '{role.Name}' updated", new { before, after = wanted.Order().ToList() });
        await db.SaveChangesAsync(ct);
        await InvalidateMembersAsync(id, ct);
        return await GetAsync(id, ct);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var role = await db.Roles.FirstOrDefaultAsync(r => r.Id == id, ct) ?? throw new NotFoundException("Role");
        if (role.IsSystem) throw new BusinessRuleException("System roles cannot be deleted.", "system_role");

        await InvalidateMembersAsync(id, ct);
        db.Roles.Remove(role);
        audit.Add("role.deleted", "role", id.ToString(), $"Role '{role.Name}' deleted");
        await db.SaveChangesAsync(ct);
    }

    private async Task<RoleDto> GetAsync(Guid id, CancellationToken ct) =>
        (await ListAsync(ct)).First(r => r.Id == id);

    private async Task InvalidateMembersAsync(Guid roleId, CancellationToken ct)
    {
        var members = await db.UserRoles.Where(ur => ur.RoleId == roleId).Select(ur => ur.UserId).ToListAsync(ct);
        members.ForEach(access.Invalidate);
    }
}
