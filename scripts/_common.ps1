$ErrorActionPreference="Stop"
$Root=Split-Path -Parent $PSScriptRoot
function Has-Cmd($n){return $null -ne (Get-Command $n -ErrorAction SilentlyContinue)}
function Ok($m){Write-Host "[OK] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[!!] $m" -ForegroundColor Yellow}
function Fail($m){Write-Host "[XX] $m" -ForegroundColor Red}

# PowerShell's ErrorActionPreference does not make native exit codes fatal.
# Keep command arguments out of errors: defines can contain provider values.
function Invoke-CheckedCommand {
  param([Parameter(Mandatory)][string]$Command, [string[]]$CommandArgs = @())
  $global:LASTEXITCODE = 0
  & $Command @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    throw "$(Split-Path -Leaf $Command) failed with exit code $LASTEXITCODE."
  }
}

function Get-LocalDefinesFile {
  param([string]$Path = $env:CULTUREBOX_ENV_FILE)
  if ([string]::IsNullOrWhiteSpace($Path)) { $Path = Join-Path $Root '.env.local' }
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw 'Missing provider configuration. Set CULTUREBOX_ENV_FILE to your private .env file.'
  }
  return (Resolve-Path -LiteralPath $Path).Path
}

function Get-DebugCertificateSha1 {
  $keytool = Get-Command keytool -ErrorAction SilentlyContinue
  $keytoolPath = if ($keytool) { $keytool.Source } else { $null }
  if (-not $keytoolPath -and $env:ProgramFiles) {
    $candidate = Get-ChildItem "$env:ProgramFiles\Android\*\jbr\bin\keytool.exe" -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($candidate) { $keytoolPath = $candidate.FullName }
  }
  if (-not $keytoolPath) { throw 'Java keytool is required to read the Android debug certificate.' }
  $debugKeystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
  if (-not (Test-Path -LiteralPath $debugKeystore)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $debugKeystore) -Force | Out-Null
    Invoke-CheckedCommand -Command $keytoolPath -CommandArgs @('-genkeypair', '-keystore', $debugKeystore,
      '-storepass', 'android', '-keypass', 'android', '-alias', 'androiddebugkey',
      '-dname', 'CN=Android Debug,O=Android,C=US', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000')
  }
  # Force a stable keytool locale before parsing the public fingerprint.
  $certificate = Invoke-CheckedCommand -Command $keytoolPath -CommandArgs @('-J-Duser.language=en', '-J-Duser.country=US',
    '-list', '-v', '-keystore', $debugKeystore, '-alias', 'androiddebugkey',
    '-storepass', 'android', '-keypass', 'android')
  $shaLine = $certificate | Select-String '^\s*SHA1:\s*([0-9A-Fa-f:]+)\s*$' | Select-Object -First 1
  if (-not $shaLine) { throw 'The Android debug certificate SHA-1 could not be read.' }
  $sha = $shaLine.Matches[0].Groups[1].Value.Replace(':', '').ToUpperInvariant()
  if ($sha -notmatch '^[0-9A-F]{40}$') { throw 'The Android debug certificate SHA-1 is invalid.' }
  return $sha
}
