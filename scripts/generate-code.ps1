. "$PSScriptRoot\_common.ps1"
Push-Location "$Root\apps\mobile"
try {
Invoke-CheckedCommand -Command dart -CommandArgs @('run', 'build_runner', 'build', '--delete-conflicting-outputs')
} finally {
  Pop-Location
}
