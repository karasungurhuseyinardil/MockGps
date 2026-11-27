using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using MockGps.Application.Access;
using MockGps.Application.Admin;
using MockGps.Application.Common;
using MockGps.Application.Geocoding;
using MockGps.Application.Locations;
using MockGps.Application.Me;
using MockGps.Application.Public;
using MockGps.Application.SystemSettings;
using MockGps.Application.Usage;

namespace MockGps.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly, includeInternalTypes: true);
        services.AddSingleton(TimeProvider.System);
        services.AddScoped<IRequestValidator, RequestValidator>();

        services.AddScoped<IUserAccessService, UserAccessService>();
        services.AddScoped<ISystemSettingsProvider, SystemSettingsProvider>();

        services.AddScoped<IMeService, MeService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IFavoriteService, FavoriteService>();
        services.AddScoped<IHistoryService, HistoryService>();
        services.AddScoped<IRouteService, RouteService>();
        services.AddScoped<IGeocodingService, GeocodingService>();
        services.AddScoped<IUsageService, UsageService>();
        services.AddScoped<IPublicService, PublicService>();

        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IAdminUserService, AdminUserService>();
        services.AddScoped<IRoleService, RoleService>();
        services.AddScoped<ISystemSettingsAdminService, SystemSettingsAdminService>();
        services.AddScoped<IAppVersionService, AppVersionService>();
        services.AddScoped<IAnnouncementService, AnnouncementService>();
        services.AddScoped<IAuditLogService, AuditLogService>();
        services.AddScoped<IContactMessageService, ContactMessageService>();
        return services;
    }
}
