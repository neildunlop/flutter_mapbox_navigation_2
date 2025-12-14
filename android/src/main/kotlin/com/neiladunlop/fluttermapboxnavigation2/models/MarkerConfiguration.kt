package com.neiladunlop.fluttermapboxnavigation2.models

/**
 * Configuration for static marker display and behavior
 */
data class MarkerConfiguration(
    val showDuringNavigation: Boolean = true,
    val showInFreeDrive: Boolean = true,
    val showOnEmbeddedMap: Boolean = true,
    val maxDistanceFromRoute: Double? = null,
    val minZoomLevel: Double = 10.0,
    val enableClustering: Boolean = true,
    val maxMarkersToShow: Int? = null,
    val defaultIconId: String? = null,
    val defaultColor: Int? = null
) {
    companion object {
        /**
         * Creates a MarkerConfiguration from a JSON map
         */
        fun fromJson(json: Map<String, Any>?): MarkerConfiguration {
            if (json == null) return MarkerConfiguration()
            
            return MarkerConfiguration(
                showDuringNavigation = json["showDuringNavigation"] as? Boolean ?: true,
                showInFreeDrive = json["showInFreeDrive"] as? Boolean ?: true,
                showOnEmbeddedMap = json["showOnEmbeddedMap"] as? Boolean ?: true,
                maxDistanceFromRoute = json["maxDistanceFromRoute"] as? Double,
                minZoomLevel = (json["minZoomLevel"] as? Number)?.toDouble() ?: 10.0,
                enableClustering = json["enableClustering"] as? Boolean ?: true,
                maxMarkersToShow = json["maxMarkersToShow"] as? Int,
                defaultIconId = json["defaultIconId"] as? String,
                defaultColor = json["defaultColor"] as? Int
            )
        }
    }

    /**
     * Converts the MarkerConfiguration to a JSON map
     */
    fun toJson(): Map<String, Any> {
        val json = mutableMapOf<String, Any>(
            "showDuringNavigation" to showDuringNavigation,
            "showInFreeDrive" to showInFreeDrive,
            "showOnEmbeddedMap" to showOnEmbeddedMap,
            "minZoomLevel" to minZoomLevel,
            "enableClustering" to enableClustering
        )

        maxDistanceFromRoute?.let { json["maxDistanceFromRoute"] = it }
        maxMarkersToShow?.let { json["maxMarkersToShow"] = it }
        defaultIconId?.let { json["defaultIconId"] = it }
        defaultColor?.let { json["defaultColor"] = it }

        return json
    }

    override fun toString(): String {
        return "MarkerConfiguration(" +
                "showDuringNavigation=$showDuringNavigation, " +
                "showInFreeDrive=$showInFreeDrive, " +
                "showOnEmbeddedMap=$showOnEmbeddedMap, " +
                "maxDistanceFromRoute=$maxDistanceFromRoute, " +
                "minZoomLevel=$minZoomLevel, " +
                "enableClustering=$enableClustering, " +
                "maxMarkersToShow=$maxMarkersToShow)"
    }
} 