# Story 002: Esqueleto 3D: terreno, lago, câmera e pescador

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Progress
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-11

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 9`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] O mapa do Lago Esmeralda (grade lógica de 48×34 do 2D) vira um terreno 3D: grama, caminhos de terra, areia, lago com água, duas ilhas, píer de madeira, ponte e a casa de pesca, tudo estilizado e colorido, sem pixel art
- [ ] Árvores, pedras, flores e arbustos repetidos em lote (instâncias), para rodar bem em celular intermediário
- [ ] Câmera superior inclinada em perspectiva, seguindo o pescador e adequada a telas pequenas na horizontal
- [ ] Um pescador 3D com animações de parado, andar e correr
- [ ] Joystick virtual (`VirtualJoystick`) move o pescador; teclado funciona para testes
- [ ] Colisão impede atravessar árvores, casa, água funda e obstáculos, com a grade lógica respondendo "é sólido?" e "é água?"
- [ ] Rodando no Godot a 30 fps ou mais, com captura de tela guardada em `production/qa/evidence/`

---

## Implementation Notes

- Mantenha uma grade lógica por baixo do 3D: é ela que a Story 001 e a pesca consultam.
- Renderizador Mobile, uma luz direcional, neblina para o horizonte, sombras leves. Meta: ~300 draw calls, 1 GB.
- Modelos simples gerados em código ou pacotes CC0 salvos em `assets/`, com entrada em `assets/provenance.yaml`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 003: pesca e a barra de disputa
- Dia e noite 3D, propriedade, lojas, construção e personagem com todas as animações de pesca: etapas seguintes do plano

---

## Files

- `src/world/` (terreno, câmera), `src/player/` (pescador, joystick), `scenes/` (`main.tscn`, `world.tscn`)
- `production/qa/evidence/story-002-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: uma captura de tela guardada em `production/qa/evidence/` + sign-off em `production/qa/evidence/story-002-evidence.md` (não é dispensado no `qa.level: minimal`).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-001-base-dados-e-logica.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-003-pesca-3d.md`
