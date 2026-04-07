package com.example.gaming_club_tashkent

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Must be called before the Flutter plugin calls MapKitFactory.initialize()
        MapKitFactory.setApiKey("92acbeed-5f95-4ad9-83c2-25a9fedf2860")
    }
}
