. "$PSScriptRoot\_common.ps1"
& "$PSScriptRoot\run-checks.ps1"
& "$PSScriptRoot\run-firebase-tests.ps1"
Ok 'Local release checks passed; publication requires the protected release CI workflow'
