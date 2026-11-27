using FluentValidation.TestHelper;
using MockGps.Application.Locations;
using MockGps.Application.Me;
using MockGps.Application.Public;
using MockGps.Application.Usage;
using MockGps.Domain.Entities;
using Shouldly;

namespace MockGps.UnitTests;

public class ValidationTests
{
    [Theory]
    [InlineData(91, 0)]
    [InlineData(-91, 0)]
    [InlineData(0, 181)]
    [InlineData(0, -180.0001)]
    public void Favorite_rejects_out_of_range_coordinates(double lat, double lng)
    {
        var result = new FavoriteRequestValidator().TestValidate(new FavoriteRequest("Home", null, lat, lng, null, null));
        result.IsValid.ShouldBeFalse();
    }

    [Fact]
    public void Favorite_accepts_valid_request()
    {
        new FavoriteRequestValidator().TestValidate(new FavoriteRequest("Berlin", "desc", 52.52, 13.405, "Mitte", null))
            .ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Favorite_requires_name()
    {
        new FavoriteRequestValidator().TestValidate(new FavoriteRequest("", null, 1, 1, null, null))
            .ShouldHaveValidationErrorFor(x => x.Name);
    }

    [Fact]
    public void Route_needs_at_least_two_points()
    {
        var result = new RouteRequestValidator().TestValidate(new RouteRequest("r", [new RoutePoint(1, 1)], 30, false));
        result.ShouldHaveValidationErrorFor(x => x.Points);
    }

    [Fact]
    public void Route_rejects_invalid_point_and_speed()
    {
        var result = new RouteRequestValidator().TestValidate(
            new RouteRequest("r", [new RoutePoint(1, 1), new RoutePoint(95, 1)], 0, false));
        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName.Contains("Lat"));
        result.ShouldHaveValidationErrorFor(x => x.SpeedKmh);
    }

    [Fact]
    public void Settings_reject_unknown_theme_and_interval()
    {
        var result = new SettingsValidator().TestValidate(new SettingsDto("neon", "en", "standard", true, false, true, 5, 50));
        result.ShouldHaveValidationErrorFor(x => x.Theme);
        result.ShouldHaveValidationErrorFor(x => x.UpdateIntervalMs);
    }

    [Fact]
    public void History_batch_rejects_future_dates_and_too_many_items()
    {
        var clock = TimeProvider.System;
        var validator = new HistoryBatchValidator(clock);
        var future = new HistoryItemRequest(Guid.NewGuid(), 1, 1, null, "map", clock.GetUtcNow().AddDays(1));
        validator.TestValidate(new HistoryBatchRequest([future])).IsValid.ShouldBeFalse();

        var many = Enumerable.Range(0, HistoryBatchValidator.MaxItems + 1)
            .Select(_ => new HistoryItemRequest(Guid.NewGuid(), 1, 1, null, null, null)).ToList();
        validator.TestValidate(new HistoryBatchRequest(many)).ShouldHaveValidationErrorFor(x => x.Items);
    }

    [Fact]
    public void Usage_events_only_accept_known_types()
    {
        var v = new UsageEventsValidator();
        v.TestValidate(new UsageEventsRequest("android", "1.0.0", ["simulation_started"])).ShouldNotHaveAnyValidationErrors();
        v.TestValidate(new UsageEventsRequest("android", "1.0.0", ["drop_table"])).IsValid.ShouldBeFalse();
        v.TestValidate(new UsageEventsRequest("windows", null, ["simulation_started"])).ShouldHaveValidationErrorFor(x => x.Platform);
    }

    [Fact]
    public void Contact_requires_valid_email_and_message()
    {
        var result = new ContactRequestValidator().TestValidate(new ContactRequest("A", "not-an-email", "Hi", "short", null));
        result.ShouldHaveValidationErrorFor(x => x.Email);
        result.ShouldHaveValidationErrorFor(x => x.Message);
    }
}
