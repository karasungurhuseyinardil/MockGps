using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MockGps.API.Infrastructure;
using MockGps.Application.Public;

namespace MockGps.API.Controllers.V1;

[ApiController]
[ApiVersion(1)]
[AllowAnonymous]
[Route("api/v{version:apiVersion}/public")]
[Produces("application/json")]
[ProducesResponseType(StatusCodes.Status200OK)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status400BadRequest)]
[EnableRateLimiting(RateLimitPolicies.Public)]
public sealed class PublicController(IPublicService publicService) : ControllerBase
{
    /// <summary>Runtime configuration for apps: update status, announcements, map styles, maintenance.</summary>
    [HttpGet("app-config")]
    public Task<AppConfigDto> AppConfig([FromQuery] string platform, [FromQuery] int? build, CancellationToken ct) =>
        publicService.GetAppConfigAsync(new AppConfigQuery(platform ?? string.Empty, build), ct);

    /// <summary>Latest published release for a platform. 204 when none is published.</summary>
    [HttpGet("releases/latest")]
    [ProducesResponseType<ReleaseDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> LatestRelease([FromQuery] string platform = "android", CancellationToken ct = default)
    {
        var release = await publicService.GetLatestReleaseAsync(platform, ct);
        return release is null ? NoContent() : Ok(release);
    }

    [HttpPost("contact")]
    [EnableRateLimiting(RateLimitPolicies.Contact)]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    public async Task<IActionResult> Contact(ContactRequest request, CancellationToken ct)
    {
        await publicService.SubmitContactAsync(request, ct);
        return Accepted();
    }
}
