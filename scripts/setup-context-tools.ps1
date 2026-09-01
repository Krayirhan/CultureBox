. "$PSScriptRoot\_common.ps1"
if(-not(Has-Cmd "uv")){throw "Install uv first"}
if(-not(Has-Cmd "graphify")){uv tool install "graphifyy[mcp]"}else{uv tool upgrade graphifyy}
if(-not(Has-Cmd "serena")){uv tool install -p 3.13 serena-agent}else{uv tool upgrade serena-agent}
serena init
if(-not(Has-Cmd "ctx7")){npm install -g ctx7}
graphify install
Ok "Context tools installed"
