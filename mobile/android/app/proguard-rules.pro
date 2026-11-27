# MapLibre
-keep class org.maplibre.** { *; }
-dontwarn org.maplibre.**
# Mock location service is referenced from the manifest only.
-keep class com.mockgps.mockgps.mock.** { *; }
