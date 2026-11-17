# Story 011: Oficina de melhoria de varas (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Build step**: thin — oficina de melhoria de varas
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: oficina de melhoria de varas`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um prédio de oficina (bancada, bigorna e ferramentas, com fumaça, no lugar da ferraria da referência) no seu lote da Story 009
- [ ] Perto da porta, um botão abre a tela da oficina; longe, o aviso diz para chegar mais perto
- [ ] A tela mostra a vara equipada e permite melhorá-la em 3 níveis por moedas: cada nível aumenta alcance, zona verde e força (valores em dados)
- [ ] A vara melhorada vale na pesca (`rods.json` + nível guardado) e o `FishingMachine` usa os valores novos
- [ ] O custo e o nível máximo aparecem na tela; sem moedas, o botão fica desativado com o motivo
- [ ] O nível de cada vara é salvo e volta ao abrir o jogo
- [ ] Textos em `texts_pt.json`; captura de tela guardada de cada tela tocada

---

## Implementation Notes

- Estenda `Rod` em `GameData` e o `GameState` (nível por vara); a pesca já lê alcance, zona e força da vara.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Materiais, encantamentos e consertos: aprofundamento (Story 021)

---

## Files

- `src/core/` (níveis de vara), `src/ui/` (tela), `src/world/` (prédio), `src/data/`
- `production/qa/evidence/story-011-oficina-varas/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-011-oficina-varas/`.

**Status**: [x] Created: `production/qa/evidence/story-011-oficina-varas-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-007-telas-loja-livro-bolsa.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-021-aprofundar-oficina.md`
