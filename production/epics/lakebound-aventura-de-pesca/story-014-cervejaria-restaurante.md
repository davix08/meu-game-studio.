# Story 014: Cervejaria-restaurante (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: thin — cervejaria-restaurante
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: cervejaria-restaurante`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um prédio de cervejaria-restaurante (barris, mesas na frente, chaminé com fumaça) no seu lote da Story 009
- [ ] Os vizinhos da Story 013 chegam lá nos horários de comer e beber, sentam nas mesas, consomem e saem
- [ ] O jogador abre a tela do restaurante perto do balcão e entrega peixes do depósito ou da bolsa para virar pratos (receita simples por espécie, valor em dados); os pratos ficam à venda
- [ ] Os vizinhos compram pratos e bebidas; cada compra dá moedas ao jogador e tira do estoque do restaurante
- [ ] A tela mostra estoque, preços e as moedas ganhas no dia
- [ ] O estoque e as vendas do dia são salvos
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada e uma anotação de playtest do ciclo (entregar peixe, vizinhos comem, moedas entram)

---

## Implementation Notes

- A lógica de estoque, pratos e vendas vai em `src/core/`; as telas em `src/ui/`; reaproveite `Economy` e `GameState`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Cardápio grande, qualidade e fama do restaurante, eventos: aprofundamento (Story 024)

---

## Files

- `src/core/` (restaurante), `src/ui/` (tela), `src/world/` (prédio e mesas), `src/data/`
- `production/qa/evidence/story-014-cervejaria-restaurante/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: testes dispensados no `qa.level: minimal`; capturas de tela e uma anotação de playtest.

**Status**: [x] Created: `production/qa/evidence/story-014-cervejaria-restaurante-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-013-vizinhos-rotina.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-024-aprofundar-cervejaria-restaurante.md`
