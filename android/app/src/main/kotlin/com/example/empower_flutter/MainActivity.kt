package com.example.empower_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Define the MethodChannel name. This must match the channel name used in Flutter.
    private val CHANNEL = "example.flutter.sentry.io"

    // Called when the Flutter engine is being configured.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Set up a MethodChannel to communicate between Flutter and native Android.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Handle method calls from Flutter.
            if (call.method == "kotlinException") {
                // Throw a real native exception. Sentry's Android SDK will capture this if set up.
                throw RuntimeException("Simulated Kotlin Exception from native code")
            } else {
                // If the method is not implemented, notify Flutter.
                result.notImplemented()
            }
        }
    }
}
