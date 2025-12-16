# Mapbox AutoValue rules
-dontwarn com.google.auto.value.AutoValue$Builder
-dontwarn com.google.auto.value.AutoValue

# Keep Mapbox classes
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
