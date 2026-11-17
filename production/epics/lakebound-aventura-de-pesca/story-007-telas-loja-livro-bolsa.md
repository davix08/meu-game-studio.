# Story 007: Telas em 3D: loja, Livro, bolsa e subida de nível

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: In Review (built 2026-11-17; awaiting phone playtest and /story-done)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 14`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Loja com abas Vender, Varas, Iscas e Itens: vender toda a bolsa (valor pela raridade e pelo peso), comprar e equipar as 5 varas e as 6 iscas, comprar lanche e isca da sorte, tudo liberado por nível e pelas moedas (`Economy`)
- [ ] Livro de Peixes com as 35 espécies: ilustração (ícone do peixe), nome, raridade, maior peso e capturas; as não descobertas aparecem como silhueta ou interrogação; contador "N/35 descobertos"
- [ ] Bolsa com os peixes guardados, o peso e o valor de cada um e o total
- [ ] Tela de subida de nível: título do nível, novas espécies liberadas, itens liberados na loja e a recompensa em moedas (`Progression`, sinal `level_up`)
- [ ] Cartão de captura ("nova espécie", "novo recorde") ao pescar, com nome, raridade, peso e valor
- [ ] Os ícones dos peixes, varas e iscas são desenhados para o 3D (imagens geradas em código ou nas cores do jogo), sem emoji; um peixe por espécie, reconhecível, com a raridade em cor
- [ ] Todas as telas funcionam por toque em tela horizontal de celular, com botões grandes, rolagem onde precisar, e fecham sem perder o estado; valores de layout em dados
- [ ] Captura de tela guardada de cada tela tocada

---

## Implementation Notes

- A lógica já existe na Story 001 (`Economy`, `Progression`, `GameState`, dados em `src/data/`); aqui é só a interface.
- Referência de conteúdo e fluxo: `prototypes/lakebound/js/ui.js` (`drawShop`, `drawBook`, `drawLevelUp`, `drawCatch`) e `prototypes/lakebound/js/art.js` (os desenhos dos 35 peixes, que podem virar texturas ou malhas nesta história).
- Estilo visual de `references/lakebound-3d-look.png`: painéis com cantos arredondados, cores quentes.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 006: o HUD e os botões que abrem estas telas
- Compras com dinheiro real (fora do escopo no brief)

---

## Files

- `src/ui/` (telas de loja, Livro, bolsa, subida de nível, cartão de captura, ícones), `src/data/`
- `production/qa/evidence/story-007-telas-loja-livro-bolsa/` (capturas)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: uma captura de tela guardada de cada tela tocada, em `production/qa/evidence/story-007-telas-loja-livro-bolsa/`.

**Status**: [x] Created: `production/qa/evidence/story-007-telas-loja-livro-bolsa-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-003-pesca-3d.md`, `production/epics/lakebound-aventura-de-pesca/story-006-hud-da-referencia.md`
- Unlocks: None
