package com.mockgps.mockgps.mock

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.asin
import kotlin.math.min

data class GeoPoint(val lat: Double, val lng: Double)

data class RouteFix(
    val lat: Double,
    val lng: Double,
    /** Degrees clockwise from north, 0..360. */
    val bearing: Float,
    /** Meters per second. */
    val speed: Float,
    /** 0..1 along the route (per lap when looping). */
    val progress: Double,
    val finished: Boolean,
)

/**
 * Moves along a polyline at constant speed. Pure logic (no Android APIs) so it is unit tested.
 * When [loop] is true the path is closed (last point connects back to the first) and repeats.
 */
class RoutePlayer(points: List<GeoPoint>, speedKmh: Double, private val loop: Boolean) {
    private val path: List<GeoPoint>
    private val cumulative: DoubleArray
    private val speedMps: Double = speedKmh / 3.6
    private var travelled = 0.0

    val totalMeters: Double

    init {
        require(points.size >= 2) { "A route needs at least two points" }
        require(speedKmh > 0) { "Speed must be positive" }
        path = if (loop && points.first() != points.last()) points + points.first() else points
        cumulative = DoubleArray(path.size)
        for (i in 1 until path.size) {
            cumulative[i] = cumulative[i - 1] + distanceMeters(path[i - 1], path[i])
        }
        totalMeters = cumulative.last()
    }

    /** Advances by [elapsedMs] and returns the new position. */
    fun advance(elapsedMs: Long): RouteFix {
        travelled += speedMps * elapsedMs / 1000.0
        return current()
    }

    fun current(): RouteFix {
        if (totalMeters <= 0.0) {
            return RouteFix(path[0].lat, path[0].lng, 0f, 0f, 1.0, !loop)
        }
        val finished = !loop && travelled >= totalMeters
        val d = if (loop) travelled % totalMeters else min(travelled, totalMeters)

        // Find segment containing distance d.
        var i = 1
        while (i < cumulative.size - 1 && cumulative[i] < d) i++
        val a = path[i - 1]
        val b = path[i]
        val segment = cumulative[i] - cumulative[i - 1]
        val t = if (segment <= 0.0) 0.0 else (d - cumulative[i - 1]) / segment
        val lat = a.lat + (b.lat - a.lat) * t
        val lng = a.lng + (b.lng - a.lng) * t

        return RouteFix(
            lat = lat,
            lng = lng,
            bearing = bearingDegrees(a, b),
            speed = if (finished) 0f else speedMps.toFloat(),
            progress = d / totalMeters,
            finished = finished,
        )
    }

    companion object {
        private const val EARTH_RADIUS_M = 6_371_008.8

        fun distanceMeters(a: GeoPoint, b: GeoPoint): Double {
            val dLat = Math.toRadians(b.lat - a.lat)
            val dLng = Math.toRadians(b.lng - a.lng)
            val h = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(a.lat)) * cos(Math.toRadians(b.lat)) * sin(dLng / 2) * sin(dLng / 2)
            return 2 * EARTH_RADIUS_M * asin(min(1.0, sqrt(h)))
        }

        fun bearingDegrees(a: GeoPoint, b: GeoPoint): Float {
            val lat1 = Math.toRadians(a.lat)
            val lat2 = Math.toRadians(b.lat)
            val dLng = Math.toRadians(b.lng - a.lng)
            val y = sin(dLng) * cos(lat2)
            val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng)
            val deg = Math.toDegrees(atan2(y, x))
            return ((deg + 360.0) % 360.0).toFloat()
        }
    }
}
