namespace MockGps.Domain.Entities;

public class Profile
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? AvatarPath { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset? LastSeenAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public UserSettings? Settings { get; set; }
    public List<UserRole> UserRoles { get; set; } = [];
}

public class Role
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsSystem { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public List<RolePermission> Permissions { get; set; } = [];
    public List<UserRole> UserRoles { get; set; } = [];
}

public class RolePermission
{
    public Guid Id { get; set; }
    public Guid RoleId { get; set; }
    public string Permission { get; set; } = string.Empty;
}

public class UserRole
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public Role? Role { get; set; }
    public Profile? User { get; set; }
}

public class UserSettings
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Theme { get; set; } = Themes.System;
    public string Language { get; set; } = Languages.English;
    public string DefaultMapType { get; set; } = MapTypes.Standard;
    public bool HistoryEnabled { get; set; } = true;
    public bool HistoryCloudSync { get; set; }
    public bool NotificationsEnabled { get; set; } = true;
    public int DefaultAccuracyM { get; set; } = 5;
    public int UpdateIntervalMs { get; set; } = 1000;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
