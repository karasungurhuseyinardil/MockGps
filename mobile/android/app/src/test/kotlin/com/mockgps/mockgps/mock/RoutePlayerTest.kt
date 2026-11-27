package com.mockgps.mockgps.mock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RoutePlayerTest {
    private val start = GeoPoint(41.0, 29.0)
    private val north = GeoPoint(41.01, 29.0) // ~1112 m north

    @Test
    fun distance_matches_haversine() {
        assertEquals(1112.0, RoutePlayer.distanceMeters(start, north), 2.0)
    }

    @Test
    fun bearing_north_and_east() {
        assertEquals(0f, RoutePlayer.bearingDegrees(start, north), 0.5f)
        assertEquals(90f, RoutePlayer.bearingDegrees(start, GeoPoint(41.0, 29.01)), 0.5f)
    }

    @Test
    fun moves_at_configured_speed() {
        val player = RoutePlayer(listOf(start, north), speedKmh = 36.0, loop = false) // 10 m/s
        val fix = player.advance(10_000) // 100 m
        assertEquals(100.0, RoutePlayer.distanceMeters(start, GeoPoint(fix.lat, fix.lng)), 1.0)
        assertEquals(10f, fix.speed, 0.01f)
        assertFalse(fix.finished)
    }

    @Test
    fun stops_at_end_when_not_looping() {
        val player = RoutePlayer(listOf(start, north), speedKmh = 3600.0, loop = false)
        val fix = player.advance(60_000)
        assertTrue(fix.finished)
        assertEquals(north.lat, fix.lat, 1e-9)
        assertEquals(0f, fix.speed, 0f)
    }

    @Test
    fun loop_returns_towards_start() {
        val player = RoutePlayer(listOf(start, north), speedKmh = 36.0, loop = true)
        val lap = player.totalMeters
        assertEquals(2 * 1112.0, lap, 4.0) // closed path: there and back
        val fix = player.advance(((lap / 10.0) * 1000 * 0.75).toLong()) // 75% of a lap = on the way back
        assertFalse(fix.finished)
        assertEquals(180f, fix.bearing, 1f)
        assertEquals(0.75, fix.progress, 0.01)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejects_single_point() {
        RoutePlayer(listOf(start), 30.0, false)
    }
}
