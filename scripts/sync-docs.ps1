. "$PSScriptRoot\_common.ps1"
Write-Host "Review affected docs using DOCS_INDEX";git -C $Root diff --name-only
