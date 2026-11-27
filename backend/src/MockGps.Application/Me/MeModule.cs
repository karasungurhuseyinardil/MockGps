using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MockGps.Application.Access;
using MockGps.Application.Common;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Me;

public record SettingsDto(
    string Theme,
    string Language,
    string DefaultMapType,
    bool HistoryEnabled,
    bool HistoryCloudSync,
    bool NotificationsEnabled,
    int DefaultAccuracyM,
    int UpdateIntervalMs);

public record MeResponse(
    Guid Id,
    string Email,
    string? DisplayName,
    string? AvatarUrl,
    DateTimeOffset CreatedAt,
    IReadOnlyList<string> Roles,
    IReadOnlyList<string> Permissions,
    SettingsDto Settings);

public record UpdateProfileRequest(string? DisplayName);

public record AvatarUpload(Stream Content, string ContentType, long Length);

public class UpdateProfileValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileValidator() => RuleFor(x => x.DisplayName).MaximumLength(80);
}

public class SettingsValidator : AbstractValidator<SettingsDto>
{
    public SettingsValidator()
    {
        RuleFor(x => x.Theme).OneOfRequired(Themes.All);
        RuleFor(x => x.Language).OneOfRequired(Languages.All);
        RuleFor(x => x.DefaultMapType).OneOfRequired(MapTypes.All);
        RuleFor(x => x.DefaultAccuracyM).InclusiveBetween(1, 500);
        RuleFor(x => x.UpdateIntervalMs).InclusiveBetween(200, 60000);
    }
}

public interface IMeService
{
    Task<MeResponse> GetAsync(CancellationToken ct);
    Task<MeResponse> UpdateProfileAsync(UpdateProfileRequest request, CancellationToken ct);
    Task<MeResponse> UploadAvatarAsync(AvatarUpload upload, CancellationToken ct);
    Task<MeResponse> RemoveAvatarAsync(CancellationToken ct);
    Task<SettingsDto> GetSettingsAsync(CancellationToken ct);
    Task<SettingsDto> UpdateSettingsAsync(SettingsDto request, CancellationToken ct);
    Task<object> ExportAsync(CancellationToken ct);
    Task DeleteAccountAsync(CancellationToken ct);
}

