package com.yourname.onlymen

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private var onboardingForcedThisProcess = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.yourname.onlymen/debug_launch",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shouldForceOnboarding" -> {
                    val forceOnboarding = !onboardingForcedThisProcess
                    onboardingForcedThisProcess = true
                    result.success(forceOnboarding)
                }
                else -> result.notImplemented()
            }
        }
    }
}
