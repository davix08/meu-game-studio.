# Story 018: Papel de prefeito da cidade (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Feature
> **Type**: UI
> **Estimate**: M
> **Build step**: thin — papel de prefeito da cidade
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: papel de prefeito da cidade`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Uma prefeitura (prédio pequeno com bandeira, no centro da vila, lote da Story 009) e um botão perto da porta que abre o painel da cidade
- [ ] O painel mostra o **nível da cidade** e a **satisfação** dos vizinhos (média de 0 a 100, calculada a partir dos pedidos entregues, da comida no restaurante e dos serviços abertos; fórmula e pesos em dados)
- [ ] O painel lista os **lotes** da cidade (Story 009) com o que cada um pode virar e o custo em moedas para construir
- [ ] Construir um lote desbloqueia o prédio dele (armazém, oficina, restaurante, campos, pasto, loja de roupas; o que já existe nas histórias 010 a 017 fica acessível pelo painel) e gasta as moedas
- [ ] Subir o nível da cidade acontece quando a satisfação passa de metas em dados e libera novos lotes e uma recompensa em moedas, com um aviso curto
- [ ] O nível, a satisfação e os lotes construídos são salvos
- [ ] Textos em `texts_pt.json`, valores em dados; captura de tela guardada do painel e da cidade antes e depois de construir um lote

---

## Implementation Notes

- A lógica vai em `src/core/` (sem desenho); a UI em `src/ui/` no mesmo estilo das telas da Story 007; estenda `GameState` e `SaveGame`.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Decisões da cidade com consequências (impostos, festas, eventos) e metas por mandato: aprofundamento (Story 028)

---

## Files

- `src/core/` (cidade), `src/ui/` (painel), `src/world/` (prefeitura), `src/data/`
- `production/qa/evidence/story-018-prefeito-cidade/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-018-prefeito-cidade/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`, `production/epics/lakebound-aventura-de-pesca/story-012-casas-vizinhos-pedidos.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-028-aprofundar-prefeito-cidade.md`
