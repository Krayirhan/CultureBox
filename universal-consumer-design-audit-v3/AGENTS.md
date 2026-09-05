# Universal Agent Instructions — Consumer Design Audit

Bu repository'de mobil ürün tasarım/UX consumer audit sistemi vardır.

Herhangi bir agent kullanıcıdan:
- consumer audit
- kullanıcı gözüyle inceleme
- hedef kullanıcı açısından puanlama
- AI/template risk
- mobil UX audit
- tasarım re-audit

talebi alırsa aşağıdaki canonical sistemi kullanmalıdır:

1. `.agent-audit/PRODUCT_PROFILE.md`
2. `.agent-audit/WORKFLOW.md`
3. `.agent-audit/RUBRIC.md`
4. `.agent-audit/RESEARCH_PROTOCOL.md`
5. `.agent-audit/EVIDENCE_POLICY.md`
6. `.agent-audit/OUTPUT_TEMPLATE.md`

Varsa:
7. `.agent-audit/CURRENT_CONSUMER_STATE.md`
8. `.agent-audit/RUN_REGISTRY.md`

Ana ilke:

> Runtime kanıtı mümkünken static code/screenshot üzerinden interaction gerçeği uydurma.

Audit varsayılan olarak source code değiştirmez.

Önce:
audit → report → user approval → fix plan → implementation → re-audit

şeklinde ilerle.

Maestro / emulator / simulator mevcutsa gerçek kullanıcı akışlarını çalıştır.
Figma varsa implementation drift için kullan.
GitHub/CI yalnız revision/release kanıtı için kullanılır; design skorunu otomatik yükseltmez.
