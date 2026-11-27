using System.Text.Json.Serialization;
using Asp.Versioning;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MockGps.API.Auth;
using MockGps.API.Infrastructure;
using MockGps.Application;
using MockGps.Application.Common;
using MockGps.Infrastructure;
using MockGps.Infrastructure.Persistence;
using Serilog;

Log.Logger = new LoggerConfiguration().WriteTo.Console().CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Host.UseSerilog((context, services, config) => config
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext());

    builder.Services.AddApplication();
    builder.Services.AddInfrastructure(builder.Configuration);

    builder.Services.AddHttpContextAccessor();
    builder.Services.AddScoped<ICurrentUser, CurrentUser>();

    builder.Services.AddControllers()
        .AddJsonOptions(o => o.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.Never);
    builder.Services.Configure<ApiBehaviorOptions>(o => o.SuppressModelStateInvalidFilter = false);
    builder.Services.AddProblemDetails(o => o.CustomizeProblemDetails = ctx =>
        ctx.ProblemDetails.Extensions["traceId"] = ctx.HttpContext.TraceIdentifier);
    builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

    builder.Services.AddApiVersioning(o =>
        {
            o.DefaultApiVersion = new ApiVersion(1);
            o.ReportApiVersions = true;
            o.ApiVersionReader = new UrlSegmentApiVersionReader();
        })
        .AddMvc()
        .AddApiExplorer(o =>
        {
            o.GroupNameFormat = "'v'V";
            o.SubstituteApiVersionInUrl = true;
        });

    // Authentication: Supabase Auth JWTs (JWKS + optional legacy HS256 secret).
    builder.Services.AddHttpClient(nameof(SupabaseSigningKeys), c => c.Timeout = TimeSpan.FromSeconds(10));
    builder.Services.AddSingleton<SupabaseSigningKeys>();
    builder.Services.ConfigureOptions<ConfigureJwtBearer>();
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();
    builder.Services.AddSingleton<IAuthorizationPolicyProvider, PermissionPolicyProvider>();
    builder.Services.AddScoped<IAuthorizationHandler, PermissionHandler>();
    builder.Services.AddAuthorization();

    builder.Services.AddApiRateLimiting();

    var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
        .WithOrigins(origins)
        .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
        .WithHeaders("Authorization", "Content-Type", "Accept-Language")
        .WithExposedHeaders("Content-Disposition", "Retry-After")
        .SetPreflightMaxAge(TimeSpan.FromHours(1))));

    builder.Services.AddHealthChecks().AddDbContextCheck<AppDbContext>("database");

    builder.Services.Configure<ForwardedHeadersOptions>(o =>
    {
        o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
        // Only trust X-Forwarded-* from configured proxies (default: loopback only). Empty lists would
        // mean "trust everyone", letting clients spoof their IP in rate limits and audit logs.
        var proxies = builder.Configuration.GetSection("ForwardedHeaders:KnownProxies").Get<string[]>() ?? [];
        foreach (var proxy in proxies) o.KnownProxies.Add(System.Net.IPAddress.Parse(proxy));
    });

    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen(c =>
    {
        c.SwaggerDoc("v1", new OpenApiInfo
        {
            Title = "Mock GPS API",
            Version = "v1",
            Description = "Location Simulation Platform API. Authenticate with a Supabase Auth access token.",
        });
        c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "Supabase Auth access token",
        });
        c.AddSecurityRequirement(doc => new OpenApiSecurityRequirement { [new OpenApiSecuritySchemeReference("Bearer", doc)] = [] });
        c.CustomSchemaIds(t => t.FullName!.Replace("MockGps.Application.", string.Empty).Replace('+', '.'));
        c.SupportNonNullableReferenceTypes();
        c.SchemaFilter<RequiredPropertiesSchemaFilter>();
        var xml = Path.Combine(AppContext.BaseDirectory, "MockGps.API.xml");
        if (File.Exists(xml)) c.IncludeXmlComments(xml);
    });

    var app = builder.Build();

    app.UseForwardedHeaders();
    // Request logging wraps the exception handler so it logs the final (mapped) status code.
    app.UseSerilogRequestLogging(o => o.GetLevel = (http, _, ex) =>
        ex is not null || http.Response.StatusCode >= 500 ? Serilog.Events.LogEventLevel.Error
        : http.Request.Path.StartsWithSegments("/health") ? Serilog.Events.LogEventLevel.Verbose
        : Serilog.Events.LogEventLevel.Information);
    app.UseExceptionHandler();
    app.UseStatusCodePages();
    app.Use(async (http, next) =>
    {
        var h = http.Response.Headers;
        h.XContentTypeOptions = "nosniff";
        h.XFrameOptions = "DENY";
        h["Referrer-Policy"] = "no-referrer";
        h["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()";
        if (!http.Request.Path.StartsWithSegments("/swagger"))
            h.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
        await next();
    });

    if (app.Configuration.GetValue("Swagger:Enabled", app.Environment.IsDevelopment()))
    {
        app.UseSwagger();
        app.UseSwaggerUI(o => o.SwaggerEndpoint("/swagger/v1/swagger.json", "Mock GPS API v1"));
    }

    if (!app.Environment.IsDevelopment()) app.UseHsts();

    app.UseCors();
    app.UseAuthentication();
    app.UseMiddleware<UserAccessMiddleware>();
    app.UseRateLimiter();
    app.UseAuthorization();

    app.MapControllers();
    app.MapGet("/health", () => Results.Ok(new { status = "ok" })).AllowAnonymous().DisableRateLimiting();
    app.MapHealthChecks("/health/ready").AllowAnonymous().DisableRateLimiting();

    // Warm up signing keys so the first authenticated request does not wait.
    _ = app.Services.GetRequiredService<SupabaseSigningKeys>().RefreshAsync();

    app.Run();
}
catch (Exception ex) when (ex is not HostAbortedException)
{
    Log.Fatal(ex, "API terminated unexpectedly");
    throw;
}
finally
{
    Log.CloseAndFlush();
}

public partial class Program;
