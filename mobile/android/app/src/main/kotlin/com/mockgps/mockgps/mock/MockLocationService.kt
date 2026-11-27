package com.mockgps.mockgps.mock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.mockgps.mockgps.MainActivity
import com.mockgps.mockgps.R
import java.util.Locale
import kotlin.math.cos
import kotlin.random.Random

/**
 * Foreground service (type=location) that keeps pushing the simulated location. Runs independently
 * of the Flutter UI so simulation continues in the background; stopped from the app or the
 * notification's Stop action.
 */
class MockLocationService : Service() {
    private lateinit var controller: MockProviderController
    private lateinit var thread: HandlerThread
    private lateinit var handler: Handler

    private var intervalMs = 1000L
    private var accuracy = 5f
    private var jitter = false
    private var pointLat = 0.0
    private var pointLng = 0.0
    private var route: RoutePlayer? = null
    private var paused = false
    private var lastTick = 0L
    private var startedAt = 0L
    private var providersEnabled = false

    private val tick = object : Runnable {
        override fun run() {
            pushOnce()
            handler.postDelayed(this, intervalMs)
        }
    }

    override fun onCreate() {
        super.onCreate()
        controller = MockProviderController(this)
        thread = HandlerThread("mock-location").apply { start() }
        handler = Handler(thread.looper)
        running = true
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_POINT -> startPoint(intent)
            ACTION_START_ROUTE -> startRoute(intent)
            ACTION_UPDATE_POINT -> handler.post {
                pointLat = intent.getDoubleExtra(EXTRA_LAT, pointLat)
                pointLng = intent.getDoubleExtra(EXTRA_LNG, pointLng)
                route = null
                paused = false
                pushOnce()
            }
            ACTION_PAUSE -> handler.post { paused = true; publish(SimulationState.STATUS_PAUSED) }
            ACTION_RESUME -> handler.post { paused = false; lastTick = SystemClock.elapsedRealtime(); pushOnce() }
            ACTION_STOP -> stopSimulation()
            else -> if (!providersEnabled) stopSelf() // restarted without a command: nothing to resume
        }
        return START_NOT_STICKY
    }

    private fun startPoint(intent: Intent) {
        readCommon(intent)
        pointLat = intent.getDoubleExtra(EXTRA_LAT, 0.0)
        pointLng = intent.getDoubleExtra(EXTRA_LNG, 0.0)
        route = null
        begin()
    }

    private fun startRoute(intent: Intent) {
        readCommon(intent)
        val flat = intent.getDoubleArrayExtra(EXTRA_POINTS) ?: doubleArrayOf()
        val points = (0 until flat.size / 2).map { GeoPoint(flat[it * 2], flat[it * 2 + 1]) }
        route = try {
            RoutePlayer(points, intent.getDoubleExtra(EXTRA_SPEED_KMH, 30.0), intent.getBooleanExtra(EXTRA_LOOP, false))
        } catch (e: IllegalArgumentException) {
            fail("invalid_route")
            return
        }
        pointLat = points.first().lat
        pointLng = points.first().lng
        begin()
    }

    private fun readCommon(intent: Intent) {
        intervalMs = intent.getLongExtra(EXTRA_INTERVAL_MS, 1000L).coerceIn(200L, 60_000L)
        accuracy = intent.getFloatExtra(EXTRA_ACCURACY, 5f).coerceIn(1f, 500f)
        jitter = intent.getBooleanExtra(EXTRA_JITTER, false)
    }

    private fun begin() {
        // startForeground must be called promptly after startForegroundService().
        try {
            ServiceCompat.startForeground(
                this, NOTIFICATION_ID, buildNotification(),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0,
            )
        } catch (e: Exception) {
            // Android 14+: missing location permission or background start restriction.
            Log.e(TAG, "startForeground failed", e)
            fail("foreground_not_allowed")
            return
        }
        handler.removeCallbacks(tick)
        handler.post {
            try {
                if (!providersEnabled) {
                    controller.enable()
                    providersEnabled = true
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "Not selected as mock location app", e)
                fail("mock_app_not_selected")
                return@post
            }
            paused = false
            startedAt = System.currentTimeMillis()
            lastTick = SystemClock.elapsedRealtime()
            handler.post(tick)
        }
    }

    private fun pushOnce() {
        if (!providersEnabled) return
        val now = SystemClock.elapsedRealtime()
        val elapsed = now - lastTick
        lastTick = now

        var lat = pointLat
        var lng = pointLng
        var bearing = 0f
        var speed = 0f
        var progress: Double? = null
        val player = route

        if (player != null) {
            val fix = if (paused) player.current() else player.advance(elapsed)
            lat = fix.lat; lng = fix.lng; bearing = fix.bearing; progress = fix.progress
            speed = if (paused) 0f else fix.speed
            if (fix.finished) {
                // Stay at the end point as a stationary simulation.
                route = null
                pointLat = fix.lat; pointLng = fix.lng
            }
        } else if (jitter) {
            // Small random offset inside the reported accuracy circle.
            val r = accuracy * 0.3 * Random.nextDouble()
            val a = Random.nextDouble() * 2 * Math.PI
            lat += (r * kotlin.math.sin(a)) / 111_320.0
            lng += (r * cos(a)) / (111_320.0 * cos(Math.toRadians(lat)).coerceAtLeast(0.01))
        }

        try {
            controller.push(lat, lng, accuracy, bearing, speed)
        } catch (e: SecurityException) {
            // Mock app was deselected while running.
            fail("mock_app_not_selected")
            return
        }
        currentLat = lat
        currentLng = lng
        publish(if (paused) SimulationState.STATUS_PAUSED else SimulationState.STATUS_RUNNING, bearing, speed, progress)
        updateNotification(lat, lng)
    }

    private fun publish(status: String, bearing: Float = 0f, speed: Float = 0f, progress: Double? = null) {
        SimulationStateStore.update(this, SimulationState(
            status = status,
            mode = if (route != null) MODE_ROUTE else MODE_POINT,
            lat = currentLat, lng = currentLng, bearing = bearing, speed = speed, accuracy = accuracy,
            progress = progress, startedAt = startedAt,
        ))
    }

    private fun fail(code: String) {
        handler.removeCallbacks(tick)
        if (providersEnabled) controller.disable()
        providersEnabled = false
        SimulationStateStore.update(this, SimulationState(status = SimulationState.STATUS_ERROR, errorCode = code))
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun stopSimulation() {
        handler.removeCallbacks(tick)
        handler.post {
            if (providersEnabled) controller.disable()
            providersEnabled = false
            SimulationStateStore.update(this, SimulationState(lat = currentLat, lng = currentLng))
        }
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        if (providersEnabled) {
            controller.disable()
            providersEnabled = false
            SimulationStateStore.update(this, SimulationState(lat = currentLat, lng = currentLng))
        }
        thread.quitSafely()
        running = false
        super.onDestroy()
    }

    // --- Notification -------------------------------------------------------------------------

    private fun buildNotification(text: String? = null): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL_ID) == null) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL_ID, getString(R.string.simulation_channel_name),
                NotificationManager.IMPORTANCE_LOW).apply { description = getString(R.string.simulation_channel_description) })
        }
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, MockLocationService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_simulation)
            .setContentTitle(getString(R.string.simulation_notification_title))
            .setContentText(text ?: getString(R.string.simulation_notification_starting))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(open)
            .addAction(0, getString(R.string.simulation_notification_stop), stop)
            .build()
    }

    private var lastNotificationText: String? = null

    private fun updateNotification(lat: Double, lng: Double) {
        val text = String.format(Locale.US, "%.5f, %.5f%s", lat, lng, if (paused) " · ${getString(R.string.simulation_paused)}" else "")
        if (text == lastNotificationText) return
        lastNotificationText = text
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(text))
    }

    companion object {
        private const val TAG = "MockLocationService"
        private const val CHANNEL_ID = "simulation"
        private const val NOTIFICATION_ID = 4711

        const val ACTION_START_POINT = "com.mockgps.START_POINT"
        const val ACTION_START_ROUTE = "com.mockgps.START_ROUTE"
        const val ACTION_UPDATE_POINT = "com.mockgps.UPDATE_POINT"
        const val ACTION_PAUSE = "com.mockgps.PAUSE"
        const val ACTION_RESUME = "com.mockgps.RESUME"
        const val ACTION_STOP = "com.mockgps.STOP"

        const val EXTRA_LAT = "lat"
        const val EXTRA_LNG = "lng"
        const val EXTRA_POINTS = "points"
        const val EXTRA_SPEED_KMH = "speedKmh"
        const val EXTRA_LOOP = "loop"
        const val EXTRA_ACCURACY = "accuracy"
        const val EXTRA_INTERVAL_MS = "intervalMs"
        const val EXTRA_JITTER = "jitter"

        const val MODE_POINT = "point"
        const val MODE_ROUTE = "route"

        @Volatile
        var running = false
            private set

        @Volatile
        private var currentLat: Double? = null
        @Volatile
        private var currentLng: Double? = null

        /**
         * @throws IllegalStateException when Android refuses to start the service, e.g. Android 12+
         * background start restrictions (the app must be visible when the user starts a simulation).
         */
        fun send(context: Context, action: String, extras: Intent.() -> Unit = {}) {
            val intent = Intent(context, MockLocationService::class.java).setAction(action).apply(extras)
            if (action == ACTION_START_POINT || action == ACTION_START_ROUTE) {
                ContextCompat.startForegroundService(context, intent)
            } else if (running) {
                context.startService(intent)
            }
        }
    }
}
