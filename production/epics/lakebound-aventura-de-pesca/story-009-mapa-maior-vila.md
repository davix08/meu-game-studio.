# Story 009: Mapa maior com a vila ao redor do lago (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: thin — mapa maior com a vila ao redor do lago
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: mapa maior com a vila ao redor do lago`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] O mapa cresce (ex.: de 48×34 para cerca de 96×68 blocos) e o Lago Esmeralda continua no centro, com o píer, a ponte e a propriedade atuais no lugar
- [ ] Ao redor do lago aparecem áreas como em `references/vila-referencia.jpg`, já com chão e caminhos de terra: centro da vila, campos, pasto, floresta, rio com ponte
- [ ] Cada prédio futuro tem um **lote** marcado e livre (armazém, oficina, casas dos vizinhos, restaurante, campos, pasto, loja de roupas, prefeitura), ligado por caminhos
- [ ] Layout da propriedade ajustado (moinho fora da frente da varanda, loja separada da casa) e a `WorldGrid` continua respondendo "é sólido?", "é água?" e "é funda?"
- [ ] A câmera segue o pescador nos limites do mapa maior sem mostrar o vazio
- [ ] Só desenha e processa o que está perto (cortes por distância ou por região), com 30 fps ou mais no celular
- [ ] Posições, tamanhos e lotes em dados (`world_look.json`); o salvamento guarda a posição do pescador no mapa novo
- [ ] Captura de tela guardada e sign-off

---

## Implementation Notes

- Parte da `WorldGrid` e do `LakeWorld` da Story 002 e da propriedade da 004. A Story 005 (rio e píer) vem antes.
- Mantenha a escala 1 bloco = 1 m e a conversão para px (×16) do `WorldQuery`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Funcionamento de cada prédio: histórias 010 a 018
- Dia e noite: Story 008

---

## Files

- `src/world/` (grade, terreno, props, câmera), `src/data/world_look.json`
- `production/qa/evidence/story-009-mapa-maior-vila-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: uma captura de tela guardada em `production/qa/evidence/story-009-mapa-maior-vila/` + sign-off em `production/qa/evidence/story-009-mapa-maior-vila-evidence.md`.

**Status**: [x] Created: `production/qa/evidence/story-009-mapa-maior-vila-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-005-cenario-rio-pier-e-modelos.md`
- Unlocks: stories 010 a 018
