param(
  [ValidateSet('run', 'build')][string]$Mode = 'run',
  [string]$Target = '',
  [string]$EnvFile = $env:CULTUREBOX_ENV_FILE
)
. "$PSScriptRoot\_common.ps1"
$envFile = Get-LocalDefinesFile $EnvFile
# Both entry points create debug APKs. Store releases use the approved CI gate.
if ($Mode -eq 'build') {
  & "$PSScriptRoot\build-mobile-debug.ps1" -EnvFile $envFile
  return
}
$sha = Get-DebugCertificateSha1
$arguments = @('run', '--debug', "--dart-define-from-file=$envFile", "--dart-define=ANDROID_CERT_SHA1=$sha")
if ($Target) { $arguments += @('-d', $Target) }
Push-Location (Join-Path $Root 'apps\mobile')
try {
  Invoke-CheckedCommand -Command flutter -CommandArgs @('pub', 'get')
  Invoke-CheckedCommand -Command flutter -CommandArgs $arguments
} finally {
  Pop-Location
}
