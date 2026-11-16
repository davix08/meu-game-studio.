# Story 003: Pesca em 3D com a barra de disputa

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-15

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 10`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Tocar na água (um raio da tela até o ponto 3D) lança a linha, dentro do alcance da vara equipada, gastando energia
- [ ] A boia cai em arco, boia na água, tem as beliscadas falsas, e a mordida mostra um aviso na tela
- [ ] O botão PUXAR segurado controla a disputa: indicador com física, zona verde que anda e dá trancos conforme a dificuldade do peixe, progresso até 100%
- [ ] Peixe capturado entra na bolsa e no Livro de Peixes com peso e valor; a tela de "nova espécie" aparece
- [ ] Sem reagir a tempo, ou perdendo o controle da disputa, o peixe escapa
- [ ] Peixes aparecem nadando na água 3D e a água funda e os cardumes mudam o sorteio como no 2D
- [ ] Barra de disputa, botões e HUD desenhados por cima do 3D, em tela horizontal de celular
- [ ] Os números de dificuldade, odds e energia são os da Story 001, sem valores novos escritos na lógica

---

## Implementation Notes

- Reaproveite a máquina de estados da pesca da Story 001; aqui só ligamos o mundo 3D (raycast, boia, linha) e a interface.
- Referência de sensação: `prototypes/lakebound/js/fishing.js` e `ui.js` (`drawFishingUI`).
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Loja 3D, Livro em tela cheia, dia e noite 3D, personagem com todas as animações de pesca: etapas seguintes do plano

---

## Files

- `src/data/texts_pt.json`
- `src/data/world_look.json`
- `src/fishing/fishing_view.gd`
- `src/fishing/water_life.gd`
- `src/player/fisherman.gd`
- `src/ui/fishing_hud.gd`
- `src/ui/pull_button.gd`
- `src/world/lake_main.gd`
- `src/world/lake_world_query.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: tests waived at `qa.level: minimal` (advisory); um playtest curto do fluxo lançar → mordida → disputa → captura, anotado.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-001-base-dados-e-logica.md`, `production/epics/lakebound-aventura-de-pesca/story-002-esqueleto-3d.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-15
**Criteria**: 8/8 passing
**Deviations**: None. Note: the "TRANCO!" warning is inferred from the zone speed because the core exposes no dart flag; it may flash slightly off.
**Test Evidence**: integration test waived at qa.level minimal; screenshots in production/qa/evidence/story-003-pesca-3d/ (01-parado-antes-de-lancar.jpg, 02-disputa-barra-zona-verde.jpg, 03-cartao-nova-especie-sardinha.jpg); playtest note from the user (cast, bite, fight, catch, escape, swimming fish and schools worked; touching the joystick or PUXAR did not cast)
**Reviewed by**: self, no independent review

## Calls beyond the design
- Fishing visuals: bobber arc 2.2 m and radius 0.11, "!" at 2.1 m in #ffd23a, rod 1.6 m in the equipped rod's colour, pose angles, held fish at 1.75 m as an ellipsoid in the rarity colour (`src/data/world_look.json` fishing, `src/fishing/fishing_view.gd`, `src/player/fisherman.gd`) · kept 2026-11-15
- Fish shadows #06203a70, 0.9 × 0.32 m, 5 cm under the water; school ring and bubbles; shadow movement copied from the 2D (`src/fishing/water_life.gd`, `world_look.json`) · kept 2026-11-15
- UI on a 1280×720 base copied from the 2D: fight bar top-centre 700×44 at y 206, bite alert y 190, short notices y 620, PUXAR button radius 84 bottom-right (`src/ui/fishing_hud.gd`, `src/ui/pull_button.gd`, `world_look.json`) · kept 2026-11-15
- Simple catch card without a fish icon; level-up as a short notice only (the polished screens are Story 007) (`src/ui/fishing_hud.gd`) · kept 2026-11-15
- "TRANCO!" inferred from the zone speed (`src/ui/fishing_hud.gd` on_fight_step) · kept 2026-11-15
- Provisional energy bar, "Bolsa N/20 · Livro N/35" and Descansar button (Z on PC) until Story 006 (`src/ui/fishing_hud.gd`) · kept 2026-11-15
- Space casts to the farthest water within range; PUXAR while waiting counts as pulled early (label "RECOLHER"); only a real mouse click casts, a touch casts once (`src/world/lake_main.gd`) · kept 2026-11-15
- All game texts in `src/data/texts_pt.json`; a fresh GameState each run until Story 008 (`src/world/lake_main.gd`) · kept 2026-11-15
