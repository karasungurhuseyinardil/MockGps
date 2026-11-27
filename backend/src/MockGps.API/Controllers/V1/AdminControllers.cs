using Microsoft.AspNetCore.Mvc;
using MockGps.API.Auth;
using MockGps.Application.Admin;
using MockGps.Application.Common;
using MockGps.Domain;

namespace MockGps.API.Controllers.V1;

[Route("api/v{version:apiVersion}/admin/dashboard")]
[HasPermission(Permissions.DashboardRead)]
public sealed class AdminDashboardController(IDashboardService dashboard) : ApiControllerBase
{
    [HttpGet("summary")]
    public Task<DashboardSummary> Summary(CancellationToken ct) => dashboard.GetSummaryAsync(ct);

    /// <summary>metric: new_users | active_users | simulations; granularity: day | month.</summary>
    [HttpGet("timeseries")]
    public Task<IReadOnlyList<TimeseriesPoint>> Timeseries([FromQuery] TimeseriesQuery query, CancellationToken ct) =>
        dashboard.GetTimeseriesAsync(query, ct);

    [HttpGet("feature-usage")]
    public Task<IReadOnlyList<FeatureUsageItem>> FeatureUsage([FromQuery] DateTimeOffset? from, [FromQuery] DateTimeOffset? to, CancellationToken ct) =>
        dashboard.GetFeatureUsageAsync(from, to, ct);

    [HttpGet("system-health")]
    public Task<SystemHealth> SystemHealth(CancellationToken ct) => dashboard.GetSystemHealthAsync(ct);
}

[Route("api/v{version:apiVersion}/admin")]
public sealed class AdminUsersController(IAdminUserService users) : ApiControllerBase
{
    /// <summary>Sort: created_at, email, last_seen_at, display_name.</summary>
    [HttpGet("users")]
    [HasPermission(Permissions.UsersRead)]
    public Task<PagedResult<AdminUserListItem>> List([FromQuery] AdminUserQuery query, CancellationToken ct) => users.ListAsync(query, ct);

    [HttpGet("users/{id:guid}")]
    [HasPermission(Permissions.UsersRead)]
    public Task<AdminUserDetail> Get(Guid id, CancellationToken ct) => users.GetAsync(id, ct);

    [HttpGet("users/{id:guid}/stats")]
    [HasPermission(Permissions.UsersRead)]
    public Task<AdminUserStats> Stats(Guid id, CancellationToken ct) => users.GetStatsAsync(id, ct);

    /// <summary>Activates or deactivates (bans) an account.</summary>
    [HttpPatch("users/{id:guid}/status")]
    [HasPermission(Permissions.UsersManage)]
    public Task<AdminUserDetail> UpdateStatus(Guid id, UpdateUserStatusRequest request, CancellationToken ct) =>
        users.UpdateStatusAsync(id, request, ct);

    [HttpPut("users/{id:guid}/roles")]
    [HasPermission(Permissions.RolesManage)]
    public Task<AdminUserDetail> UpdateRoles(Guid id, UpdateUserRolesRequest request, CancellationToken ct) =>
        users.UpdateRolesAsync(id, request, ct);

    /// <summary>Users that hold at least one role with admin permissions.</summary>
    [HttpGet("admins")]
    [HasPermission(Permissions.UsersRead)]
    public Task<PagedResult<AdminUserListItem>> Admins([FromQuery] PageQuery query, CancellationToken ct) => users.ListAdminsAsync(query, ct);
}

[Route("api/v{version:apiVersion}/admin")]
[HasPermission(Permissions.RolesManage)]
public sealed class AdminRolesController(IRoleService roles) : ApiControllerBase
{
    [HttpGet("roles")]
    public Task<IReadOnlyList<RoleDto>> List(CancellationToken ct) => roles.ListAsync(ct);

