using System.Text.Json;
using MockGps.Application.Common;
using MockGps.Domain.Entities;

namespace MockGps.Infrastructure.Persistence;

public sealed class AuditLogger(AppDbContext db, ICurrentUser currentUser) : IAuditLogger
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public void Add(string action, string entity, string? entityId, string? description, object? metadata = null)
    {
        db.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = currentUser.IsAuthenticated ? currentUser.UserId : null,
            Action = action,
            Entity = entity,
            EntityId = entityId,
            Description = description is { Length: > 1000 } ? description[..1000] : description,
            Metadata = metadata is null ? null : JsonSerializer.Serialize(metadata, Json),
            IpAddress = currentUser.IpAddress,
        });
    }
}
