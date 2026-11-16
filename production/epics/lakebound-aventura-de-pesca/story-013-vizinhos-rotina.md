# Story 013: Vizinhos (NPCs) com rotina (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: thin — vizinhos (NPCs) com rotina: comer, beber e comprar
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: vizinhos (NPCs) com rotina: comer, beber e comprar`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Os vizinhos da Story 012 viram personagens 3D (formas simples e coloridas no estilo do pescador, cada um com cores e chapéu diferentes) que andam pela cidade
- [ ] Cada vizinho segue uma rotina por horário do relógio do jogo (Story 008): acorda em casa, vai ao restaurante para comer, passa pela loja para comprar, volta para casa à noite (horários em dados)
- [ ] Andam pelos caminhos de terra, desviam de obstáculos e não atravessam construções (caminhos pré-calculados na grade ou navegação simples)
- [ ] Ao chegar a um destino tocam uma animação curta (sentar, comer, comprar) e voltam a andar
- [ ] Tocar em um vizinho na rua abre o diálogo da Story 012 se ele tiver pedido
- [ ] A posição e a etapa da rotina de cada vizinho são salvas
- [ ] Até 6 NPCs andando juntos mantêm 30 fps ou mais no celular, com captura de tela guardada e sign-off

---

## Implementation Notes

- A rotina é uma lista de (hora, destino) em dados; a lógica em `src/core/`, o desenho em `src/world/`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API (navegação: prefira a grade lógica já existente).

---

## Out of Scope

- O que acontece dentro do restaurante e da loja: Story 014; personalidades, humor e diálogos ricos: aprofundamento (Story 023)

---

## Files

- `src/core/` (rotina), `src/world/` (NPCs), `src/data/`
- `production/qa/evidence/story-013-vizinhos-rotina-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: testes dispensados no `qa.level: minimal`; capturas de tela e uma anotação de playtest (ver os vizinhos seguirem a rotina durante um dia).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-008-dia-noite-e-salvamento.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`, `production/epics/lakebound-aventura-de-pesca/story-012-casas-vizinhos-pedidos.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-014-cervejaria-restaurante.md`, `production/epics/lakebound-aventura-de-pesca/story-023-aprofundar-vizinhos-rotina.md`
