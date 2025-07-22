package com.eopeter.fluttermapboxnavigation.views

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for creating Flutter navigation platform views
 * This allows Flutter to embed native Android navigation views as platform views
 */
class FlutterNavigationPlatformViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return FlutterNavigationPlatformView(context, viewId, creationParams, messenger)
    }
}