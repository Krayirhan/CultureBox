param([string]$Note="checkpoint",[string]$Agent="unknown")
. "$PSScriptRoot\_common.ps1"
$s=Get-Content "$Root\automation\state\current.json" -Raw|ConvertFrom-Json
$row=[ordered]@{at=(Get-Date).ToUniversalTime().ToString("o");agent=$Agent;task=$s.activeTask;status=$s.status;note=$Note}
($row|ConvertTo-Json -Compress)|Add-Content "$Root\automation\state\checkpoints.jsonl"
Ok "Checkpoint $($s.activeTask)"