public sealed class MeService(
    IUserDataScope scope,
    ICurrentUser currentUser,
    IUserAccessService access,
    IStorageClient storage,
    IAuthAdminClient authAdmin,
    IAppDbContext db,
    IAuditLogger audit,
    IRequestValidator validator,
    TimeProvider clock,
    ILogger<MeService> logger) : IMeService
{
    public const long MaxAvatarBytes = 2 * 1024 * 1024;

    public async Task<MeResponse> GetAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        var (profile, settings) = await scope.RunAsync(async ctx =>
        {
            var p = await ctx.Profiles.AsNoTracking().FirstOrDefaultAsync(x => x.Id == uid, ct);
            var s = await ctx.UserSettings.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == uid, ct);
            return (p, s);
        }, ct);

        if (profile is null || settings is null) throw new NotFoundException("Profile");
        var userAccess = await access.GetAsync(uid, ct) ?? throw new NotFoundException("Profile");

        return new MeResponse(
            profile.Id,
            profile.Email,
            profile.DisplayName,
            await AvatarUrlAsync(profile.AvatarPath, ct),
            profile.CreatedAt,
            userAccess.Roles,
            userAccess.Permissions,
            ToDto(settings));
    }

    public async Task<MeResponse> UpdateProfileAsync(UpdateProfileRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        await scope.RunAsync(async ctx =>
        {
            var profile = await ctx.Profiles.FirstOrDefaultAsync(x => x.Id == uid, ct)
                ?? throw new NotFoundException("Profile");
            profile.DisplayName = Text.Clean(request.DisplayName);
            await ctx.SaveChangesAsync(ct);
        }, ct);
        return await GetAsync(ct);
    }

    public async Task<MeResponse> UploadAvatarAsync(AvatarUpload upload, CancellationToken ct)
    {
        if (upload.Length <= 0 || upload.Length > MaxAvatarBytes)
            throw new BusinessRuleException("Avatar must be smaller than 2 MB.", "avatar_too_large");

        using var buffer = new MemoryStream();
        await upload.Content.CopyToAsync(buffer, ct);
        var bytes = buffer.ToArray();
        var extension = ImageSniffer.Detect(bytes)
            ?? throw new BusinessRuleException("Avatar must be a PNG, JPEG or WebP image.", "avatar_invalid_type");

        var uid = currentUser.UserId;
        var path = $"{uid}/{Guid.NewGuid():N}.{extension}";
        await storage.UploadAsync(StorageBuckets.Avatars, path, new MemoryStream(bytes), ImageSniffer.ContentType(extension), ct);

        var previous = await scope.RunAsync(async ctx =>
        {
            var profile = await ctx.Profiles.FirstOrDefaultAsync(x => x.Id == uid, ct)
                ?? throw new NotFoundException("Profile");
            var old = profile.AvatarPath;
            profile.AvatarPath = path;
            await ctx.SaveChangesAsync(ct);
            return old;
        }, ct);

        await DeleteAvatarFileAsync(previous, ct);
        return await GetAsync(ct);
    }

    public async Task<MeResponse> RemoveAvatarAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        var previous = await scope.RunAsync(async ctx =>
        {
            var profile = await ctx.Profiles.FirstOrDefaultAsync(x => x.Id == uid, ct)
                ?? throw new NotFoundException("Profile");
            var old = profile.AvatarPath;
            profile.AvatarPath = null;
            await ctx.SaveChangesAsync(ct);
            return old;
        }, ct);
        await DeleteAvatarFileAsync(previous, ct);
        return await GetAsync(ct);
    }

    public async Task<SettingsDto> GetSettingsAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        var settings = await scope.RunAsync(ctx => ctx.UserSettings.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == uid, ct), ct)
            ?? throw new NotFoundException("Settings");
        return ToDto(settings);
    }

    public async Task<SettingsDto> UpdateSettingsAsync(SettingsDto request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var uid = currentUser.UserId;
        return await scope.RunAsync(async ctx =>
        {
            var s = await ctx.UserSettings.FirstOrDefaultAsync(x => x.UserId == uid, ct)
                ?? throw new NotFoundException("Settings");

            s.Theme = request.Theme;
            s.Language = request.Language;
            s.DefaultMapType = request.DefaultMapType;
            s.HistoryEnabled = request.HistoryEnabled;
            s.HistoryCloudSync = request.HistoryCloudSync && request.HistoryEnabled;
            s.NotificationsEnabled = request.NotificationsEnabled;
            s.DefaultAccuracyM = request.DefaultAccuracyM;
            s.UpdateIntervalMs = request.UpdateIntervalMs;
            await ctx.SaveChangesAsync(ct);

            // Turning cloud sync off removes the cloud copy; the device keeps its local history.
            if (!s.HistoryCloudSync)
            {
                await ctx.LocationHistory.Where(h => h.UserId == uid).ExecuteDeleteAsync(ct);
            }
            return ToDto(s);
        }, ct);
    }

    public async Task<object> ExportAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        var me = await GetAsync(ct);
        return await scope.RunAsync<object>(async ctx => new
        {
            exportedAt = clock.GetUtcNow(),
            profile = new { me.Id, me.Email, me.DisplayName, me.CreatedAt, me.Roles },
            settings = me.Settings,
            categories = await ctx.LocationCategories.AsNoTracking().Where(x => x.UserId == uid)
                .OrderBy(x => x.SortOrder).Select(x => new { x.Id, x.Name, x.Icon, x.Color, x.SortOrder }).ToListAsync(ct),
            favorites = await ctx.FavoriteLocations.AsNoTracking().Where(x => x.UserId == uid)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new { x.Id, x.Name, x.Description, x.Latitude, x.Longitude, x.Address, x.CategoryId, x.CreatedAt }).ToListAsync(ct),
            routes = await ctx.SavedRoutes.AsNoTracking().Where(x => x.UserId == uid)
                .OrderBy(x => x.CreatedAt)
                .Select(x => new { x.Id, x.Name, x.Points, x.SpeedKmh, x.Loop, x.CreatedAt }).ToListAsync(ct),
            cloudHistory = await ctx.LocationHistory.AsNoTracking().Where(x => x.UserId == uid)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new { x.Latitude, x.Longitude, x.Address, x.Source, x.CreatedAt }).ToListAsync(ct),
        }, ct);
    }

    public async Task DeleteAccountAsync(CancellationToken ct)
    {
        var uid = currentUser.UserId;
        var avatarPath = await db.Profiles.Where(p => p.Id == uid).Select(p => p.AvatarPath).FirstOrDefaultAsync(ct);

        // Audit first: the row survives the cascade with user_id set to NULL.
        audit.Add("account.deleted", "user", uid.ToString(), "User deleted their account");
        await db.SaveChangesAsync(ct);

        await DeleteAvatarFileAsync(avatarPath, ct);
        // Deleting the Auth user cascades to profile, settings, categories, favorites, routes and history.
        await authAdmin.DeleteUserAsync(uid, ct);
        access.Invalidate(uid);
        logger.LogInformation("Account {UserId} deleted", uid);
    }

    private async Task<string?> AvatarUrlAsync(string? path, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(path)) return null;
        try
        {
            return await storage.CreateSignedUrlAsync(StorageBuckets.Avatars, path, TimeSpan.FromHours(1), ct);
        }
        catch (ExternalServiceException e)
        {
            logger.LogWarning(e, "Could not sign avatar url");
            return null;
        }
    }

    private async Task DeleteAvatarFileAsync(string? path, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(path)) return;
        try
        {
            await storage.DeleteAsync(StorageBuckets.Avatars, [path], ct);
        }
        catch (ExternalServiceException e)
        {
            logger.LogWarning(e, "Could not delete avatar file");
        }
    }

    internal static SettingsDto ToDto(UserSettings s) => new(
        s.Theme, s.Language, s.DefaultMapType, s.HistoryEnabled, s.HistoryCloudSync,
        s.NotificationsEnabled, s.DefaultAccuracyM, s.UpdateIntervalMs);
}

/// <summary>Detects image type from magic bytes instead of trusting the client content type.</summary>
public static class ImageSniffer
{
    public static string? Detect(ReadOnlySpan<byte> b)
    {
        if (b.Length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return "png";
        if (b.Length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return "jpg";
        if (b.Length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F' &&
            b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "webp";
        return null;
    }

    public static string ContentType(string extension) => extension switch
    {
        "png" => "image/png",
        "jpg" => "image/jpeg",
        "webp" => "image/webp",
        _ => "application/octet-stream",
    };
}
