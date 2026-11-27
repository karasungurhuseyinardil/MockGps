package com.mockgps.mockgps

import com.mockgps.mockgps.mock.MockLocationPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var mockLocation: MockLocationPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mockLocation = MockLocationPlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mockLocation?.dispose()
        mockLocation = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
