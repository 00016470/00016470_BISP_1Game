package com.onegame.app

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("92acbeed-5f95-4ad9-83c2-25a9fedf2860")
    }
}
