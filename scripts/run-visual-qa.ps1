. "$PSScriptRoot\_common.ps1"
Push-Location "$Root\apps\mobile"
try {
  Invoke-CheckedCommand -Command flutter -CommandArgs @('test', '--tags=golden')
} finally {
  Pop-Location
}
