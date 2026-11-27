namespace MockGps.Application.Common;

/// <summary>Base type for errors that map to a specific HTTP status and a user-safe message.</summary>
public abstract class AppException(string message, string code) : Exception(message)
{
    /// <summary>Stable machine-readable code clients can translate.</summary>
    public string Code { get; } = code;
}

public sealed class NotFoundException(string entity)
    : AppException($"{entity} was not found.", "not_found");

public sealed class ConflictException(string message, string code = "conflict")
    : AppException(message, code);

public sealed class BusinessRuleException(string message, string code)
    : AppException(message, code);

public sealed class ForbiddenException(string message, string code = "forbidden")
    : AppException(message, code);

public sealed class ServiceUnavailableException(string message, string code)
    : AppException(message, code);

public sealed class ExternalServiceException(string service, string message)
    : AppException($"{service} is not available right now. {message}".Trim(), "external_service_error");
