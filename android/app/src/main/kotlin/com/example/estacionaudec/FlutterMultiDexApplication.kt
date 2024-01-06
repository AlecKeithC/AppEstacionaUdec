package com.example.estacionaudec

import io.flutter.app.FlutterApplication
import androidx.multidex.MultiDex
import android.content.Context


class FlutterMultiDexApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}