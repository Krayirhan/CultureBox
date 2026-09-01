. "$PSScriptRoot\_common.ps1"
$bad=$false
foreach($c in @("git","flutter","dart","node","npm","npx","python")){if(Has-Cmd $c){Ok $c}else{Fail "$c missing";$bad=$true}}
foreach($c in @("firebase","uv","graphify","serena","ctx7","docker")){if(Has-Cmd $c){Ok $c}else{Warn "$c optional/not ready"}}
if(Test-Path "$Root\.env.local"){Ok ".env.local"}else{Warn "copy .env.example -> .env.local"}
if(Test-Path "$Root\graphify-out\graph.json"){Ok "Graphify graph"}else{Warn "run: graphify ."}
if($bad){exit 1}else{Ok "Core environment ready"}
