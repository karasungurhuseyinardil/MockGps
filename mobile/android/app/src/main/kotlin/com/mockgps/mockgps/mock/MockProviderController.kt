package com.mockgps.mockgps.mock

import android.annotation.SuppressLint
import android.content.Context
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.location.provider.ProviderProperties
import android.os.Build
import android.os.SystemClock
import android.util.Log
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices

/**
 * Pushes simulated locations through Android's official mock location APIs:
 * LocationManager test providers (gps, network, and fused on API 31+) and, when Google Play
 * services is present, FusedLocationProviderClient mock mode. Requires the app to be selected as
 * "mock location app" in Developer options; otherwise a SecurityException is thrown.
 */
class MockProviderController(context: Context) {
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val fused: FusedLocationProviderClient? = createFusedClient(context)
    private val active = mutableListOf<String>()
    private var fusedMockEnabled = false

    private val providers: List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.FUSED_PROVIDER)
        } else {
            listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        }

    /** @throws SecurityException when this app is not the selected mock location app. */
    fun enable() {
        for (provider in providers) {
            try {
                removeQuietly(provider)
                addTestProvider(provider)
                locationManager.setTestProviderEnabled(provider, true)
                active += provider
            } catch (e: SecurityException) {
                disable()
                throw e
            } catch (e: IllegalArgumentException) {
                // Provider not supported on this device (e.g. no network provider). Skip it.
                Log.w(TAG, "Skipping provider $provider: ${e.message}")
            }
        }
        if (active.isEmpty()) throw SecurityException("No test provider could be added")

        fused?.let {
            try {
                it.setMockMode(true).addOnFailureListener { e -> Log.w(TAG, "Fused mock mode failed", e) }
                fusedMockEnabled = true
            } catch (e: Exception) {
                Log.w(TAG, "Fused mock mode unavailable", e)
            }
        }
    }

    fun push(lat: Double, lng: Double, accuracy: Float, bearing: Float, speed: Float, altitude: Double = 0.0) {
        val now = System.currentTimeMillis()
        val elapsed = SystemClock.elapsedRealtimeNanos()
        for (provider in active) {
            pushToProvider(provider, buildLocation(provider, lat, lng, accuracy, bearing, speed, altitude, now, elapsed))
        }
        if (fusedMockEnabled) {
            pushToFused(buildLocation("fused", lat, lng, accuracy, bearing, speed, altitude, now, elapsed))
        }
    }

    private fun pushToProvider(provider: String, location: Location) {
        try {
            locationManager.setTestProviderLocation(provider, location)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Push to $provider failed: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    private fun pushToFused(location: Location) {
        val client = fused ?: return
        try {
            client.setMockLocation(location)
        } catch (e: SecurityException) {
            Log.w(TAG, "Fused push rejected", e)
        }
    }

    fun disable() {
        for (provider in active.toList()) removeQuietly(provider)
        active.clear()
        if (fusedMockEnabled) {
            try {
                fused?.setMockMode(false)
            } catch (e: Exception) {
                Log.w(TAG, "Fused mock mode disable failed", e)
            }
            fusedMockEnabled = false
        }
    }

    /** Removes test providers left over from a previous process (e.g. after a crash). */
    fun cleanupLeftovers() {
        for (provider in providers) removeQuietly(provider)
        try {
            fused?.setMockMode(false)
        } catch (ignored: Exception) {
        }
    }

    private fun removeQuietly(provider: String) {
        try {
            locationManager.removeTestProvider(provider)
        } catch (ignored: IllegalArgumentException) {
        } catch (ignored: SecurityException) {
        }
    }

    @Suppress("DEPRECATION")
    private fun addTestProvider(provider: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val accuracy = if (provider == LocationManager.GPS_PROVIDER) ProviderProperties.ACCURACY_FINE else ProviderProperties.ACCURACY_COARSE
            val properties = ProviderProperties.Builder()
                .setHasAltitudeSupport(true)
                .setHasSpeedSupport(true)
                .setHasBearingSupport(true)
                .setAccuracy(accuracy)
                .setPowerUsage(ProviderProperties.POWER_USAGE_LOW)
                .build()
            locationManager.addTestProvider(provider, properties)
        } else {
            val fine = provider == LocationManager.GPS_PROVIDER
            locationManager.addTestProvider(
                provider,
                false, false, false, false,
                true, true, true,
                Criteria.POWER_LOW,
                if (fine) Criteria.ACCURACY_FINE else Criteria.ACCURACY_COARSE,
            )
        }
    }

    private fun buildLocation(
        provider: String, lat: Double, lng: Double, accuracy: Float, bearing: Float, speed: Float,
        altitude: Double, time: Long, elapsedNanos: Long,
    ) = Location(provider).apply {
        latitude = lat
        longitude = lng
        this.accuracy = accuracy
        this.altitude = altitude
        this.bearing = bearing
        this.speed = speed
        this.time = time
        elapsedRealtimeNanos = elapsedNanos
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            verticalAccuracyMeters = accuracy * 1.5f
            speedAccuracyMetersPerSecond = 0.5f
            bearingAccuracyDegrees = 5f
        }
    }

    companion object {
        private const val TAG = "MockProvider"

        private fun createFusedClient(context: Context): FusedLocationProviderClient? =
            runCatching { LocationServices.getFusedLocationProviderClient(context) }.getOrNull()
    }
}
