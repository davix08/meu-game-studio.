# Story 012: Casas dos vizinhos e pedidos de peixe (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: thin — casas dos vizinhos e pedidos de peixe
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: casas dos vizinhos e pedidos de peixe`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Três casas de vizinhos (estilo de fazenda moderna aconchegante, cada uma diferente) nos lotes da Story 009, com porta e caixa de correio
- [ ] Cada vizinho tem nome, rosto simples no diálogo e um pedido de peixe por vez (espécie e quantidade vindas dos dados, só espécies já liberadas pelo nível)
- [ ] Perto da porta, um botão abre um diálogo curto com o pedido, a recompensa e o botão Entregar
- [ ] Entregar tira os peixes da bolsa ou do armazém (se existir), dá moedas e uma isca, e o vizinho dá o próximo pedido no dia seguinte
- [ ] Sem os peixes, o botão Entregar fica desativado com o motivo; o pedido pendente aparece num marcador acima da casa
- [ ] Os pedidos e o progresso de cada vizinho são salvos
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada do diálogo e do marcador

---

## Implementation Notes

- A lógica dos pedidos vai em `src/core/` (sem desenho), a UI em `src/ui/`; reaproveite `GameState`, `Economy` e `SaveGame`.
- O relógio de dias vem da Story 008.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Os vizinhos andando pela cidade: Story 013; pedidos longos, cadeias e amizade: aprofundamento (Story 022)

---

## Files

- `src/core/` (pedidos), `src/ui/` (diálogo), `src/world/` (casas), `src/data/`
- `production/qa/evidence/story-012-casas-vizinhos-pedidos/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: testes dispensados no `qa.level: minimal`; uma anotação curta de playtest (receber o pedido, pescar, entregar, ver a recompensa e o pedido novo no dia seguinte) e capturas de tela.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-007-telas-loja-livro-bolsa.md`, `production/epics/lakebound-aventura-de-pesca/story-008-dia-noite-e-salvamento.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-013-vizinhos-rotina.md`, `production/epics/lakebound-aventura-de-pesca/story-018-prefeito-cidade.md`, `production/epics/lakebound-aventura-de-pesca/story-022-aprofundar-casas-vizinhos.md`
