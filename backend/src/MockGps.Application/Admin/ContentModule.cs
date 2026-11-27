using System.Linq.Expressions;
using System.Text.Json;
using FluentValidation;
using FluentValidation.Validators;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using MockGps.Application.SystemSettings;
using MockGps.Domain;
using MockGps.Domain.Entities;

namespace MockGps.Application.Admin;

// ---------------------------------------------------------------------------
// System settings
// ---------------------------------------------------------------------------
public record SystemSettingDto(string Key, JsonElement Value, string? Description, DateTimeOffset UpdatedAt, Guid? UpdatedBy);
public record UpdateSystemSettingRequest(JsonElement Value);

public interface ISystemSettingsAdminService
{
    Task<IReadOnlyList<SystemSettingDto>> ListAsync(CancellationToken ct);
    Task<SystemSettingDto> UpdateAsync(string key, UpdateSystemSettingRequest request, CancellationToken ct);
}

public sealed class SystemSettingsAdminService(
    IAppDbContext db, ICurrentUser currentUser, IAuditLogger audit, ISystemSettingsProvider provider) : ISystemSettingsAdminService
{
    public async Task<IReadOnlyList<SystemSettingDto>> ListAsync(CancellationToken ct)
    {
        var rows = await db.SystemSettings.AsNoTracking().OrderBy(s => s.Key).ToListAsync(ct);
        return rows.Select(ToDto).ToList();
    }

    public async Task<SystemSettingDto> UpdateAsync(string key, UpdateSystemSettingRequest request, CancellationToken ct)
    {
        var setting = await db.SystemSettings.FirstOrDefaultAsync(s => s.Key == key, ct) ?? throw new NotFoundException("Setting");
        var error = ValidateValue(key, request.Value);
        if (error is not null) throw new BusinessRuleException(error, "invalid_setting_value");

        var before = setting.Value;
        setting.Value = request.Value.GetRawText();
        setting.UpdatedBy = currentUser.UserId;
        audit.Add("setting.updated", "system_setting", key, $"Setting '{key}' changed", new { before, after = setting.Value });
        await db.SaveChangesAsync(ct);
        provider.Invalidate();
        return ToDto(setting);
    }

    /// <summary>Every known setting has a fixed type; unknown keys do not exist in the table.</summary>
    internal static string? ValidateValue(string key, JsonElement value) => key switch
    {
        SystemSettingKeys.MaintenanceMode or SystemSettingKeys.GeocodingEnabled =>
            value.ValueKind is JsonValueKind.True or JsonValueKind.False ? null : "Value must be true or false.",
        SystemSettingKeys.HistoryMaxCloudItems =>
            value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var n) && n is >= 10 and <= 10_000
                ? null : "Value must be a whole number between 10 and 10000.",
        SystemSettingKeys.SupportEmail =>
            value.ValueKind == JsonValueKind.String && IsEmail(value.GetString()) ? null : "Value must be an email address.",
        _ => "This setting cannot be changed.",
    };

    private static bool IsEmail(string? s) =>
        !string.IsNullOrWhiteSpace(s) && s.Length <= 254 && s.IndexOf('@') is > 0 && s.IndexOf('@') < s.Length - 1 && !s.Contains(' ');

    private static SystemSettingDto ToDto(SystemSetting s)
    {
        using var doc = JsonDocument.Parse(s.Value);
        return new SystemSettingDto(s.Key, doc.RootElement.Clone(), s.Description, s.UpdatedAt, s.UpdatedBy);
    }
}

// ---------------------------------------------------------------------------
// App versions
// ---------------------------------------------------------------------------
public record AppVersionDto(
    Guid Id, string Platform, string Version, int BuildNumber, int MinSupportedBuild, string? DownloadUrl,
    long? FileSizeBytes, string? ReleaseNotes, bool IsPublished, DateTimeOffset? PublishedAt, DateTimeOffset CreatedAt);

public record AppVersionRequest(
    string Platform, string Version, int BuildNumber, int MinSupportedBuild, string? DownloadUrl, string? ReleaseNotes, bool IsPublished);

public record ArtifactUpload(Stream Content, long Length, string FileName);

