package com.neiladunlop.fluttermapboxnavigation2.factory

import android.app.Activity
import android.content.Context
import android.view.LayoutInflater
import com.neiladunlop.fluttermapboxnavigation2.R
import com.neiladunlop.fluttermapboxnavigation2.databinding.NavigationActivityBinding
import com.neiladunlop.fluttermapboxnavigation2.models.views.EmbeddedNavigationMapView
import com.neiladunlop.fluttermapboxnavigation2.utilities.PluginUtilities
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class EmbeddedNavigationViewFactory(
    private val messenger: BinaryMessenger,
    private val activity: Activity
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val inflater = LayoutInflater.from(context)
        val binding = NavigationActivityBinding.inflate(inflater)
        val accessToken = PluginUtilities.getResourceFromContext(context, "mapbox_access_token")
        val view = EmbeddedNavigationMapView(
            context,
            activity,
            binding,
            messenger,
            viewId,
            args,
            accessToken
        )

        view.initialize()

        activity.setTheme(R.style.AppTheme)

        return view
    }
}
