using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;
using MockGps.Application.Access;
using MockGps.Application.Common;

namespace MockGps.API.Auth;

/// <summary>Requires a database-backed permission (roles are never read from the JWT).</summary>
public sealed class HasPermissionAttribute(string permission) : AuthorizeAttribute(PermissionPolicy.Prefix + permission);

public static class PermissionPolicy
{
    public const string Prefix = "perm:";
}

public sealed record PermissionRequirement(string Permission) : IAuthorizationRequirement;

public sealed class PermissionPolicyProvider(IOptions<AuthorizationOptions> options) : DefaultAuthorizationPolicyProvider(options)
{
    public override async Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (!policyName.StartsWith(PermissionPolicy.Prefix, StringComparison.Ordinal))
            return await base.GetPolicyAsync(policyName);

        return new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser()
            .AddRequirements(new PermissionRequirement(policyName[PermissionPolicy.Prefix.Length..]))
            .Build();
    }
}

public sealed class PermissionHandler(IUserAccessService access, ICurrentUser currentUser) : AuthorizationHandler<PermissionRequirement>
{
    protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
    {
        if (!currentUser.IsAuthenticated) return;
        var userAccess = await access.GetAsync(currentUser.UserId, CancellationToken.None);
        if (userAccess is { IsActive: true } && userAccess.Has(requirement.Permission))
        {
            context.Succeed(requirement);
        }
    }
}

public sealed class CurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    private System.Security.Claims.ClaimsPrincipal? Principal => accessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true && Guid.TryParse(Principal.FindFirst("sub")?.Value, out _);

    public Guid UserId => Guid.TryParse(Principal?.FindFirst("sub")?.Value, out var id)
        ? id
        : throw new UnauthorizedAccessException("No authenticated user.");

    public string? Email => Principal?.FindFirst("email")?.Value;

    public string? IpAddress => accessor.HttpContext?.Connection.RemoteIpAddress?.ToString();
}
