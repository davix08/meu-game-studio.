# Story 002: Esqueleto 3D: terreno, lago, câmera e pescador

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-15

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

- `project.godot`
- `scenes/main.tscn`
- `src/data/world_look.json`
- `src/player/fisherman.gd`
- `src/ui/hud.gd`
- `src/ui/virtual_stick.gd`
- `src/world/follow_camera.gd`
- `src/world/lake_main.gd`
- `src/world/lake_props.gd`
- `src/world/lake_terrain.gd`
- `src/world/lake_water.gd`
- `src/world/lake_world.gd`
- `src/world/lake_world_query.gd`
- `src/world/mesh_builder.gd`
- `src/world/prop_meshes.gd`
- `src/world/water.gdshader`
- `src/world/world_grid.gd`
- `src/world/world_look.gd`

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

## Completion Notes
**Completed**: 2026-11-15
**Criteria**: 7/7 passing
**Deviations**: ADVISORY, accepted by the user — own `VirtualStick` (src/ui/virtual_stick.gd) instead of the Godot 4.7 `VirtualJoystick` node named in the criterion. Notes: deep-water sparkle shows a regular dot grid (Story 005); the fisherman reads small at camera size 14 (accepted).
**Test Evidence**: production/qa/evidence/story-002-esqueleto-3d/02-camera-isometrica-pescador-novo.jpg; sign-off production/qa/evidence/story-002-esqueleto-3d-evidence.md
**Reviewed by**: self, no independent review

## Calls beyond the design
- Camera: isometric orthographic, size 14 m, pitch 35.264°, yaw 45°, distance 30, near 1, far 90, smoothing 6, edge margins 12/12/10/10 (`src/data/world_look.json` camera) · kept 2026-11-15
- Input rotated by the camera yaw for keyboard and joystick (`src/world/lake_main.gd`) · kept 2026-11-15
- 1 block = 1 m; WorldQuery positions in 2D pixels (×16, `to_query_pos`) (`src/world/lake_world_query.gd`, `world_grid.gd`) · kept 2026-11-15
- Feet box centred 0.25 × 0.16 m; walk 3.25 m/s and run 5.5 m/s from config.json; run with Shift or the stick at ≥ 0.95 (`world_grid.gd`, `lake_main.gd`, `world_look.json`) · kept 2026-11-15
- Fisherman ~1.30 m, head ~40%, after references/pescador-design-*.png: grey beard, dark curly hair, straw hat with red band, red vest over cream shirt, belt with gold buckle, jeans, brown boots, backpack; head/hat sway 4° (`src/player/fisherman.gd`, `world_look.json` player/colors) · kept 2026-11-15
- Warm late-afternoon light #ffd9a0 1.35, procedural sky, fog #f4d3a0 0.006, MSAA 2×, saturated palette, vertex colours as sRGB (`src/world/lake_world.gd`, `mesh_builder.gd`, `world_look.json`) · kept 2026-11-15
- Terrain relief ±0.12, water at −0.1, lake beds −0.38/−1.0, skirt strips outside the map; water shader `water.gdshader` (`src/world/lake_terrain.gd`, `lake_water.gd`) · kept 2026-11-15
- Extras: pier lantern, rowboat, chimney smoke; no fences (`src/world/prop_meshes.gd`, `lake_world.gd`) · kept 2026-11-15
- Joystick radius 100, dead zone 0.15; HUD with region and FPS only (`src/ui/virtual_stick.gd`, `hud.gd`) · kept 2026-11-15
