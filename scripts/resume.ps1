. "$PSScriptRoot\_common.ps1"
$s=Get-Content "$Root\automation\state\current.json" -Raw|ConvertFrom-Json
Write-Host "Phase: $($s.phase)`nTask: $($s.activeTask)`nState: $($s.status)`nNext: $($s.nextAction)"
git -C $Root status --short;git -C $Root log -5 --oneline
