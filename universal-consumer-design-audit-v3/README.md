# Universal Consumer Design Audit v3

Bu paket belirli bir agent'a özel değildir.

Desteklenen kullanım modeli:
- OpenAI Codex
- Google Antigravity / Antigravity IDE / CLI
- Claude Code
- Cursor
- GitHub Copilot CLI
- Gemini CLI
- agent skills / MCP destekleyen diğer agent'lar

## Mimari

Tek bir canonical çekirdek:

```text
.agent-audit/
├─ PRODUCT_PROFILE.md
├─ CURRENT_CONSUMER_STATE.md
├─ RUN_REGISTRY.md
├─ WORKFLOW.md
├─ RUBRIC.md
├─ RESEARCH_PROTOCOL.md
├─ EVIDENCE_POLICY.md
├─ OUTPUT_TEMPLATE.md
└─ runs/
```

Portable skill:

```text
.agents/
└─ skills/
   └─ consumer-design-audit/
      └─ SKILL.md
```

Agent adapter'ları sadece canonical dosyalara yönlendirir.

Amaç:
- aynı rubric
- aynı evidence policy
- aynı product profile
- aynı audit history
- farklı agent

Böylece Codex ile baseline alıp Antigravity ile re-audit yaptığında aynı metodolojiyi kullanabilirsin.
