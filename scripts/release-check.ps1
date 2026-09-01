. "$PSScriptRoot\_common.ps1"
& "$PSScriptRoot\run-checks.ps1";if($LASTEXITCODE -ne 0){throw "Quality gates failed"};Ok "Local release checks passed"
