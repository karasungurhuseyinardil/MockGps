package com.mockgps.mockgps.mock

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.json.JSONObject

/** Snapshot of the simulation, shared between the service and the Flutter bridge. */
data class SimulationState(
    val status: String = STATUS_IDLE,
    val mode: String? = null,
    val lat: Double? = null,
    val lng: Double? = null,
    val bearing: Float = 0f,
    val speed: Float = 0f,
    val accuracy: Float = 5f,
    val progress: Double? = null,
    val startedAt: Long? = null,
    val errorCode: String? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status, "mode" to mode, "lat" to lat, "lng" to lng, "bearing" to bearing.toDouble(),
        "speed" to speed.toDouble(), "accuracy" to accuracy.toDouble(), "progress" to progress,
        "startedAt" to startedAt, "errorCode" to errorCode,
    )

    companion object {
        const val STATUS_IDLE = "idle"
        const val STATUS_RUNNING = "running"
        const val STATUS_PAUSED = "paused"
        const val STATUS_ERROR = "error"
    }
}

/**
 * Process-wide state holder. Persists the last state so the UI can reconnect after the Flutter
 * engine or the process is recreated, and notifies listeners on the main thread.
 */
object SimulationStateStore {
    private const val PREFS = "mock_simulation"
    private const val KEY = "state"
    private val main = Handler(Looper.getMainLooper())
    private val listeners = mutableSetOf<(SimulationState) -> Unit>()

    @Volatile
    var current: SimulationState = SimulationState()
        private set

    fun update(context: Context, state: SimulationState) {
        current = state
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY, JSONObject(state.toMap()).toString()).apply()
        main.post { listeners.toList().forEach { it(state) } }
    }

    /** Last persisted state, used when no service is running in this process. */
    fun restore(context: Context, serviceRunning: Boolean): SimulationState {
        if (serviceRunning) return current
        // The service is gone (process killed): report idle, keep last coordinates for the UI.
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
        val last = json?.let { runCatching { JSONObject(it) }.getOrNull() }
        current = SimulationState(
            lat = last?.optDouble("lat")?.takeUnless { it.isNaN() },
            lng = last?.optDouble("lng")?.takeUnless { it.isNaN() },
        )
        return current
    }

    fun addListener(listener: (SimulationState) -> Unit) { listeners += listener }
    fun removeListener(listener: (SimulationState) -> Unit) { listeners -= listener }
}
