using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MockGps.Application.Common;
using MockGps.Domain.Entities;

namespace MockGps.Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options), IAppDbContext
{
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<UserSettings> UserSettings => Set<UserSettings>();
    public DbSet<LocationCategory> LocationCategories => Set<LocationCategory>();
    public DbSet<FavoriteLocation> FavoriteLocations => Set<FavoriteLocation>();
    public DbSet<LocationHistoryEntry> LocationHistory => Set<LocationHistoryEntry>();
    public DbSet<SavedRoute> SavedRoutes => Set<SavedRoute>();
    public DbSet<UsageEvent> UsageEvents => Set<UsageEvent>();
    public DbSet<SystemSetting> SystemSettings => Set<SystemSetting>();
    public DbSet<AppVersion> AppVersions => Set<AppVersion>();
    public DbSet<Announcement> Announcements => Set<Announcement>();
    public DbSet<ContactMessage> ContactMessages => Set<ContactMessage>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    public IQueryable<T> SqlQuery<T>(FormattableString sql) => Database.SqlQuery<T>(sql);

    protected override void OnModelCreating(ModelBuilder b)
    {
        // Schema is owned by Supabase migrations (supabase/migrations). EF only maps it.
        b.HasDefaultSchema("app");

        b.Entity<Profile>(e =>
        {
            e.ToTable("profiles");
            e.Property(x => x.Id).ValueGeneratedNever();
            Timestamps(e);
            e.HasOne(x => x.Settings).WithOne().HasForeignKey<UserSettings>(s => s.UserId);
            e.HasMany(x => x.UserRoles).WithOne(x => x.User).HasForeignKey(x => x.UserId);
        });

        b.Entity<Role>(e =>
        {
            e.ToTable("roles");
            Created(e);
            e.HasMany(x => x.Permissions).WithOne().HasForeignKey(x => x.RoleId);
            e.HasMany(x => x.UserRoles).WithOne(x => x.Role).HasForeignKey(x => x.RoleId);
        });
        b.Entity<RolePermission>().ToTable("role_permissions");
        b.Entity<UserRole>(e => { e.ToTable("user_roles"); Created(e); });

        b.Entity<UserSettings>(e => { e.ToTable("user_settings"); Timestamps(e); });
        b.Entity<LocationCategory>(e => { e.ToTable("location_categories"); Timestamps(e); });
        b.Entity<FavoriteLocation>(e =>
        {
            e.ToTable("favorite_locations");
            Timestamps(e);
            e.HasOne(x => x.Category).WithMany().HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.ClientSetNull);
        });
        b.Entity<LocationHistoryEntry>(e => { e.ToTable("location_history"); Created(e); });

        b.Entity<SavedRoute>(e =>
        {
            e.ToTable("saved_routes");
            Timestamps(e);
            e.Property(x => x.Points)
                .HasColumnType("jsonb")
                .HasConversion(
                    v => JsonSerializer.Serialize(v, JsonOptions),
                    v => JsonSerializer.Deserialize<List<RoutePoint>>(v, JsonOptions) ?? new List<RoutePoint>(),
                    new ValueComparer<List<RoutePoint>>(
                        (a, c) => a!.SequenceEqual(c!),
                        v => v.Aggregate(0, (h, p) => HashCode.Combine(h, p.GetHashCode())),
                        v => v.ToList()));
        });

        b.Entity<UsageEvent>(e => { e.ToTable("usage_events"); Created(e); });
        b.Entity<SystemSetting>(e =>
        {
            e.ToTable("system_settings");
            e.Property(x => x.Value).HasColumnType("jsonb");
            Updated(e);
        });
        b.Entity<AppVersion>(e => { e.ToTable("app_versions"); Timestamps(e); });
        b.Entity<Announcement>(e => { e.ToTable("announcements"); Timestamps(e); });
        b.Entity<ContactMessage>(e => { e.ToTable("contact_messages"); Timestamps(e); });
        b.Entity<AuditLog>(e =>
        {
            e.ToTable("audit_logs");
            e.Property(x => x.Metadata).HasColumnType("jsonb");
            Created(e);
        });
    }

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    // created_at / updated_at are owned by Postgres (defaults + triggers). EF never writes them, which
    // also matters for RLS: `authenticated` has no UPDATE grant on these columns.
    private static void Created<T>(EntityTypeBuilder<T> e) where T : class =>
        e.Property<DateTimeOffset>("CreatedAt").HasDefaultValueSql("now()").ValueGeneratedOnAdd()
            .Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);

    private static void Updated<T>(EntityTypeBuilder<T> e) where T : class
    {
        var p = e.Property<DateTimeOffset>("UpdatedAt").HasDefaultValueSql("now()").ValueGeneratedOnAddOrUpdate().Metadata;
        p.SetBeforeSaveBehavior(PropertySaveBehavior.Ignore);
        p.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);
    }

    private static void Timestamps<T>(EntityTypeBuilder<T> e) where T : class
    {
        Created(e);
        Updated(e);
    }
}
