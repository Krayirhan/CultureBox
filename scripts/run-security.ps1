. "$PSScriptRoot\_common.ps1"
if(Has-Cmd "gitleaks"){Invoke-CheckedCommand gitleaks @('detect', '--source', $Root, '--no-banner', '--redact')}else{Warn "gitleaks not installed; secret scanning was not performed locally"}
if(Has-Cmd "osv-scanner"){Invoke-CheckedCommand osv-scanner @('scan', 'source', '-r', $Root)}else{Warn "osv-scanner not installed; dependency scanning was not performed locally"}
