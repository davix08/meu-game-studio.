# Story 010: Armazém (depósito) (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Build step**: thin — armazém (depósito)
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: armazém (depósito)`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um prédio de armazém no seu lote (Story 009), com porta e galpão de madeira, no estilo da referência
- [ ] Perto da porta, um botão abre a tela do armazém (como a loja da Story 007); longe, o aviso diz para chegar mais perto
- [ ] A tela mostra a bolsa e o depósito lado a lado; tocar em um peixe move entre os dois (`GameState`)
- [ ] O depósito tem capacidade inicial maior que a bolsa (valor em dados) e pode ser ampliado com moedas
- [ ] Peixes no depósito entram no valor para vender e nos pedidos, e saem do depósito ao serem vendidos ou entregues
- [ ] O salvamento guarda o conteúdo e a capacidade do depósito
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada de cada tela tocada

---

## Implementation Notes

- A lógica do depósito vai em `src/core/` (sem desenho), com a tela em `src/ui/`; reaproveite `GameState` e `SaveGame` (versão do formato sobe).
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Melhorias avançadas, categorias e filtros: aprofundamento (Story 020)

---

## Files

- `src/core/` (depósito), `src/ui/` (tela), `src/world/` (prédio), `src/data/`
- `production/qa/evidence/story-010-armazem/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-010-armazem/`.

**Status**: [x] Created: `production/qa/evidence/story-010-armazem-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-007-telas-loja-livro-bolsa.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-020-aprofundar-armazem.md`
