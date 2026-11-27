using FluentValidation;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;
using Npgsql;

namespace MockGps.API.Infrastructure;

/// <summary>Maps exceptions to RFC 9457 problem responses with a stable <c>code</c> and no internals.</summary>
public sealed class GlobalExceptionHandler(IProblemDetailsService problems, ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext http, Exception exception, CancellationToken ct)
    {
        if (exception is OperationCanceledException && http.RequestAborted.IsCancellationRequested)
        {
            http.Response.StatusCode = 499;
            return true;
        }

        var (status, title, code, detail) = Map(exception);
        var problem = new ProblemDetails { Status = status, Title = title, Detail = detail, Type = $"https://httpstatuses.io/{status}" };
        problem.Extensions["code"] = code;

        if (exception is ValidationException ve)
        {
            problem.Extensions["errors"] = ve.Errors
                .GroupBy(e => ToCamel(e.PropertyName))
                .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).Distinct().ToArray());
        }

        if (status >= 500) logger.LogError(exception, "Unhandled error ({Code})", code);
        else logger.LogInformation("Request failed with {Status} {Code}: {Message}", status, code, exception.Message);

        http.Response.StatusCode = status;
        return await problems.TryWriteAsync(new ProblemDetailsContext { HttpContext = http, ProblemDetails = problem, Exception = exception });
    }

    private static (int Status, string Title, string Code, string? Detail) Map(Exception e) => e switch
    {
        ValidationException => (400, "Validation failed", "validation_error", "One or more fields are invalid."),
        BadHttpRequestException b => (b.StatusCode, "Bad request", "bad_request", "The request could not be read."),
        NotFoundException x => (404, "Not found", x.Code, x.Message),
        ConflictException x => (409, "Conflict", x.Code, x.Message),
        BusinessRuleException x => (422, "Request cannot be completed", x.Code, x.Message),
        ForbiddenException x => (403, "Forbidden", x.Code, x.Message),
        ServiceUnavailableException x => (503, "Service unavailable", x.Code, x.Message),
        ExternalServiceException x => (503, "Service unavailable", x.Code, x.Message),
        UnauthorizedAccessException => (401, "Unauthorized", "unauthorized", "Sign in to continue."),
        HttpRequestException => (503, "Service unavailable", "external_service_error", "A required service is not reachable right now."),
        DbUpdateException { InnerException: PostgresException pg } => MapPostgres(pg),
        PostgresException pg => MapPostgres(pg),
        _ => (500, "Unexpected error", "internal_error", "Something went wrong. Please try again."),
    };

    private static (int, string, string, string?) MapPostgres(PostgresException pg) => pg.SqlState switch
    {
        PostgresErrorCodes.UniqueViolation => (409, "Conflict", "duplicate", "A record with the same value already exists."),
        PostgresErrorCodes.ForeignKeyViolation => (422, "Request cannot be completed", "invalid_reference", "A referenced record does not exist."),
        PostgresErrorCodes.CheckViolation => (422, "Request cannot be completed", "invalid_value", "A value is outside the allowed range."),
        // Raised by RLS / grants. Should never happen through normal API use; logged as an error.
        PostgresErrorCodes.InsufficientPrivilege => (403, "Forbidden", "forbidden", "You do not have access to this resource."),
        _ => (500, "Unexpected error", "internal_error", "Something went wrong. Please try again."),
    };

    private static string ToCamel(string name) =>
        string.Join('.', name.Split('.').Select(p => p.Length == 0 ? p : char.ToLowerInvariant(p[0]) + p[1..]));
}
