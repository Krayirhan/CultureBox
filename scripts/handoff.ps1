param([string]$Agent="unknown")
. "$PSScriptRoot\_common.ps1"
$s=Get-Content "$Root\automation\state\current.json" -Raw|ConvertFrom-Json
$st=git -C $Root status --short;$lg=git -C $Root log -5 --oneline 2>$null
$body="# Handoff`n`nFrom: $Agent`nTask: $($s.activeTask)`nPhase: $($s.phase)`nStatus: $($s.status)`nNext: $($s.nextAction)`n`n## Git status`n```text`n$st`n``` `n## Recent commits`n```text`n$lg`n``` `nResume with docs/RESUME_PROTOCOL.md.`n"
Set-Content "$Root\docs\HANDOFF.md" $body -Encoding utf8
& "$PSScriptRoot\checkpoint.ps1" -Note "handoff generated" -Agent $Agent
