. "$PSScriptRoot\_common.ps1"
$rules=Get-Content "$Root\docs\MASTER_RULES.md" -Raw
$resume=Get-Content "$Root\docs\RESUME_PROTOCOL.md" -Raw
Set-Content "$Root\AGENTS.md" ("# GENERATED BRIDGE`n`n"+$rules+"`n"+$resume) -Encoding utf8
Set-Content "$Root\CLAUDE.md" "# Generated bridge`nRead docs/MASTER_RULES.md and docs/RESUME_PROTOCOL.md." -Encoding utf8
Set-Content "$Root\GEMINI.md" "# Generated bridge`nRead docs/MASTER_RULES.md and docs/RESUME_PROTOCOL.md." -Encoding utf8
Ok "Agent bridges generated"
