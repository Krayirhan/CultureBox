. "$PSScriptRoot\_common.ps1"
Write-Host "=== FULL AUTO BOOTSTRAP ==="
& "$PSScriptRoot\setup-flutter.ps1";& "$PSScriptRoot\setup-firebase.ps1"
if(Has-Cmd "uv"){& "$PSScriptRoot\setup-context-tools.ps1"}else{Warn "uv missing; context tools skipped"}
& "$PSScriptRoot\setup-mcp.ps1";& "$PSScriptRoot\generate-agent-configs.ps1"
if(Has-Cmd "graphify"){Push-Location $Root;graphify .;Pop-Location}
& "$PSScriptRoot\doctor.ps1"
