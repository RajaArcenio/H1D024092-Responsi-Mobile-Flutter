package com.rajaarcenio.langit_kota

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val prefs = getSharedPreferences("langit_kota", MODE_PRIVATE)
        // Disk writes run on a serial background queue.
        val channel = MethodChannel(
            messenger, "langit_kota/locations",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        )
        channel.setMethodCallHandler { call, result ->
            val key = call.argument<String>("key")
            if (key == null) {
                result.error("INVALID_KEY", "Kunci lokasi kosong.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "read" -> result.success(prefs.getString(key, null))
                "write" -> {
                    val value = call.argument<String>("value")
                    if (value != null && prefs.edit().putString(key, value).commit()) {
                        result.success(null)
                    } else {
                        result.error("WRITE_FAILED", "Lokasi gagal disimpan.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
