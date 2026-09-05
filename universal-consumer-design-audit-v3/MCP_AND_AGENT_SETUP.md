# MCP + Agent Setup

## 1. Core principle

Audit sistemi MCP'ye değil metodolojiye bağlıdır.

MCP yalnız evidence toplama aracıdır.

Önerilen çekirdek:

```text
Any Agent
+ portable consumer-design-audit skill
+ Maestro CLI
+ Maestro MCP
+ Android emulator / iOS simulator
```

Conditional:
- Figma MCP
- GitHub MCP
- Context7
- Firebase/Supabase

---

# 2. Maestro MCP

Community-maintained Maestro MCP kullanılabilir.

Canonical audit hiçbir özel vendor server'a hard-code edilmemelidir.

MCP varsa:
- device discovery
- app launch
- tap
- input
- swipe
- hierarchy
- screenshot
- assertions
- flow execution

Yoksa Maestro CLI fallback.

---

# 3. Codex

Codex project instructions:
`AGENTS.md`

Codex MCP config tipik olarak:
`~/.codex/config.toml`

Örnek:

```toml
[mcp_servers.maestro]
command = "node"
args = ["D:/ABSOLUTE/PATH/maestro-mcp/dist/index.js"]
```

Codex'e audit çağrısı:

```text
Use the consumer-design-audit skill and run a BASELINE audit.
Do not change source code.
Use Maestro runtime evidence.
```

veya Türkçe:

```text
consumer-design-audit metodolojisini kullanarak BASELINE audit yap.
Kaynak kodu değiştirme.
Maestro ile gerçek runtime kanıtı topla.
```

---

# 4. Antigravity

Project skill:

```text
.agents/skills/consumer-design-audit/SKILL.md
```

Antigravity MCP merkezi config:

```text
~/.gemini/config/mcp_config.json
```

Örnek:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "node",
      "args": [
        "D:/ABSOLUTE/PATH/maestro-mcp/dist/index.js"
      ]
    }
  }
}
```

Antigravity'de skill adıyla veya slash/autodiscovery üzerinden çağır:

```text
consumer-design-audit
```

---

# 5. Claude Code

Canonical docs yine `.agent-audit/`.

Claude için:
- `CLAUDE.md` thin adapter
- portable skill'i Claude skill konumuna kopyalayabilir veya agent skill installer kullanabilirsin.

Claude-specific ikinci rubric oluşturma.

MCP config mevcut Claude setup'ına göre Maestro server'ı işaret etmelidir.

---

# 6. Cursor / Copilot / Gemini CLI

Amaç aynı:

1. root `AGENTS.md` / project instruction dosyasını okut
2. portable `SKILL.md` yükle
3. canonical `.agent-audit/` dosyalarını source-of-truth yap
4. Maestro tool erişimi ver

Agent değişse bile skor metodolojisi değişmemeli.

---

# 7. Portable skill installer

Agent Skills destekleyen ortamlarda canonical skill'i kopyalayabilir veya skill installer ile yükleyebilirsin.

Asıl source:
`.agents/skills/consumer-design-audit/`

Bunu tek canonical kopya olarak versiyonla.
