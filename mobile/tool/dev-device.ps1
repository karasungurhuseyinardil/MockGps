<#
.SYNOPSIS
  Prepares a connected Android device (USB or wireless debugging) for local development and runs the app.

.DESCRIPTION
  - Picks the device (first one, or -Device <serial>).
  - Tunnels the local API (5080) and Supabase (54321) to the phone with `adb reverse`, so the phone
    reaches http://127.0.0.1:<port> without opening Windows Firewall ports. Works over wireless adb.
  - Optionally (-GrantSetup) grants location permissions and selects the app as mock location app.
    This is the same as choosing it in Developer options; skip it to test the in-app setup guide.
  - Runs `flutter run` with env/dev.json.

  Tunnels last while adb stays connected. Re-run after reconnecting the phone.

.EXAMPLE
  ./tool/dev-device.ps1 -GrantSetup
  ./tool/dev-device.ps1 -NoRun
#>
param(
  [string]$Device,
  [switch]$GrantSetup,
  [switch]$NoRun
)

$ErrorActionPreference = 'Stop'
$package = 'com.mockgps.mockgps'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $Device) {
  $Device = (adb devices | Select-String '\tdevice$' | Select-Object -First 1).Line -replace '\tdevice$', ''
}
if (-not $Device) { throw 'No device found. Enable USB or wireless debugging and pair the phone (adb pair <ip:port>).' }
Write-Host "Device: $Device ($(adb -s $Device shell getprop ro.product.model)) Android $(adb -s $Device shell getprop ro.build.version.release)"

foreach ($port in 5080, 54321) { adb -s $Device reverse "tcp:$port" "tcp:$port" | Out-Null }
Write-Host 'Tunnels:'; adb -s $Device reverse --list

if ($GrantSetup) {
  if (-not (adb -s $Device shell pm list packages $package)) {
    Write-Host 'App not installed yet; installing debug build first...'
    flutter build apk --debug --dart-define-from-file=env/dev.json
    adb -s $Device install -r build/app/outputs/flutter-apk/app-debug.apk
  }
  foreach ($p in 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION', 'POST_NOTIFICATIONS') {
    adb -s $Device shell pm grant $package "android.permission.$p" 2>$null
  }
  adb -s $Device shell appops set $package android:mock_location allow
  Write-Host "Mock location app: $(adb -s $Device shell appops get $package android:mock_location)"
}

if (-not $NoRun) {
  flutter run -d $Device --dart-define-from-file=env/dev.json
}
