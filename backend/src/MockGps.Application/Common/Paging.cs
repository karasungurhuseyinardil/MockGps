using System.Linq.Expressions;
using FluentValidation;
using Microsoft.EntityFrameworkCore;

namespace MockGps.Application.Common;

public record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount)
{
    public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}

public class PageQuery
{
    public const int MaxPageSize = 100;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    /// <summary>Format: <c>field:asc</c> or <c>field:desc</c>.</summary>
    public string? Sort { get; set; }
}

public class PageQueryValidator<T> : AbstractValidator<T> where T : PageQuery
{
    public PageQueryValidator()
    {
        RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
        RuleFor(x => x.PageSize).InclusiveBetween(1, PageQuery.MaxPageSize);
        RuleFor(x => x.Sort).MaximumLength(64);
    }
}

public sealed class PlainPageQueryValidator : PageQueryValidator<PageQuery>;

public static class QueryableExtensions
{
    public static async Task<PagedResult<TOut>> ToPagedAsync<TIn, TOut>(
        this IQueryable<TIn> query, PageQuery page, Expression<Func<TIn, TOut>> selector, CancellationToken ct)
    {
        var total = await query.CountAsync(ct);
        var items = await query
            .Skip((page.Page - 1) * page.PageSize)
            .Take(page.PageSize)
            .Select(selector)
            .ToListAsync(ct);
        return new PagedResult<TOut>(items, page.Page, page.PageSize, total);
    }

    /// <summary>
    /// Applies a whitelisted sort. Unknown fields fall back to the default sort, so clients cannot
    /// sort on arbitrary columns.
    /// </summary>
    public static IQueryable<T> ApplySort<T>(
        this IQueryable<T> query,
        string? sort,
        IReadOnlyDictionary<string, Expression<Func<T, object?>>> allowed,
        string defaultSort)
    {
        var (field, descending) = SortSpec.Parse(sort, defaultSort);
        if (!allowed.TryGetValue(field, out var key))
        {
            (field, descending) = SortSpec.Parse(defaultSort, defaultSort);
            key = allowed[field];
        }
        return descending ? query.OrderByDescending(key) : query.OrderBy(key);
    }
}

public static class SortSpec
{
    public static (string Field, bool Descending) Parse(string? sort, string defaultSort)
    {
        var value = string.IsNullOrWhiteSpace(sort) ? defaultSort : sort.Trim();
        var parts = value.Split(':', 2, StringSplitOptions.TrimEntries);
        var field = parts[0].ToLowerInvariant();
        var descending = parts.Length > 1 && parts[1].Equals("desc", StringComparison.OrdinalIgnoreCase);
        return (field, descending);
    }
}
