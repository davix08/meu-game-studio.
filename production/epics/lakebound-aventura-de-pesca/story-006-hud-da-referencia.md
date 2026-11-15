# Story 006: HUD da referência funcionando

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 13`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] No topo, no estilo de `references/lakebound-3d-look.png`: nível com estrela e barra de espécies até o próximo nível (ex.: 3/5), moedas, energia (barra e porcentagem), sol com dia e hora e período, e a engrenagem de ajustes
- [ ] Os valores vêm do `GameState` (moedas, nível, espécies descobertas, energia, dia e relógio do `GameClock`) e se atualizam pelos sinais (`coins_changed`, `energy_changed`, `level_up`, `day_started`)
- [ ] Embaixo à direita: botão grande de pescar (vara com boia) que lança, recolhe e puxa conforme o estado da pesca (a mesma lógica do PUXAR da Story 003), mais mochila, Descansar, Livro e Loja
- [ ] Descansar liga e desliga o descanso (`Energy.toggle_rest`); a mochila abre a bolsa com os peixes e o valor estimado; Livro e Loja abrem as telas da Story 007 (e a Loja só funciona perto da loja de pesca, com o aviso claro quando está longe)
- [ ] A engrenagem abre ajustes com som ligado/desligado, Continuar e Novo jogo; nenhum botão decorativo, e sem os botões "+" de dinheiro real
- [ ] O joystick (já existente) fica no canto inferior esquerdo e nenhum botão cobre o joystick nem a ação principal
- [ ] Alvos de toque grandes o bastante para polegar, texto legível, tela horizontal de celular; valores de tamanho e cor em dados
- [ ] Captura de tela guardada de cada tela tocada (topo, base, bolsa, ajustes)

---

## Implementation Notes

- Reaproveite o `GameState` e os sistemas de `src/core/` (Story 001); a UI só mostra e chama, sem regra de jogo dentro.
- O HUD é uma camada 2D (`CanvasLayer`) por cima do 3D; o `Hud` atual (região e FPS) é o ponto de partida; mantenha o FPS como opção de ajuste.
- Textos em português; o projeto pede localização: use um arquivo de textos em vez de literais, se existir, ou registre a decisão.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 007: telas completas de loja, Livro, subida de nível e cartão de captura
- Story 008: dia e noite 3D e salvamento
- Compras com dinheiro real (fora do escopo no brief)

---

## Files

- `src/ui/` (HUD, botões, bolsa, ajustes), `scenes/` se precisar, `src/data/` para os dados de layout
- `production/qa/evidence/story-006-hud-da-referencia/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-006-hud-da-referencia/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-003-pesca-3d.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-007-telas-loja-livro-bolsa.md`, `production/epics/lakebound-aventura-de-pesca/story-008-dia-noite-e-salvamento.md`
