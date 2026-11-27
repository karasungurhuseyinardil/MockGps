using System.Linq.Expressions;
using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MockGps.Application.Admin;
using MockGps.Application.Common;
using MockGps.Application.Me;
using MockGps.Domain;
using MockGps.Domain.Entities;
using MockGps.Infrastructure.Geocoding;
using Shouldly;

namespace MockGps.UnitTests;

public class CoreLogicTests
{
    [Fact]
    public void Haversine_istanbul_to_ankara_is_about_350km()
    {
        var d = Geo.DistanceMeters(41.0082, 28.9784, 39.9334, 32.8597);
        d.ShouldBeInRange(345_000, 355_000);
    }

    [Fact]
    public void Path_length_sums_segments()
    {
        var points = new List<RoutePoint> { new(0, 0), new(0, 1), new(0, 2) };
        Geo.PathLengthMeters(points).ShouldBe(2 * Geo.DistanceMeters(0, 0, 0, 1), 0.001);
    }

    [Theory]
    [InlineData("name:asc", "name", false)]
    [InlineData("CREATED_AT:desc", "created_at", true)]
    [InlineData(null, "created_at", true)]
    [InlineData("  ", "created_at", true)]
    public void Sort_spec_parses(string? input, string field, bool desc)
    {
        SortSpec.Parse(input, "created_at:desc").ShouldBe((field, desc));
    }

    [Fact]
    public void Unknown_sort_field_falls_back_to_default()
    {
        var data = new[] { new FavoriteLocation { Name = "b", CreatedAt = DateTimeOffset.UnixEpoch }, new FavoriteLocation { Name = "a", CreatedAt = DateTimeOffset.UtcNow } }.AsQueryable();
        var allowed = new Dictionary<string, Expression<Func<FavoriteLocation, object?>>> { ["name"] = f => f.Name, ["created_at"] = f => f.CreatedAt };
        data.ApplySort("password:asc", allowed, "created_at:desc").First().Name.ShouldBe("a");
        data.ApplySort("name:asc", allowed, "created_at:desc").First().Name.ShouldBe("a");
    }

    [Fact]
    public void Like_pattern_escapes_wildcards()
    {
        Text.LikePattern("50%_off\\").ShouldBe("%50\\%\\_off\\\\%");
    }

    [Fact]
    public void Image_sniffer_uses_magic_bytes()
    {
        ImageSniffer.Detect([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]).ShouldBe("png");
        ImageSniffer.Detect([0xFF, 0xD8, 0xFF, 0xE0]).ShouldBe("jpg");
        ImageSniffer.Detect(Encoding.ASCII.GetBytes("RIFF....WEBPVP8 ")).ShouldBe("webp");
        ImageSniffer.Detect(Encoding.ASCII.GetBytes("<svg onload=alert(1)>")).ShouldBeNull();
    }

    [Theory]
    [InlineData("maintenance_mode", "true", true)]
    [InlineData("maintenance_mode", "\"yes\"", false)]
    [InlineData("history_max_cloud_items", "500", true)]
    [InlineData("history_max_cloud_items", "5", false)]
    [InlineData("support_email", "\"help@example.com\"", true)]
    [InlineData("support_email", "\"nope\"", false)]
    [InlineData("unknown_key", "1", false)]
    public void System_setting_values_are_typed(string key, string json, bool valid)
    {
        using var doc = JsonDocument.Parse(json);
        (SystemSettingsAdminService.ValidateValue(key, doc.RootElement) is null).ShouldBe(valid);
    }

    [Fact]
    public async Task Photon_response_is_parsed()
    {
        const string body = """
        {"features":[{"geometry":{"coordinates":[13.3888,52.5170]},
          "properties":{"name":"Berlin","city":"Berlin","country":"Germany","osm_value":"city"}}]}
        """;
        var http = new HttpClient(new StubHandler(body));
        var provider = new PhotonGeocodingProvider(http, Options.Create(new GeocodingOptions()), NullLogger<PhotonGeocodingProvider>.Instance);

        var results = await provider.SearchAsync("berlin", "en", 5, CancellationToken.None);

        results.Count.ShouldBe(1);
        results[0].Latitude.ShouldBe(52.5170);
        results[0].Longitude.ShouldBe(13.3888);
        results[0].Label.ShouldBe("Berlin, Germany");
        results[0].Type.ShouldBe("city");
    }

    [Fact]
    public async Task Geocoding_http_failure_becomes_external_service_error()
    {
        var http = new HttpClient(new StubHandler("oops", HttpStatusCode.BadGateway));
        var provider = new PhotonGeocodingProvider(http, Options.Create(new GeocodingOptions()), NullLogger<PhotonGeocodingProvider>.Instance);
        await Should.ThrowAsync<ExternalServiceException>(() => provider.SearchAsync("x", "en", 5, CancellationToken.None));
    }

    private sealed class StubHandler(string body, HttpStatusCode status = HttpStatusCode.OK) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) =>
            Task.FromResult(new HttpResponseMessage(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") });
    }
}
