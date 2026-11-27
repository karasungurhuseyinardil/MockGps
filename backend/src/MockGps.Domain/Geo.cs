using MockGps.Domain.Entities;

namespace MockGps.Domain;

public static class Geo
{
    private const double EarthRadiusMeters = 6_371_008.8;

    /// <summary>Great-circle distance in meters (haversine).</summary>
    public static double DistanceMeters(double lat1, double lng1, double lat2, double lng2)
    {
        var dLat = ToRad(lat2 - lat1);
        var dLng = ToRad(lng2 - lng1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2)) * Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
        return 2 * EarthRadiusMeters * Math.Asin(Math.Min(1, Math.Sqrt(a)));
    }

    public static double PathLengthMeters(IReadOnlyList<RoutePoint> points)
    {
        double total = 0;
        for (var i = 1; i < points.Count; i++)
        {
            total += DistanceMeters(points[i - 1].Lat, points[i - 1].Lng, points[i].Lat, points[i].Lng);
        }
        return total;
    }

    private static double ToRad(double degrees) => degrees * Math.PI / 180d;
}
