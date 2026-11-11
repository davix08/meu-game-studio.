# Story 003: Pesca em 3D com a barra de disputa

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

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

- `src/fishing/` (raycast, boia, linha), `src/ui/` (barra de disputa, HUD, botões)
- `tests/integration/lakebound/` (ou um roteiro de playtest)

---

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