    [HttpPost("roles")]
    [ProducesResponseType<RoleDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(RoleRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await roles.CreateAsync(request, ct));

    [HttpPut("roles/{id:guid}")]
    public Task<RoleDto> Update(Guid id, RoleRequest request, CancellationToken ct) => roles.UpdateAsync(id, request, ct);

    [HttpDelete("roles/{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await roles.DeleteAsync(id, ct);
        return NoContent();
    }

    [HttpGet("permissions")]
    public IReadOnlyList<string> ListPermissions() => Permissions.All;
}

[Route("api/v{version:apiVersion}/admin/system-settings")]
[HasPermission(Permissions.SettingsManage)]
public sealed class AdminSystemSettingsController(ISystemSettingsAdminService settings) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<SystemSettingDto>> List(CancellationToken ct) => settings.ListAsync(ct);

    [HttpPut("{key}")]
    public Task<SystemSettingDto> Update(string key, UpdateSystemSettingRequest request, CancellationToken ct) =>
        settings.UpdateAsync(key, request, ct);
}

[Route("api/v{version:apiVersion}/admin/app-versions")]
[HasPermission(Permissions.VersionsManage)]
public sealed class AdminAppVersionsController(IAppVersionService versions) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<AppVersionDto>> List([FromQuery] string? platform, CancellationToken ct) => versions.ListAsync(platform, ct);

    [HttpPost]
    [ProducesResponseType<AppVersionDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(AppVersionRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await versions.CreateAsync(request, ct));

    [HttpPut("{id:guid}")]
    public Task<AppVersionDto> Update(Guid id, AppVersionRequest request, CancellationToken ct) => versions.UpdateAsync(id, request, ct);

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await versions.DeleteAsync(id, ct);
        return NoContent();
    }

    /// <summary>Uploads the APK to Supabase Storage and sets the download URL.</summary>
    [HttpPost("{id:guid}/artifact")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(AppVersionService.MaxArtifactBytes + 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = AppVersionService.MaxArtifactBytes + 1024 * 1024)]
    public async Task<AppVersionDto> UploadArtifact(Guid id, IFormFile file, CancellationToken ct)
    {
        await using var stream = file.OpenReadStream();
        return await versions.UploadArtifactAsync(id, new ArtifactUpload(stream, file.Length, file.FileName), ct);
    }
}

[Route("api/v{version:apiVersion}/admin/announcements")]
[HasPermission(Permissions.AnnouncementsManage)]
public sealed class AdminAnnouncementsController(IAnnouncementService announcements) : ApiControllerBase
{
    [HttpGet]
    public Task<PagedResult<AdminAnnouncementDto>> List([FromQuery] PageQuery query, CancellationToken ct) => announcements.ListAsync(query, ct);

    [HttpPost]
    [ProducesResponseType<AdminAnnouncementDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(AnnouncementRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await announcements.CreateAsync(request, ct));

    [HttpPut("{id:guid}")]
    public Task<AdminAnnouncementDto> Update(Guid id, AnnouncementRequest request, CancellationToken ct) => announcements.UpdateAsync(id, request, ct);

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await announcements.DeleteAsync(id, ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/admin/audit-logs")]
[HasPermission(Permissions.AuditRead)]
public sealed class AdminAuditLogsController(IAuditLogService audit) : ApiControllerBase
{
    [HttpGet]
    public Task<PagedResult<AuditLogDto>> List([FromQuery] AuditLogQuery query, CancellationToken ct) => audit.ListAsync(query, ct);
}

[Route("api/v{version:apiVersion}/admin/contact-messages")]
[HasPermission(Permissions.MessagesManage)]
public sealed class AdminContactMessagesController(IContactMessageService messages) : ApiControllerBase
{
    [HttpGet]
    public Task<PagedResult<ContactMessageDto>> List([FromQuery] ContactMessageQuery query, CancellationToken ct) => messages.ListAsync(query, ct);

    [HttpPatch("{id:guid}")]
    public Task<ContactMessageDto> UpdateStatus(Guid id, UpdateContactMessageRequest request, CancellationToken ct) =>
        messages.UpdateStatusAsync(id, request, ct);
}
