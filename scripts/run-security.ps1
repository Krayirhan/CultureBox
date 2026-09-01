. "$PSScriptRoot\_common.ps1"
if(Has-Cmd "gitleaks"){gitleaks detect --source $Root --no-banner}else{Warn "gitleaks not installed"}
if(Has-Cmd "osv-scanner"){osv-scanner scan source -r $Root}else{Warn "osv-scanner not installed"}
