. "$PSScriptRoot\_common.ps1"
if(-not(Has-Cmd "flutter")){throw "Flutter SDK missing"}
if(-not(Test-Path "$Root\apps\mobile\pubspec.yaml")){New-Item -ItemType Directory -Force "$Root\apps"|Out-Null;flutter create --platforms=android,ios "$Root\apps\mobile"}
Ok "Flutter ready"
