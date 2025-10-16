package com.rise.unplugged

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val channelName = "com.rise.unplugged/timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimezone" -> result.success(TimeZone.getDefault().id)
                "getAvailableTimezones" -> {
                    val timezones =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ZoneId.getAvailableZoneIds().toList()
                        } else {
                            TimeZone.getAvailableIDs().toList()
                        }
                    result.success(timezones)
                }

                else -> result.notImplemented()
            }
        }
    }
}
