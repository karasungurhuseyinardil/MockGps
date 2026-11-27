using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MockGps.API.Infrastructure;
using MockGps.Application.Common;
using MockGps.Application.Geocoding;
using MockGps.Application.Locations;
using MockGps.Application.Me;
using MockGps.Application.Usage;

namespace MockGps.API.Controllers.V1;

[ApiController]
[ApiVersion(1)]
[Authorize]
[Produces("application/json")]
// Untyped 200: ApiExplorer then documents the action's return type (Task<T>).
[ProducesResponseType(StatusCodes.Status200OK)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest)]
[ProducesResponseType(StatusCodes.Status401Unauthorized)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden)]
public abstract class ApiControllerBase : ControllerBase;

[Route("api/v{version:apiVersion}/me")]
public sealed class MeController(IMeService me) : ApiControllerBase
{
    /// <summary>Current user's profile, roles, permissions and settings.</summary>
    [HttpGet]
    public Task<MeResponse> Get(CancellationToken ct) => me.GetAsync(ct);

    [HttpPatch("profile")]
    public Task<MeResponse> UpdateProfile(UpdateProfileRequest request, CancellationToken ct) => me.UpdateProfileAsync(request, ct);

    /// <summary>Uploads a PNG, JPEG or WebP avatar (max 2 MB).</summary>
    [HttpPost("avatar")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MeService.MaxAvatarBytes + 64 * 1024)]
    public async Task<MeResponse> UploadAvatar(IFormFile file, CancellationToken ct)
    {
        await using var stream = file.OpenReadStream();
        return await me.UploadAvatarAsync(new AvatarUpload(stream, file.ContentType, file.Length), ct);
    }

    [HttpDelete("avatar")]
    public Task<MeResponse> RemoveAvatar(CancellationToken ct) => me.RemoveAvatarAsync(ct);

    [HttpGet("settings")]
    public Task<SettingsDto> GetSettings(CancellationToken ct) => me.GetSettingsAsync(ct);

    /// <summary>Replaces settings. Turning off cloud history sync deletes the cloud copy of the history.</summary>
    [HttpPut("settings")]
    public Task<SettingsDto> UpdateSettings(SettingsDto request, CancellationToken ct) => me.UpdateSettingsAsync(request, ct);

    /// <summary>Downloads all personal data stored for this account.</summary>
    [HttpGet("export")]
    public async Task<IActionResult> Export(CancellationToken ct)
    {
        Response.Headers.ContentDisposition = "attachment; filename=\"mockgps-export.json\"";
        return Ok(await me.ExportAsync(ct));
    }

    /// <summary>Permanently deletes the account and all personal data.</summary>
    [HttpDelete]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(CancellationToken ct)
    {
        await me.DeleteAccountAsync(ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/categories")]
public sealed class CategoriesController(ICategoryService categories) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<CategoryDto>> List(CancellationToken ct) => categories.ListAsync(ct);

    [HttpPost]
    [ProducesResponseType<CategoryDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(CategoryRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await categories.CreateAsync(request, ct));

    [HttpPut("{id:guid}")]
    public Task<CategoryDto> Update(Guid id, CategoryRequest request, CancellationToken ct) => categories.UpdateAsync(id, request, ct);

    /// <summary>Deletes a category. Its favorites are kept without a category.</summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await categories.DeleteAsync(id, ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/favorites")]
public sealed class FavoritesController(IFavoriteService favorites) : ApiControllerBase
{
    /// <summary>Lists favorites. Sort: name, created_at, updated_at (e.g. <c>name:asc</c>).</summary>
    [HttpGet]
    public Task<PagedResult<FavoriteDto>> List([FromQuery] FavoriteQuery query, CancellationToken ct) => favorites.ListAsync(query, ct);

    [HttpGet("{id:guid}")]
    public Task<FavoriteDto> Get(Guid id, CancellationToken ct) => favorites.GetAsync(id, ct);

    [HttpPost]
    [ProducesResponseType<FavoriteDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(FavoriteRequest request, CancellationToken ct)
    {
        var created = await favorites.CreateAsync(request, ct);
        return CreatedAtAction(nameof(Get), new { id = created.Id, version = "1" }, created);
    }

    [HttpPut("{id:guid}")]
    public Task<FavoriteDto> Update(Guid id, FavoriteRequest request, CancellationToken ct) => favorites.UpdateAsync(id, request, ct);

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await favorites.DeleteAsync(id, ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/history")]
public sealed class HistoryController(IHistoryService history) : ApiControllerBase
{
    [HttpGet]
    public Task<PagedResult<HistoryDto>> List([FromQuery] HistoryQuery query, CancellationToken ct) => history.ListAsync(query, ct);

    /// <summary>Uploads local history items (idempotent by clientId). Requires cloud sync enabled in settings.</summary>
    [HttpPost("batch")]
    public Task<HistoryBatchResult> AddBatch(HistoryBatchRequest request, CancellationToken ct) => history.AddBatchAsync(request, ct);

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await history.DeleteAsync(id, ct);
        return NoContent();
    }

    /// <summary>Deletes the cloud copy of a device history entry by its client id (idempotent).</summary>
    [HttpDelete("client/{clientId:guid}")]
    public async Task<IActionResult> DeleteByClientId(Guid clientId, CancellationToken ct)
    {
        await history.DeleteByClientIdAsync(clientId, ct);
        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult> Clear(CancellationToken ct)
    {
        await history.ClearAsync(ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/routes")]
public sealed class RoutesController(IRouteService routes) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<RouteDto>> List(CancellationToken ct) => routes.ListAsync(ct);

    [HttpGet("{id:guid}")]
    public Task<RouteDto> Get(Guid id, CancellationToken ct) => routes.GetAsync(id, ct);

    [HttpPost]
    [ProducesResponseType<RouteDto>(StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(RouteRequest request, CancellationToken ct)
    {
        var created = await routes.CreateAsync(request, ct);
        return CreatedAtAction(nameof(Get), new { id = created.Id, version = "1" }, created);
    }

    [HttpPut("{id:guid}")]
    public Task<RouteDto> Update(Guid id, RouteRequest request, CancellationToken ct) => routes.UpdateAsync(id, request, ct);

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await routes.DeleteAsync(id, ct);
        return NoContent();
    }
}

[Route("api/v{version:apiVersion}/geocoding")]
[EnableRateLimiting(RateLimitPolicies.Geocoding)]
public sealed class GeocodingController(IGeocodingService geocoding) : ApiControllerBase
{
    [HttpGet("search")]
    public Task<IReadOnlyList<GeocodingResult>> Search([FromQuery] string q, [FromQuery] string? lang, [FromQuery] int limit = 5, CancellationToken ct = default) =>
        geocoding.SearchAsync(new GeocodingSearchQuery(q ?? string.Empty, lang, limit), ct);

    /// <summary>Address for a coordinate. Returns 204 when nothing is found.</summary>
    [HttpGet("reverse")]
    [ProducesResponseType<GeocodingResult>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Reverse([FromQuery] double lat, [FromQuery] double lng, [FromQuery] string? lang, CancellationToken ct)
    {
        var result = await geocoding.ReverseAsync(new GeocodingReverseQuery(lat, lng, lang), ct);
        return result is null ? NoContent() : Ok(result);
    }
}

[Route("api/v{version:apiVersion}/usage-events")]
[EnableRateLimiting(RateLimitPolicies.Usage)]
public sealed class UsageEventsController(IUsageService usage) : ApiControllerBase
{
    /// <summary>Records anonymous usage events (no coordinates).</summary>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    public async Task<IActionResult> Record(UsageEventsRequest request, CancellationToken ct)
    {
        var count = await usage.RecordAsync(request, ct);
        return Accepted(new { recorded = count });
    }
}
