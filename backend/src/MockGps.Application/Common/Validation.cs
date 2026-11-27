using FluentValidation;

namespace MockGps.Application.Common;

public static class ValidationExtensions
{
    public static IRuleBuilderOptions<T, double> ValidLatitude<T>(this IRuleBuilder<T, double> rule) =>
        rule.InclusiveBetween(-90, 90).WithMessage("Latitude must be between -90 and 90.");

    public static IRuleBuilderOptions<T, double> ValidLongitude<T>(this IRuleBuilder<T, double> rule) =>
        rule.InclusiveBetween(-180, 180).WithMessage("Longitude must be between -180 and 180.");

    public static IRuleBuilderOptions<T, string?> OneOf<T>(this IRuleBuilder<T, string?> rule, IReadOnlyList<string> values) =>
        rule.Must(v => v is null || values.Contains(v))
            .WithMessage($"Must be one of: {string.Join(", ", values)}.");

    public static IRuleBuilderOptions<T, string> OneOfRequired<T>(this IRuleBuilder<T, string> rule, IReadOnlyList<string> values) =>
        rule.NotEmpty().Must(v => values.Contains(v))
            .WithMessage($"Must be one of: {string.Join(", ", values)}.");
}

/// <summary>Validates requests using the registered FluentValidation validators.</summary>
public interface IRequestValidator
{
    Task ValidateAsync<T>(T request, CancellationToken ct);
}

public sealed class RequestValidator(IServiceProvider services) : IRequestValidator
{
    public async Task ValidateAsync<T>(T request, CancellationToken ct)
    {
        if (services.GetService(typeof(IValidator<T>)) is IValidator<T> validator)
        {
            await validator.ValidateAndThrowAsync(request, ct);
        }
    }
}

public static class Text
{
    /// <summary>Trims and turns empty strings into null.</summary>
    public static string? Clean(string? value)
    {
        if (value is null) return null;
        var trimmed = value.Trim();
        return trimmed.Length == 0 ? null : trimmed;
    }

    /// <summary>Escapes LIKE wildcards so user input is matched literally.</summary>
    public static string LikePattern(string term) =>
        "%" + term.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%";
}
