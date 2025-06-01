package com.fahad.app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val token = resources.getString(R.string.mapbox_access_token)
        Log.d("MapboxDebug", "Access Token: $token")
    }
} 