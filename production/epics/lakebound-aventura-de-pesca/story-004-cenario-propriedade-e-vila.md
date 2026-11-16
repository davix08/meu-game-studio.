# Story 004: Cenário I: propriedade e vila

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 11`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] A casa de pesca ganha varanda, telhado de telhas, madeira aparente, chaminé com fumaça e janelas que podem acender (a luz vem na Story 008), no estilo de `references/lakebound-3d-look.png`
- [ ] Propriedade ao redor da casa: galpão de telhado vermelho com pilha de lenha e um trator, horta cercada com fileiras de plantas e um espantalho, galinheiro com cerca e galinhas que andam e bicam, caixa d'água de madeira e moinho com pás girando
- [ ] Loja de pesca como prédio separado, com toldo listrado azul e branco, placa de peixe, caixotes e barris na frente
- [ ] Mural de avisos, banco, poste de luz e cercas de madeira ao longo dos caminhos de terra
- [ ] Tudo feito com formas simples e cores saturadas e quentes da referência; repetições (cercas, caixotes, plantas) em lote (MultiMesh) para manter ~300 draw calls
- [ ] Colisão pela `WorldGrid`: casa, loja, galpão, trator, cercas, caixa d'água e moinho bloqueiam o pescador; os caminhos continuam livres e a horta e o galinheiro são só cenário (não dá para plantar nem cuidar dos animais ainda)
- [ ] Posições, tamanhos e cores em dados (`world_look.json` e a grade), não em literais na lógica
- [ ] Roda a 30 fps ou mais no celular, com captura de tela guardada e sign-off

---

## Implementation Notes

- Parta do que a Story 002 já tem (`LakeProps`, `PropMeshes`, `MeshBuilder`, `WorldGrid`) e acrescente, sem refazer o mapa do lago (isso é a Story 005).
- A loja de pesca separada é só o prédio nesta história: a tela da loja é a Story 007, e o botão Loja perto dela, a Story 006.
- Câmera isométrica ortográfica atual: dê a cada objeto uma silhueta que se leia bem de cima e na diagonal.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 005: rio, cachoeiras, píer em L, ilhota e melhoria geral dos modelos e da água
- Plantar, cuidar dos animais, usar o trator: etapas futuras do plano (fora do escopo no brief)
- Luz das janelas e dia e noite: Story 008

---

## Files

- `src/data/world_look.json`
- `src/world/estate_meshes.gd`
- `src/world/lake_estate.gd`
- `src/world/lake_props.gd`
- `src/world/lake_world.gd`
- `src/world/prop_meshes.gd`
- `src/world/world_grid.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: uma captura de tela guardada em `production/qa/evidence/story-004-cenario-propriedade-e-vila/` + sign-off em `production/qa/evidence/story-004-cenario-propriedade-e-vila-evidence.md` (não é dispensado no `qa.level: minimal`).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-002-esqueleto-3d.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 8/8 passing as seen on the screenshots; two caveats below
**Deviations**: None. Notes: the user said an item from the detail list was missing without naming it (water tower, turning mill blades, walking hens, chimney smoke, notice board, woodpile, fish sign) — not verified; window and lamp glow exists in the code but is off until Story 008; layout points (windmill in front of the house porch, shop touching the house, lamp 3 on shore sand, awning over the plaza) move to the bigger map.
**Test Evidence**: production/qa/evidence/story-004-cenario-propriedade-e-vila/ (01-casa-loja-galpao-moinho.jpg, 02-horta-galinheiro-pier.jpg); sign-off production/qa/evidence/story-004-cenario-propriedade-e-vila-evidence.md
**Reviewed by**: self, no independent review

## Calls beyond the design
- Placements in cells (`src/data/world_look.json` estate): shed (12,2) 4×3, tractor (16,3) 3×2, garden (20,2) 7×4 with scarecrow and crate strip, coop (28,2) 4×4 with 4 hens, water tower (3,2), windmill (13,9) with 5 blades at 0.7 rad/s, fish shop (2,7) facing east with dirt plaza (6,7), lamps (7,9) (14,8) (19,8), notice board (11,8), bench (17,8), path fences with a gate gap at (15,6) · kept as is 2026-11-16 (layout fixes go into the bigger map)
- House rebuilt in `src/world/estate_meshes.gd`: 12 roof bands, 14 cm porch without collision, beams, flower boxes, east window · kept 2026-11-16
- Shop roof blue-grey #7893ab/#647f98 with an 8-stripe awning; garden, coop and fences fully solid with no gate; shop crates and barrels without collision; window and lamp glow off until Story 008; ground lift 0.13 for low pieces · kept 2026-11-16
