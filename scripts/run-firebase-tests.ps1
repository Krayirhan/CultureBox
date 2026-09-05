. "$PSScriptRoot\_common.ps1"
Push-Location "$Root\firebase\tests"
try {
  # npm.ps1 reconstructs its input from the calling source line and therefore
  # loses arguments when invoked through a wrapper. Prefer the native shim.
  $npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
  if (-not $npm) { $npm = (Get-Command npm -ErrorAction Stop).Source }
  Invoke-CheckedCommand -Command $npm -CommandArgs @('ci', '--ignore-scripts', '--no-audit', '--no-fund')
  Invoke-CheckedCommand -Command $npm -CommandArgs @('run', 'test:emulator')
} finally {
  Pop-Location
}
