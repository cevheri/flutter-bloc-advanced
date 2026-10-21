package com.cevheri.flutter.flutter_bloc_advance

import android.app.Application

/** Starts the native Sentry SDK before the Flutter engine, as sentry_flutter requires when it does not start it. */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeSentry.start(this)
    }
}