public class AppVersionRequestValidator : AbstractValidator<AppVersionRequest>
{
    public AppVersionRequestValidator()
    {
        RuleFor(x => x.Platform).OneOfRequired(Platforms.Mobile);
        RuleFor(x => x.Version).NotEmpty().Matches(@"^\d+\.\d+\.\d+$").WithMessage("Version must look like 1.2.3.");
        RuleFor(x => x.BuildNumber).GreaterThan(0);
        RuleFor(x => x.MinSupportedBuild).GreaterThan(0).LessThanOrEqualTo(x => x.BuildNumber)
            .WithMessage("Minimum supported build cannot be higher than the build number.");
        RuleFor(x => x.DownloadUrl).MaximumLength(500)
            .Must(u => u is null || Uri.TryCreate(u, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps)
            .WithMessage("Download URL must be an https URL.");
        RuleFor(x => x.ReleaseNotes).MaximumLength(4000);
    }
}

public interface IAppVersionService
{
    Task<IReadOnlyList<AppVersionDto>> ListAsync(string? platform, CancellationToken ct);
    Task<AppVersionDto> CreateAsync(AppVersionRequest request, CancellationToken ct);
    Task<AppVersionDto> UpdateAsync(Guid id, AppVersionRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
    Task<AppVersionDto> UploadArtifactAsync(Guid id, ArtifactUpload upload, CancellationToken ct);
}

public sealed class AppVersionService(
    IAppDbContext db, IAuditLogger audit, IStorageClient storage, IRequestValidator validator, TimeProvider clock) : IAppVersionService
{
    public const long MaxArtifactBytes = 200L * 1024 * 1024;

    private static readonly Expression<Func<AppVersion, AppVersionDto>> ToDto = v => new AppVersionDto(
        v.Id, v.Platform, v.Version, v.BuildNumber, v.MinSupportedBuild, v.DownloadUrl, v.FileSizeBytes,
        v.ReleaseNotes, v.IsPublished, v.PublishedAt, v.CreatedAt);

    public async Task<IReadOnlyList<AppVersionDto>> ListAsync(string? platform, CancellationToken ct)
    {
        var q = db.AppVersions.AsNoTracking();
        if (!string.IsNullOrEmpty(platform)) q = q.Where(v => v.Platform == platform);
        return await q.OrderBy(v => v.Platform).ThenByDescending(v => v.BuildNumber).Select(ToDto).ToListAsync(ct);
    }

    public async Task<AppVersionDto> CreateAsync(AppVersionRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        if (await db.AppVersions.AnyAsync(v => v.Platform == request.Platform && v.BuildNumber == request.BuildNumber, ct))
            throw new ConflictException("This build number already exists for the platform.", "version_exists");

        var version = new AppVersion { Id = Guid.NewGuid() };
        Apply(version, request);
        db.AppVersions.Add(version);
        audit.Add("version.created", "app_version", version.Id.ToString(), $"{version.Platform} {version.Version} ({version.BuildNumber}) created");
        await db.SaveChangesAsync(ct);
        return await GetAsync(version.Id, ct);
    }

    public async Task<AppVersionDto> UpdateAsync(Guid id, AppVersionRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var version = await db.AppVersions.FirstOrDefaultAsync(v => v.Id == id, ct) ?? throw new NotFoundException("Version");
        if (await db.AppVersions.AnyAsync(v => v.Id != id && v.Platform == request.Platform && v.BuildNumber == request.BuildNumber, ct))
            throw new ConflictException("This build number already exists for the platform.", "version_exists");

        Apply(version, request);
        audit.Add("version.updated", "app_version", id.ToString(), $"{version.Platform} {version.Version} ({version.BuildNumber}) updated",
            new { version.IsPublished });
        await db.SaveChangesAsync(ct);
        return await GetAsync(id, ct);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var version = await db.AppVersions.FirstOrDefaultAsync(v => v.Id == id, ct) ?? throw new NotFoundException("Version");
        db.AppVersions.Remove(version);
        audit.Add("version.deleted", "app_version", id.ToString(), $"{version.Platform} {version.Version} ({version.BuildNumber}) deleted");
        await db.SaveChangesAsync(ct);
        if (version.DownloadUrl is { } url && TryGetReleasePath(url, out var path))
        {
            try { await storage.DeleteAsync(StorageBuckets.Releases, [path], ct); }
            catch (ExternalServiceException) { /* file cleanup is best effort */ }
        }
    }

    public async Task<AppVersionDto> UploadArtifactAsync(Guid id, ArtifactUpload upload, CancellationToken ct)
    {
        var version = await db.AppVersions.FirstOrDefaultAsync(v => v.Id == id, ct) ?? throw new NotFoundException("Version");
        if (version.Platform != Platforms.Android)
            throw new BusinessRuleException("Only Android builds can be uploaded as APK files.", "artifact_platform");
        if (upload.Length <= 0 || upload.Length > MaxArtifactBytes)
            throw new BusinessRuleException("The APK must be smaller than 200 MB.", "artifact_too_large");
        if (!upload.FileName.EndsWith(".apk", StringComparison.OrdinalIgnoreCase))
            throw new BusinessRuleException("Upload an .apk file.", "artifact_invalid_type");

        // APK files are ZIP archives: check the "PK\x03\x04" signature.
        var header = new byte[4];
        var read = await upload.Content.ReadAtLeastAsync(header, 4, throwOnEndOfStream: false, ct);
        if (read < 4 || header[0] != 0x50 || header[1] != 0x4B || header[2] != 0x03 || header[3] != 0x04)
            throw new BusinessRuleException("The file is not a valid APK.", "artifact_invalid_type");

        var path = $"android/mockgps-{version.Version}-{version.BuildNumber}.apk";
        var content = new ConcatStream(header, upload.Content);
        await storage.UploadAsync(StorageBuckets.Releases, path, content, "application/vnd.android.package-archive", ct);

        version.DownloadUrl = storage.GetPublicUrl(StorageBuckets.Releases, path);
        version.FileSizeBytes = upload.Length;
        audit.Add("version.artifact_uploaded", "app_version", id.ToString(), $"APK uploaded for {version.Version} ({version.BuildNumber})",
            new { upload.Length });
        await db.SaveChangesAsync(ct);
        return await GetAsync(id, ct);
    }

    private void Apply(AppVersion v, AppVersionRequest r)
    {
        v.Platform = r.Platform;
        v.Version = r.Version;
        v.BuildNumber = r.BuildNumber;
        v.MinSupportedBuild = r.MinSupportedBuild;
        v.ReleaseNotes = Text.Clean(r.ReleaseNotes);
        if (r.DownloadUrl is not null) v.DownloadUrl = Text.Clean(r.DownloadUrl);
        if (r.IsPublished && !v.IsPublished) v.PublishedAt = clock.GetUtcNow();
        if (!r.IsPublished) v.PublishedAt = null;
        v.IsPublished = r.IsPublished;
    }

    private async Task<AppVersionDto> GetAsync(Guid id, CancellationToken ct) =>
        await db.AppVersions.AsNoTracking().Where(v => v.Id == id).Select(ToDto).FirstAsync(ct);

    private static bool TryGetReleasePath(string url, out string path)
    {
        const string marker = "/storage/v1/object/public/releases/";
        var i = url.IndexOf(marker, StringComparison.Ordinal);
        path = i >= 0 ? url[(i + marker.Length)..] : string.Empty;
        return i >= 0;
    }

    /// <summary>Re-attaches already-read header bytes in front of the remaining stream.</summary>
    private sealed class ConcatStream(byte[] head, Stream tail) : Stream
    {
        private int _pos;
        public override bool CanRead => true;
        public override bool CanSeek => false;
        public override bool CanWrite => false;
        public override long Length => throw new NotSupportedException();
        public override long Position { get => throw new NotSupportedException(); set => throw new NotSupportedException(); }
        public override void Flush() { }
        public override int Read(byte[] buffer, int offset, int count)
        {
            if (_pos < head.Length)
            {
                var n = Math.Min(count, head.Length - _pos);
                Array.Copy(head, _pos, buffer, offset, n);
                _pos += n;
                return n;
            }
            return tail.Read(buffer, offset, count);
        }
        public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default)
        {
            if (_pos < head.Length)
            {
                var n = Math.Min(buffer.Length, head.Length - _pos);
                head.AsMemory(_pos, n).CopyTo(buffer);
                _pos += n;
                return n;
            }
            return await tail.ReadAsync(buffer, cancellationToken);
        }
        public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
        public override void SetLength(long value) => throw new NotSupportedException();
        public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();
    }
}

// ---------------------------------------------------------------------------
// Announcements
// ---------------------------------------------------------------------------
public record AdminAnnouncementDto(
    Guid Id, string Title, string Body, string Level, string Audience, DateTimeOffset StartsAt, DateTimeOffset? EndsAt,
    bool IsActive, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record AnnouncementRequest(string Title, string Body, string Level, string Audience, DateTimeOffset? StartsAt, DateTimeOffset? EndsAt, bool IsActive);

public class AnnouncementRequestValidator : AbstractValidator<AnnouncementRequest>
{
    public AnnouncementRequestValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Body).NotEmpty().MaximumLength(2000);
        RuleFor(x => x.Level).OneOfRequired(AnnouncementLevels.All);
        RuleFor(x => x.Audience).OneOfRequired(AnnouncementAudiences.Values);
        RuleFor(x => x).Must(x => x.EndsAt is null || x.EndsAt > (x.StartsAt ?? DateTimeOffset.MinValue))
            .WithMessage("End date must be after the start date.");
    }
}

