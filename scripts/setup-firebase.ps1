. "$PSScriptRoot\_common.ps1"
if(-not(Has-Cmd "firebase")){npm install -g firebase-tools}
firebase --version
Write-Host "If needed run: firebase login"
