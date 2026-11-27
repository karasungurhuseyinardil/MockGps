package com.mockgps.mockgps.mock

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Bridge between Flutter (`mockgps/mock_location`) and the mock location service. */
class MockLocationPlugin(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, "mockgps/mock_location")
    private val events = EventChannel(messenger, "mockgps/mock_location/state")
    private var listener: ((SimulationState) -> Unit)? = null

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        // A previous process may have crashed while simulating: remove stale test providers.
        if (!MockLocationService.running && MockSetupChecker.isMockAppSelected(context)) {
            runCatching { MockProviderController(context).cleanupLeftovers() }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            handle(call, result)
        } catch (e: IllegalStateException) {
            // ForegroundServiceStartNotAllowedException (Android 12+) extends IllegalStateException.
            result.error("foreground_not_allowed", "Android did not allow the simulation service to start", e.message)
        } catch (e: SecurityException) {
            result.error("foreground_not_allowed", "Missing permission to start the simulation service", e.message)
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkSetup" -> result.success(MockSetupChecker.check(context))
            "getState" -> result.success(SimulationStateStore.restore(context, MockLocationService.running).toMap())
            "openDeveloperSettings" -> result.success(open(Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS))
                || open(Intent(Settings.ACTION_DEVICE_INFO_SETTINGS)))
            "openDeviceInfoSettings" -> result.success(open(Intent(Settings.ACTION_DEVICE_INFO_SETTINGS)))
            "openLocationSettings" -> result.success(open(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)))
            "openBatterySettings" -> result.success(open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)))
            "openAppSettings" -> result.success(open(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.packageName, null))))
            "startPoint" -> {
                val lat = call.argument<Double>("lat")
                val lng = call.argument<Double>("lng")
                if (lat == null || lng == null || lat !in -90.0..90.0 || lng !in -180.0..180.0) {
                    return result.error("invalid_coordinates", "Coordinates are out of range", null)
                }
                MockLocationService.send(context, MockLocationService.ACTION_START_POINT) {
                    putExtra(MockLocationService.EXTRA_LAT, lat)
                    putExtra(MockLocationService.EXTRA_LNG, lng)
                    common(call)
                }
                result.success(null)
            }
            "updatePoint" -> {
                val lat = call.argument<Double>("lat") ?: return result.error("invalid_coordinates", null, null)
                val lng = call.argument<Double>("lng") ?: return result.error("invalid_coordinates", null, null)
                MockLocationService.send(context, MockLocationService.ACTION_UPDATE_POINT) {
                    putExtra(MockLocationService.EXTRA_LAT, lat)
                    putExtra(MockLocationService.EXTRA_LNG, lng)
                }
                result.success(null)
            }
            "startRoute" -> {
                val points = call.argument<List<Double>>("points")
                if (points == null || points.size < 4 || points.size % 2 != 0) {
                    return result.error("invalid_route", "A route needs at least two points", null)
                }
                MockLocationService.send(context, MockLocationService.ACTION_START_ROUTE) {
                    putExtra(MockLocationService.EXTRA_POINTS, points.toDoubleArray())
                    putExtra(MockLocationService.EXTRA_SPEED_KMH, call.argument<Double>("speedKmh") ?: 30.0)
                    putExtra(MockLocationService.EXTRA_LOOP, call.argument<Boolean>("loop") ?: false)
                    common(call)
                }
                result.success(null)
            }
            "pause" -> { MockLocationService.send(context, MockLocationService.ACTION_PAUSE); result.success(null) }
            "resume" -> { MockLocationService.send(context, MockLocationService.ACTION_RESUME); result.success(null) }
            "stop" -> { MockLocationService.send(context, MockLocationService.ACTION_STOP); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private fun Intent.common(call: MethodCall) {
        putExtra(MockLocationService.EXTRA_ACCURACY, (call.argument<Double>("accuracy") ?: 5.0).toFloat())
        putExtra(MockLocationService.EXTRA_INTERVAL_MS, (call.argument<Int>("intervalMs") ?: 1000).toLong())
        putExtra(MockLocationService.EXTRA_JITTER, call.argument<Boolean>("jitter") ?: false)
    }

    private fun open(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val l: (SimulationState) -> Unit = { sink.success(it.toMap()) }
        listener = l
        SimulationStateStore.addListener(l)
        sink.success(SimulationStateStore.restore(context, MockLocationService.running).toMap())
    }

    override fun onCancel(arguments: Any?) {
        listener?.let { SimulationStateStore.removeListener(it) }
        listener = null
    }

    fun dispose() {
        onCancel(null)
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }
}
