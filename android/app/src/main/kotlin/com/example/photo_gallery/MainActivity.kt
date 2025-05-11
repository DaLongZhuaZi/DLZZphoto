package com.example.photo_gallery

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get("my_engine_id")
            ?: super.provideFlutterEngine(context)
    }
}
