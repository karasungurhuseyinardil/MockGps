namespace MockGps.Domain;

public static class Permissions
{
    public const string DashboardRead = "dashboard.read";
    public const string UsersRead = "users.read";
    public const string UsersManage = "users.manage";
    public const string RolesManage = "roles.manage";
    public const string SettingsManage = "settings.manage";
    public const string VersionsManage = "versions.manage";
    public const string AnnouncementsManage = "announcements.manage";
    public const string AuditRead = "audit.read";
    public const string MessagesManage = "messages.manage";

    public static readonly IReadOnlyList<string> All =
    [
        DashboardRead, UsersRead, UsersManage, RolesManage, SettingsManage,
        VersionsManage, AnnouncementsManage, AuditRead, MessagesManage,
    ];
}

public static class SystemRoles
{
    public const string User = "user";
    public const string Admin = "admin";
    public const string SuperAdmin = "superadmin";
}

public static class Themes
{
    public const string System = "system";
    public const string Light = "light";
    public const string Dark = "dark";
    public static readonly IReadOnlyList<string> All = [System, Light, Dark];
}

public static class Languages
{
    public const string English = "en";
    public const string Turkish = "tr";
    public static readonly IReadOnlyList<string> All = [English, Turkish];
}

public static class MapTypes
{
    public const string Standard = "standard";
    public const string Light = "light";
    public const string Dark = "dark";
    public const string Satellite = "satellite";
    public static readonly IReadOnlyList<string> All = [Standard, Light, Dark, Satellite];
}

public static class HistorySources
{
    public const string Map = "map";
    public static readonly IReadOnlyList<string> All = ["map", "manual", "search", "favorite", "route", "history"];
}

public static class Platforms
{
    public const string Android = "android";
    public const string Ios = "ios";
    public const string Web = "web";
    public static readonly IReadOnlyList<string> All = [Android, Ios, Web];
    public static readonly IReadOnlyList<string> Mobile = [Android, Ios];
}

public static class UsageEventTypes
{
    public const string SimulationStarted = "simulation_started";
    public const string SimulationStopped = "simulation_stopped";
    public const string RouteStarted = "route_started";
    public const string FavoriteActivated = "favorite_activated";
    public const string SearchUsed = "search_used";
    public const string GpxExported = "gpx_exported";
    public const string AppOpened = "app_opened";

    public static readonly IReadOnlyList<string> All =
        [SimulationStarted, SimulationStopped, RouteStarted, FavoriteActivated, SearchUsed, GpxExported, AppOpened];
}

public static class AnnouncementLevels
{
    public const string Info = "info";
    public static readonly IReadOnlyList<string> All = ["info", "warning", "critical"];
}

public static class AnnouncementAudiences
{
    public const string All = "all";
    public static readonly IReadOnlyList<string> Values = ["all", "android", "ios", "web"];
}

public static class ContactStatuses
{
    public const string New = "new";
    public static readonly IReadOnlyList<string> All = ["new", "read", "archived"];
}

public static class SystemSettingKeys
{
    public const string MaintenanceMode = "maintenance_mode";
    public const string GeocodingEnabled = "geocoding_enabled";
    public const string HistoryMaxCloudItems = "history_max_cloud_items";
    public const string SupportEmail = "support_email";
}
