package com.mockgps.mockgps.mock

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability

/** Reports every precondition for mock location so the UI can guide the user step by step. */
object MockSetupChecker {
    fun check(context: Context): Map<String, Any> {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return mapOf(
            "locationPermission" to has(context, Manifest.permission.ACCESS_FINE_LOCATION),
            "notificationPermission" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                has(context, Manifest.permission.POST_NOTIFICATIONS)),
            "developerOptionsEnabled" to (Settings.Global.getInt(
                context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1),
            "mockAppSelected" to isMockAppSelected(context),
            "locationEnabled" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || lm.isLocationEnabled),
            "batteryOptimizationIgnored" to isIgnoringBatteryOptimizations(context),
            "playServicesAvailable" to (GoogleApiAvailability.getInstance()
                .isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS),
            "sdkInt" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
        )
    }

    fun isMockAppSelected(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_MOCK_LOCATION, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_MOCK_LOCATION, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    private fun has(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
}
