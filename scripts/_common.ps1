$ErrorActionPreference="Stop"
$Root=Split-Path -Parent $PSScriptRoot
function Has-Cmd($n){return $null -ne (Get-Command $n -ErrorAction SilentlyContinue)}
function Ok($m){Write-Host "[OK] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[!!] $m" -ForegroundColor Yellow}
function Fail($m){Write-Host "[XX] $m" -ForegroundColor Red}
