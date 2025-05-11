package com.dlzz.photo_gallery

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class MyApplication : FlutterApplication() {
    
    lateinit var flutterEngine : FlutterEngine

    override fun onCreate() {
        super.onCreate()
        
        // 初始化FlutterEngine
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // 缓存FlutterEngine
        FlutterEngineCache
            .getInstance()
            .put("my_engine_id", flutterEngine)
        
        // 注册插件
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
} 