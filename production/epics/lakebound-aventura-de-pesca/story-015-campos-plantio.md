# Story 015: Campos de plantio (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: thin — campos de plantio (plantar e colher)
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: campos de plantio (plantar e colher)`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Campos cercados nos lotes da Story 009, com canteiros marcados (a horta da Story 004 passa a ser um deles)
- [ ] O jogador compra sementes (2 tipos para começar: legume e trigo, valores em dados) e planta em um canteiro vazio perto dele (botão de ação com o canteiro mais próximo destacado)
- [ ] Cada planta cresce por dias do jogo (relógio da Story 008) em estágios visíveis (broto, crescendo, madura) e precisa de água: regar é uma ação e planta sem água para de crescer
- [ ] Colher uma planta madura dá a colheita para a bolsa ou o armazém; colher gasta energia
- [ ] A colheita pode ser vendida na loja (valor em dados) ou usada como isca (melhora a pesca como as iscas da loja)
- [ ] O estágio, a água e os dias de cada canteiro são salvos
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada dos três estágios e uma anotação de playtest do ciclo plantar, regar, esperar e colher

---

## Implementation Notes

- A lógica dos canteiros vai em `src/core/` (sem desenho), a visualização em `src/world/` (MultiMesh por estágio), a UI em `src/ui/`; estenda `GameState`, `Economy` e `SaveGame`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Muitas culturas, estações, pragas e fertilizante: aprofundamento (Story 025); o moinho que vira farinha: aprofundamento

---

## Files

- `src/core/` (plantio), `src/world/` (campos), `src/ui/` (ação e sementes), `src/data/`
- `production/qa/evidence/story-015-campos-plantio/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: testes dispensados no `qa.level: minimal`; capturas de tela e uma anotação de playtest.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-008-dia-noite-e-salvamento.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-025-aprofundar-campos-plantio.md`
