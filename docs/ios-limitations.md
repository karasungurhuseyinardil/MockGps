# iOS limitations

* iOS has **no public API** that lets an app change the location seen by other apps.
  Apps that try (private frameworks, jailbreak tweaks) are rejected by App Review. This project does
  not use any of them.
* What Apple supports for developers:
  * **Xcode → Debug → Simulate Location** with a `.gpx` file on a connected device or the Simulator.
  * Location simulation inside the iOS Simulator (Features → Location).
  * Xcode test schemes with a default simulated location.

## What the iOS app does

* Works: account, favorites, categories, history, saved routes, search / reverse geocoding, settings.
* Instead of *Start simulation*, iOS shows **Export GPX**: the selected point or route is exported as a
  `.gpx` file that a developer can load in Xcode's *Simulate Location*.
* The simulation start button is not shown on iOS, and the UI explains why.

## Build

iOS builds need macOS with Xcode. The Flutter code is kept platform-safe; building and testing the iOS
target happens on a Mac.
