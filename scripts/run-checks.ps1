. "$PSScriptRoot\_common.ps1"
& "$PSScriptRoot\doctor.ps1";if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
if(Test-Path "$Root\apps\mobile\pubspec.yaml"){Push-Location "$Root\apps\mobile";dart format --output=none --set-exit-if-changed .;flutter analyze;flutter test;Pop-Location}
& "$PSScriptRoot\run-security.ps1"
