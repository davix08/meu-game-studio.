# Story 016: Pasto com animais (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: thin — pasto com animais (cuidar e produzir)
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: pasto com animais (cuidar e produzir)`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um pasto cercado e um galinheiro no seu lote da Story 009, com um cocho e um bebedouro (o galinheiro da Story 004 passa a ser um deles)
- [ ] O jogador compra animais (galinha, vaca e ovelha para começar, valores em dados) e eles aparecem no pasto andando, pastando e dormindo à noite
- [ ] Cada animal tem fome: o jogador enche o cocho com ração (comprada ou colhida na Story 015) uma vez por dia; animal sem comida não produz e perde a alegria
- [ ] Animais alimentados produzem ovo, leite ou lã por dia do jogo (Story 008), que aparece como item para coletar com a ação de coletar
- [ ] Os produtos vão para a bolsa ou o armazém e vendem na loja (valor em dados)
- [ ] Os animais, a fome, a alegria e os produtos pendentes são salvos
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada e uma anotação de playtest do ciclo comprar, alimentar, esperar e coletar

---

## Implementation Notes

- A lógica vai em `src/core/`, os animais em `src/world/` (movimento procedural simples, como as galinhas da Story 004), a UI em `src/ui/`; estenda `GameState`, `Economy` e `SaveGame`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Reprodução, raças, doenças, estábulo grande e cavalos: aprofundamento (Story 026)

---

## Files

- `src/core/` (animais), `src/world/` (pasto), `src/ui/` (ação e compra), `src/data/`
- `production/qa/evidence/story-016-pasto-animais/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: testes dispensados no `qa.level: minimal`; capturas de tela e uma anotação de playtest.

**Status**: [x] Created: `production/qa/evidence/story-016-pasto-animais-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-008-dia-noite-e-salvamento.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-026-aprofundar-pasto-animais.md`
