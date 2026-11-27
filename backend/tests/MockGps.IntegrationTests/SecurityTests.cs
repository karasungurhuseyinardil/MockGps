using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Shouldly;

namespace MockGps.IntegrationTests;

[Collection(ApiCollection.Name)]
public class SecurityTests(ApiFixture api)
{
    [Fact]
    public async Task Personal_endpoints_require_a_token()
    {
        var anonymous = api.CreateClient();
        (await anonymous.GetAsync("/api/v1/me")).StatusCode.ShouldBe(HttpStatusCode.Unauthorized);
        (await anonymous.GetAsync("/api/v1/favorites")).StatusCode.ShouldBe(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Forged_token_is_rejected()
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new("Bearer",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJhdWQiOiJhdXRoZW50aWNhdGVkIn0.invalidsignature");
        (await client.GetAsync("/api/v1/me")).StatusCode.ShouldBe(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task New_user_gets_profile_settings_and_default_categories()
    {
        var user = await api.CreateUserAsync("new");
        var me = await user.Http.GetFromJsonAsync<JsonElement>("/api/v1/me");
        me.GetProperty("email").GetString().ShouldBe(user.Email);
        me.GetProperty("roles").EnumerateArray().Select(r => r.GetString()).ShouldBe(["user"]);
        me.GetProperty("settings").GetProperty("historyCloudSync").GetBoolean().ShouldBeFalse();

        var categories = await user.Http.GetFromJsonAsync<JsonElement>("/api/v1/categories");
        categories.GetArrayLength().ShouldBe(5);
    }

    [Fact]
    public async Task Users_cannot_access_each_others_favorites()
    {
        var alice = await api.CreateUserAsync("alice");
        var bob = await api.CreateUserAsync("bob");

        var created = await alice.Http.PostAsJsonAsync("/api/v1/favorites", new { name = "Berlin", latitude = 52.52, longitude = 13.405 });
        created.StatusCode.ShouldBe(HttpStatusCode.Created);
        var id = (await created.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString();

        (await bob.Http.GetAsync($"/api/v1/favorites/{id}")).StatusCode.ShouldBe(HttpStatusCode.NotFound);
        (await bob.Http.PutAsJsonAsync($"/api/v1/favorites/{id}", new { name = "x", latitude = 1, longitude = 1 }))
            .StatusCode.ShouldBe(HttpStatusCode.NotFound);
        (await bob.Http.DeleteAsync($"/api/v1/favorites/{id}")).StatusCode.ShouldBe(HttpStatusCode.NotFound);

        var bobList = await bob.Http.GetFromJsonAsync<JsonElement>("/api/v1/favorites");
        bobList.GetProperty("totalCount").GetInt32().ShouldBe(0);
        (await alice.Http.GetAsync($"/api/v1/favorites/{id}")).StatusCode.ShouldBe(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Favorite_cannot_reference_another_users_category()
    {
        var alice = await api.CreateUserAsync("alice");
        var bob = await api.CreateUserAsync("bob");
        var bobCategories = await bob.Http.GetFromJsonAsync<JsonElement>("/api/v1/categories");
        var bobCategory = bobCategories[0].GetProperty("id").GetString();

        var response = await alice.Http.PostAsJsonAsync("/api/v1/favorites",
            new { name = "x", latitude = 1, longitude = 1, categoryId = bobCategory });
        response.StatusCode.ShouldBe(HttpStatusCode.UnprocessableEntity);
    }

    [Fact]
    public async Task Validation_errors_are_problem_details_with_fields()
    {
        var user = await api.CreateUserAsync("val");
        var response = await user.Http.PostAsJsonAsync("/api/v1/favorites", new { name = "", latitude = 120, longitude = 0 });
        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
        var problem = await response.Content.ReadFromJsonAsync<JsonElement>();
        problem.GetProperty("code").GetString().ShouldBe("validation_error");
        problem.GetProperty("errors").TryGetProperty("latitude", out _).ShouldBeTrue();
    }

    [Fact]
    public async Task Admin_endpoints_require_permission()
    {
        var user = await api.CreateUserAsync("plain");
        (await user.Http.GetAsync("/api/v1/admin/dashboard/summary")).StatusCode.ShouldBe(HttpStatusCode.Forbidden);
        (await user.Http.GetAsync("/api/v1/admin/users")).StatusCode.ShouldBe(HttpStatusCode.Forbidden);

        await api.GrantRoleAsync(user.Id, "admin");
        (await user.Http.GetAsync("/api/v1/admin/dashboard/summary")).StatusCode.ShouldBe(HttpStatusCode.OK);
        // admin role does not include roles.manage
        (await user.Http.GetAsync("/api/v1/admin/roles")).StatusCode.ShouldBe(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Deactivated_user_is_blocked_and_audited()
    {
        var admin = await api.CreateUserAsync("admin");
        await api.GrantRoleAsync(admin.Id, "admin");
        var target = await api.CreateUserAsync("target");

        var response = await admin.Http.PatchAsJsonAsync($"/api/v1/admin/users/{target.Id}/status", new { isActive = false, reason = "test" });
        response.StatusCode.ShouldBe(HttpStatusCode.OK);

        var blocked = await target.Http.GetAsync("/api/v1/me");
        blocked.StatusCode.ShouldBe(HttpStatusCode.Forbidden);
        (await blocked.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString().ShouldBe("account_disabled");

        var logs = await admin.Http.GetFromJsonAsync<JsonElement>($"/api/v1/admin/audit-logs?action=user.deactivated");
        logs.GetProperty("items").EnumerateArray().ShouldContain(l => l.GetProperty("entityId").GetString() == target.Id.ToString());

        (await admin.Http.PatchAsJsonAsync($"/api/v1/admin/users/{admin.Id}/status", new { isActive = false }))
            .StatusCode.ShouldBe(HttpStatusCode.UnprocessableEntity);
    }

    [Fact]
    public async Task Account_deletion_removes_personal_data()
    {
        var user = await api.CreateUserAsync("delete");
        await user.Http.PostAsJsonAsync("/api/v1/favorites", new { name = "Home", latitude = 1, longitude = 1 });

        (await user.Http.DeleteAsync("/api/v1/me")).StatusCode.ShouldBe(HttpStatusCode.NoContent);
        (await user.Http.GetAsync("/api/v1/me")).StatusCode.ShouldBe(HttpStatusCode.Unauthorized);

        await using var conn = new Npgsql.NpgsqlConnection(ApiFixture.Database);
        await conn.OpenAsync();
        await using var cmd = new Npgsql.NpgsqlCommand("select count(*) from app.favorite_locations where user_id = @u", conn);
        cmd.Parameters.AddWithValue("u", user.Id);
        ((long)(await cmd.ExecuteScalarAsync())!).ShouldBe(0);
    }

    [Fact]
    public async Task Cloud_history_requires_opt_in()
    {
        var user = await api.CreateUserAsync("hist");
        var batch = new { items = new[] { new { clientId = Guid.NewGuid(), latitude = 1.0, longitude = 2.0 } } };
        var blocked = await user.Http.PostAsJsonAsync("/api/v1/history/batch", batch);
        blocked.StatusCode.ShouldBe(HttpStatusCode.UnprocessableEntity);

        var settings = await user.Http.GetFromJsonAsync<Dictionary<string, JsonElement>>("/api/v1/me/settings");
        var body = settings!.ToDictionary(k => k.Key, k => (object)k.Value);
        body["historyCloudSync"] = true;
        (await user.Http.PutAsJsonAsync("/api/v1/me/settings", body)).StatusCode.ShouldBe(HttpStatusCode.OK);

        (await user.Http.PostAsJsonAsync("/api/v1/history/batch", batch)).StatusCode.ShouldBe(HttpStatusCode.OK);
        var again = await (await user.Http.PostAsJsonAsync("/api/v1/history/batch", batch)).Content.ReadFromJsonAsync<JsonElement>();
        again.GetProperty("inserted").GetInt32().ShouldBe(0);
    }
}
