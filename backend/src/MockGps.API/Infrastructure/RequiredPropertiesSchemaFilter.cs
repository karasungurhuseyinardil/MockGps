using System.Reflection;
using System.Text.Json;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace MockGps.API.Infrastructure;

/// <summary>
/// Marks every property that cannot be null in C# as <c>required</c> in the OpenAPI document, so
/// generated clients (web/packages/api-client) get exact types instead of "everything optional".
/// </summary>
public sealed class RequiredPropertiesSchemaFilter : ISchemaFilter
{
    private static readonly NullabilityInfoContext Nullability = new();

    public void Apply(IOpenApiSchema schema, SchemaFilterContext context)
    {
        if (schema is not OpenApiSchema concrete || concrete.Properties is null || context.Type.IsPrimitive || context.Type == typeof(string)) return;

        foreach (var property in context.Type.GetProperties(BindingFlags.Public | BindingFlags.Instance))
        {
            var name = JsonNamingPolicy.CamelCase.ConvertName(property.Name);
            if (!concrete.Properties.ContainsKey(name)) continue;

            var type = property.PropertyType;
            var nullable = type.IsValueType
                ? Nullable.GetUnderlyingType(type) is not null
                : Nullability.Create(property).ReadState != NullabilityState.NotNull;

            if (!nullable)
            {
                concrete.Required ??= new HashSet<string>();
                concrete.Required.Add(name);
            }
        }
    }
}
