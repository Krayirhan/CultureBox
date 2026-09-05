# Configuration can live outside the repository through CULTUREBOX_ENV_FILE.
param([string]$EnvFile = $env:CULTUREBOX_ENV_FILE)
. "$PSScriptRoot\_common.ps1"
$envFile = Get-LocalDefinesFile $EnvFile
$sha = Get-DebugCertificateSha1
Push-Location (Join-Path $Root 'apps\mobile')
try {
  Invoke-CheckedCommand -Command flutter -CommandArgs @('pub', 'get')
  Invoke-CheckedCommand -Command flutter -CommandArgs @('build', 'apk', '--debug',
    "--dart-define-from-file=$envFile", "--dart-define=ANDROID_CERT_SHA1=$sha")
} finally {
  Pop-Location
}
