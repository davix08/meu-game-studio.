# Story 017: Loja de roupas (versão simples)

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Build step**: thin — loja de roupas
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief Your systems: loja de roupas`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Um prédio de loja de roupas (vitrine com manequins e varal na lateral, no lugar da tecelaria da referência) no seu lote da Story 009
- [ ] Perto da porta, um botão abre a tela da loja; longe, o aviso diz para chegar mais perto
- [ ] A tela mostra o pescador em um visor 3D girando e permite experimentar chapéus (3), camisas (3) e botas (2), com preço em dados
- [ ] Comprar com moedas desbloqueia a peça; equipar muda o visual do pescador no jogo na hora (cores e peças do `Fisherman`)
- [ ] A roupa é só visual: nenhuma peça muda a pesca nesta versão
- [ ] As peças compradas e as equipadas são salvas
- [ ] Textos em `texts_pt.json`; captura de tela guardada de cada tela tocada e do pescador com roupa nova

---

## Implementation Notes

- O visor pode reaproveitar o modelo do `Fisherman` num `SubViewport`; as peças são trocas de cor e de pequenas malhas no modelo.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Roupas com efeito na pesca, conjuntos e roupas de NPCs: aprofundamento (Story 027)

---

## Files

- `src/ui/` (tela), `src/player/fisherman.gd`, `src/world/` (prédio), `src/core/` (peças), `src/data/`
- `production/qa/evidence/story-017-loja-roupas/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-017-loja-roupas/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-007-telas-loja-livro-bolsa.md`, `production/epics/lakebound-aventura-de-pesca/story-009-mapa-maior-vila.md`
- Unlocks: `production/epics/lakebound-aventura-de-pesca/story-027-aprofundar-loja-roupas.md`