public interface IAnnouncementService
{
    Task<PagedResult<AdminAnnouncementDto>> ListAsync(PageQuery query, CancellationToken ct);
    Task<AdminAnnouncementDto> CreateAsync(AnnouncementRequest request, CancellationToken ct);
    Task<AdminAnnouncementDto> UpdateAsync(Guid id, AnnouncementRequest request, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}

public sealed class AnnouncementService(
    IAppDbContext db, ICurrentUser currentUser, IAuditLogger audit, IRequestValidator validator, TimeProvider clock) : IAnnouncementService
{
    private static readonly Dictionary<string, Expression<Func<Announcement, object?>>> Sorts = new()
    {
        ["created_at"] = a => a.CreatedAt,
        ["starts_at"] = a => a.StartsAt,
        ["title"] = a => a.Title,
    };

    private static readonly Expression<Func<Announcement, AdminAnnouncementDto>> ToDto = a => new AdminAnnouncementDto(
        a.Id, a.Title, a.Body, a.Level, a.Audience, a.StartsAt, a.EndsAt, a.IsActive, a.CreatedAt, a.UpdatedAt);

    public async Task<PagedResult<AdminAnnouncementDto>> ListAsync(PageQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        return await db.Announcements.AsNoTracking().ApplySort(query.Sort, Sorts, "created_at:desc").ToPagedAsync(query, ToDto, ct);
    }

    public async Task<AdminAnnouncementDto> CreateAsync(AnnouncementRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var a = new Announcement { Id = Guid.NewGuid(), CreatedBy = currentUser.UserId };
        Apply(a, request);
        db.Announcements.Add(a);
        audit.Add("announcement.created", "announcement", a.Id.ToString(), $"Announcement '{a.Title}' created");
        await db.SaveChangesAsync(ct);
        return await db.Announcements.AsNoTracking().Where(x => x.Id == a.Id).Select(ToDto).FirstAsync(ct);
    }

    public async Task<AdminAnnouncementDto> UpdateAsync(Guid id, AnnouncementRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var a = await db.Announcements.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NotFoundException("Announcement");
        Apply(a, request);
        audit.Add("announcement.updated", "announcement", id.ToString(), $"Announcement '{a.Title}' updated", new { a.IsActive });
        await db.SaveChangesAsync(ct);
        return await db.Announcements.AsNoTracking().Where(x => x.Id == id).Select(ToDto).FirstAsync(ct);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct)
    {
        var a = await db.Announcements.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NotFoundException("Announcement");
        db.Announcements.Remove(a);
        audit.Add("announcement.deleted", "announcement", id.ToString(), $"Announcement '{a.Title}' deleted");
        await db.SaveChangesAsync(ct);
    }

    private void Apply(Announcement a, AnnouncementRequest r)
    {
        a.Title = r.Title.Trim();
        a.Body = r.Body.Trim();
        a.Level = r.Level;
        a.Audience = r.Audience;
        a.StartsAt = r.StartsAt ?? (a.StartsAt == default ? clock.GetUtcNow() : a.StartsAt);
        a.EndsAt = r.EndsAt;
        a.IsActive = r.IsActive;
    }
}

// ---------------------------------------------------------------------------
// Audit logs
// ---------------------------------------------------------------------------
public record AuditLogDto(
    Guid Id, Guid? UserId, string? UserEmail, string Action, string Entity, string? EntityId, string? Description,
    JsonElement? Metadata, string? IpAddress, DateTimeOffset CreatedAt);

public class AuditLogQuery : PageQuery
{
    public Guid? UserId { get; set; }
    public string? Action { get; set; }
    public string? Entity { get; set; }
    public DateTimeOffset? From { get; set; }
    public DateTimeOffset? To { get; set; }
}

public class AuditLogQueryValidator : PageQueryValidator<AuditLogQuery>
{
    public AuditLogQueryValidator()
    {
        RuleFor(x => x.Action).MaximumLength(64);
        RuleFor(x => x.Entity).MaximumLength(64);
    }
}

public interface IAuditLogService
{
    Task<PagedResult<AuditLogDto>> ListAsync(AuditLogQuery query, CancellationToken ct);
}

public sealed class AuditLogService(IAppDbContext db, IRequestValidator validator) : IAuditLogService
{
    public async Task<PagedResult<AuditLogDto>> ListAsync(AuditLogQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var q = db.AuditLogs.AsNoTracking();
        if (query.UserId is { } uid) q = q.Where(a => a.UserId == uid);
        if (Text.Clean(query.Action) is { } action) q = q.Where(a => a.Action.StartsWith(action));
        if (Text.Clean(query.Entity) is { } entity) q = q.Where(a => a.Entity == entity);
        if (query.From is { } from) q = q.Where(a => a.CreatedAt >= from);
        if (query.To is { } to) q = q.Where(a => a.CreatedAt <= to);

        var total = await q.CountAsync(ct);
        var rows = await q.OrderByDescending(a => a.CreatedAt)
            .Skip((query.Page - 1) * query.PageSize).Take(query.PageSize)
            .Select(a => new
            {
                a.Id, a.UserId, Email = db.Profiles.Where(p => p.Id == a.UserId).Select(p => p.Email).FirstOrDefault(),
                a.Action, a.Entity, a.EntityId, a.Description, a.Metadata, a.IpAddress, a.CreatedAt,
            })
            .ToListAsync(ct);

        var items = rows.Select(r => new AuditLogDto(r.Id, r.UserId, r.Email, r.Action, r.Entity, r.EntityId, r.Description,
            r.Metadata is null ? null : JsonDocument.Parse(r.Metadata).RootElement.Clone(), r.IpAddress, r.CreatedAt)).ToList();
        return new PagedResult<AuditLogDto>(items, query.Page, query.PageSize, total);
    }
}

// ---------------------------------------------------------------------------
// Contact messages
// ---------------------------------------------------------------------------
public record ContactMessageDto(Guid Id, string Name, string Email, string Subject, string Message, string Status, DateTimeOffset CreatedAt);

public class ContactMessageQuery : PageQuery
{
    public string? Status { get; set; }
}

public record UpdateContactMessageRequest(string Status);

public class ContactMessageQueryValidator : PageQueryValidator<ContactMessageQuery>
{
    public ContactMessageQueryValidator() => RuleFor(x => x.Status).OneOf(ContactStatuses.All);
}

public class UpdateContactMessageValidator : AbstractValidator<UpdateContactMessageRequest>
{
    public UpdateContactMessageValidator() => RuleFor(x => x.Status).OneOfRequired(ContactStatuses.All);
}

public interface IContactMessageService
{
    Task<PagedResult<ContactMessageDto>> ListAsync(ContactMessageQuery query, CancellationToken ct);
    Task<ContactMessageDto> UpdateStatusAsync(Guid id, UpdateContactMessageRequest request, CancellationToken ct);
}

public sealed class ContactMessageService(IAppDbContext db, IAuditLogger audit, IRequestValidator validator) : IContactMessageService
{
    private static readonly Expression<Func<ContactMessage, ContactMessageDto>> ToDto =
        m => new ContactMessageDto(m.Id, m.Name, m.Email, m.Subject, m.Message, m.Status, m.CreatedAt);

    public async Task<PagedResult<ContactMessageDto>> ListAsync(ContactMessageQuery query, CancellationToken ct)
    {
        await validator.ValidateAsync(query, ct);
        var q = db.ContactMessages.AsNoTracking();
        if (query.Status is { } status) q = q.Where(m => m.Status == status);
        return await q.OrderByDescending(m => m.CreatedAt).ToPagedAsync(query, ToDto, ct);
    }

    public async Task<ContactMessageDto> UpdateStatusAsync(Guid id, UpdateContactMessageRequest request, CancellationToken ct)
    {
        await validator.ValidateAsync(request, ct);
        var m = await db.ContactMessages.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NotFoundException("Message");
        m.Status = request.Status;
        audit.Add("message.status_changed", "contact_message", id.ToString(), $"Message marked as {request.Status}");
        await db.SaveChangesAsync(ct);
        return await db.ContactMessages.AsNoTracking().Where(x => x.Id == id).Select(ToDto).FirstAsync(ct);
    }
}
