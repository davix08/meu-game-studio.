# Story 005: Cenário II: rio, cachoeiras, píer em L, ilhota e modelos melhores

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 12`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um rio desce de uma parte alta do mapa com duas ou três cachoeiras e pedras grandes e desemboca no lago, como em `references/lakebound-3d-look.png`
- [ ] Píer de madeira em "L" com tábuas desgastadas, postes, caixote de iscas, uma vara apoiada e o barco a remo amarrado, mais um píer pequeno extra
- [ ] Ilhota com árvore, pedras, juncos e vitórias-régias
- [ ] Água melhorada: espuma e borda clara na margem, cor mais viva, ondas e brilho; rio com movimento de correnteza
- [ ] Modelos melhores: telhado de telhas, pedras arredondadas, mais variedade de árvores, arbustos e flores, grama com mais cor
- [ ] A `WorldGrid` continua respondendo "é água?" e "é funda?" (o rio conta como água rasa, o lago como antes), para a pesca da Story 003 funcionar no rio e no lago; os cardumes podem ficar só no lago
- [ ] A colisão acompanha o terreno novo (pedras grandes, píer, ilhota); o pescador não atravessa água funda nem cachoeira
- [ ] Valores de cor, tamanho e quantidades em `world_look.json`; roda a 30 fps ou mais no celular, com captura de tela guardada e sign-off

---

## Implementation Notes

- O mapa 48×34 do 2D é o ponto de partida; o rio e a elevação são acréscimos. Qualquer mudança na `WorldGrid` mantém `is_water`, `is_deep` e a escala (1 bloco = 1 m).
- A água (`water.gdshader`) já é transparente com espuma e brilho; evolua-a com cuidado para o renderizador Mobile.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 004: propriedade e vila
- Barco navegável e novas regiões: etapas futuras
- Dia e noite: Story 008

---

## Files

- `src/world/` (grade, terreno, água, props), `src/data/world_look.json`
- `production/qa/evidence/story-005-cenario-rio-pier-e-modelos-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: uma captura de tela guardada em `production/qa/evidence/story-005-cenario-rio-pier-e-modelos/` + sign-off em `production/qa/evidence/story-005-cenario-rio-pier-e-modelos-evidence.md` (não é dispensado no `qa.level: minimal`).

**Status**: [x] Created: `production/qa/evidence/story-005-cenario-rio-pier-e-modelos-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-002-esqueleto-3d.md`
- Unlocks: None
