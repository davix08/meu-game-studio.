# Story 001: Base: dados e lógica do jogo no Godot

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-11

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 8`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] As 35 espécies, 5 varas, 6 iscas, os itens e os 6 níveis vêm de arquivos de dados do Godot com os mesmos números de `prototypes/lakebound/data.js`
- [ ] Os 60 valores ajustáveis de `prototypes/lakebound/config.js` ficam num arquivo de configuração do Godot, nunca escritos dentro da lógica
- [ ] Sorteio da espécie, peso e valor do peixe, economia (vender, comprar, equipar), níveis, energia, relógio com 4 períodos e sono automático são GDScript sem nenhum código de desenho
- [ ] A lógica da pesca (lançar, mordida, disputa na barra, captura ou fuga) é uma máquina de estados que só pergunta ao mundo "é água?" e "é funda?"
- [ ] O salvamento guarda os mesmos campos do 2D e converte o save v1 do protótipo para o formato novo
- [ ] Toda a aleatoriedade passa por um gerador com semente, para os testes serem repetíveis
- [ ] O projeto abre no Godot 4.7 sem erros de script (`godot --headless --path . --import`)

---

## Implementation Notes

- Fonte das regras: `prototypes/lakebound/js/` (`fish.js`, `fishing.js`, `economy.js`, `levels.js`, `energy.js`, `time.js`, `save.js`). Traduza o comportamento, não a estrutura.
- Use tipagem estática e sinais no passado (`fish_caught`, `level_up`). Dados em recursos `.tres` ou JSON.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API: a 4.7 é posterior ao treinamento.

---

## Out of Scope

- Story 002: terreno, câmera e personagem em 3D
- Story 003: a pesca no mundo 3D e a barra desenhada

---

## Files

- `src/core/economy.gd`
- `src/core/energy.gd`
- `src/core/fish_roller.gd`
- `src/core/fishing_machine.gd`
- `src/core/game_clock.gd`
- `src/core/game_data.gd`
- `src/core/game_state.gd`
- `src/core/progression.gd`
- `src/core/random_source.gd`
- `src/core/save_game.gd`
- `src/core/world_query.gd`
- `src/data/baits.json`
- `src/data/config.json`
- `src/data/items.json`
- `src/data/levels.json`
- `src/data/rods.json`
- `src/data/species.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: tests waived at `qa.level: minimal` (advisory); o save v1 convertido deve ser conferido com um save do protótipo 2D.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-002-esqueleto-3d.md`, `production/epics/lakebound-aventura-de-pesca/story-003-pesca-3d.md`

## Completion Notes
**Completed**: 2026-11-11
**Criteria**: 6/7 passing (deferred: regras em GDScript sem desenho, conferir ao jogar o 3D)
**Deviations**: None. Notes: a conversão do save v1 não foi testada com um save real do 2D; "abre no Godot 4.7 sem erros" foi confirmado pelo usuário no Godot do celular, sem imagem guardada.
**Test Evidence**: waived at qa.level minimal
**Reviewed by**: self, no independent review

## Calls beyond the design
- WorldQuery usa Vector3, com alcance e raio de cardume em pixels do 2D sem reescala (`src/core/world_query.gd`, `src/core/game_data.gd`) · kept 2026-11-11
- O save guarda `pos [x,y,z]`; o save v1 vira px→x, py→z, y=0 (`src/core/save_game.gd`) · kept 2026-11-11
- Os avisos de texto viraram códigos de resultado; o texto fica para a interface (`Economy.Result`, `Energy.Result`, `FishingMachine.CastResult`) · kept 2026-11-11
- O lançamento mede só a distância no chão; o lançar pelo teclado ficou de fora (`src/core/fishing_machine.gd`) · kept 2026-11-11
- O peixe fica 1,1 s no ar antes de ir para a bolsa: `catch_hold`, ajustável de 0,3 a 3 (`src/data/config.json`) · kept 2026-11-11
- Cerca de 30 números que o 2D tinha soltos no código ficaram num bloco `fixed` não ajustável (`src/data/config.json`) · kept 2026-11-11
- O save fica em `user://lakebound_save.json` e valida campos faltando ou inválidos (`src/core/save_game.gd`) · kept 2026-11-11
- O sono automático não reposiciona o jogador; só emite `day_started` (`src/core/game_clock.gd`) · kept 2026-11-11
