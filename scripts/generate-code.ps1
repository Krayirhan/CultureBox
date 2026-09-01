. "$PSScriptRoot\_common.ps1"
if(Test-Path "$Root\apps\mobile\pubspec.yaml"){Push-Location "$Root\apps\mobile";dart run build_runner build --delete-conflicting-outputs;Pop-Location}else{Warn "Flutter app not ready"}
