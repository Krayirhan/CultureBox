. "$PSScriptRoot\_common.ps1"
if (-not (Test-Path "$Root\apps\mobile\pubspec.yaml")) { throw 'Flutter app is missing.' }
Push-Location "$Root\apps\mobile"
try {
  Invoke-CheckedCommand -Command flutter -CommandArgs @('test')
} finally {
  Pop-Location
}
