using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using MockGps.Application.Common;

namespace MockGps.Infrastructure.Persistence;

/// <summary>
/// Executes user-scoped work as the Postgres <c>authenticated</c> role with the caller's JWT claims,
/// inside a transaction (<c>set_config(..., is_local =&gt; true)</c>). RLS policies using
/// <c>auth.uid()</c> therefore apply to every statement, independent of the API's own filters.
/// </summary>
public sealed class UserDataScope(AppDbContext db, ICurrentUser currentUser) : IUserDataScope
{
    public async Task<T> RunAsync<T>(Func<IAppDbContext, Task<T>> work, CancellationToken ct)
    {
        if (db.Database.CurrentTransaction is not null)
        {
            // Nested call: already inside a user scope.
            return await work(db);
        }

        var claims = JsonSerializer.Serialize(new
        {
            sub = currentUser.UserId.ToString(),
            role = "authenticated",
            email = currentUser.Email,
        });

        await using var tx = await db.Database.BeginTransactionAsync(ct);
        try
        {
            await db.Database.ExecuteSqlInterpolatedAsync(
                $"select set_config('request.jwt.claims', {claims}, true), set_config('role', 'authenticated', true)", ct);
            var result = await work(db);
            await tx.CommitAsync(ct);
            return result;
        }
        catch
        {
            // Tracked entities from a failed transaction must not leak into later work in this request.
            db.ChangeTracker.Clear();
            throw;
        }
    }

    public Task RunAsync(Func<IAppDbContext, Task> work, CancellationToken ct) =>
        RunAsync<bool>(async ctx => { await work(ctx); return true; }, ct);
}
