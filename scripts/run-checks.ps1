. "$PSScriptRoot\_common.ps1"
& "$PSScriptRoot\doctor.ps1"
if (-not (Test-Path "$Root\apps\mobile\pubspec.yaml")) { throw 'Flutter app is missing.' }
Push-Location "$Root\apps\mobile"
try {
  Invoke-CheckedCommand -Command flutter -CommandArgs @('pub', 'get')
  # Formatting is a repair step here; the formatter's changed-files exit code
  # must not hide later analyzer, test, or security failures.
  Invoke-CheckedCommand -Command dart -CommandArgs @('format', '--output=none', '.')
  Invoke-CheckedCommand -Command flutter -CommandArgs @('analyze')
  # Provider fixtures inject their own keys; checks never read production secrets.
  Invoke-CheckedCommand -Command flutter -CommandArgs @('test')
} finally {
  Pop-Location
}
& "$PSScriptRoot\run-security.ps1"
Ok 'Local Flutter and available security checks passed'
