# Story 008: Dia e noite em 3D e salvamento automático ligado

> **Epic**: Lakebound — Aventura de Pesca (migração para 3D no Godot)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 15`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] O relógio do `GameClock` roda na cena (1 hora de jogo = 30 s, o descanso acelera) e o jogo começa de manhã, às 6h
- [ ] O sol (luz direcional) muda de posição, cor e energia nos 4 períodos (manhã, tarde, noite, madrugada); céu e neblina acompanham, com o fim de tarde quente da referência
- [ ] À noite o cenário escurece em azul, as janelas das casas e o poste do píer acendem e aparecem vaga-lumes; o pescador continua visível
- [ ] Ao chegar ao horário limite o pescador dorme sozinho: tela de sono, novo dia, energia cheia (`GameClock.sleep_new_day`, sinal `day_started`)
- [ ] O salvamento automático chama `SaveGame.write` no intervalo de `autosave_seconds` e nos eventos principais (captura, venda, compra, dormir, sair do jogo), e ao abrir o jogo o progresso volta
- [ ] A tela inicial oferece Continuar (quando existe save) e Novo jogo (com confirmação); o save do protótipo 2D é convertido (`SaveGame.convert_v1`)
- [ ] Valores de cor, intensidade e horários em dados; roda a 30 fps ou mais no celular, com captura de tela guardada de dia, noite e da tela inicial, e sign-off

---

## Implementation Notes

- A lógica de relógio e salvamento está na Story 001; o 2D de referência é `prototypes/lakebound/js/time.js` (`lightAt`) e `save.js`.
- Mantenha poucas luzes com sombra (uma direcional); as luzes das janelas podem ser emissivas ou OmniLight3D sem sombra, no limite do celular.
- Consulte `docs/engine-reference/godot/` antes de usar qualquer API.

---

## Out of Scope

- Story 006: o HUD (o relógio e o sol já aparecem lá)
- Clima, estações e eventos de época: futuro

---

## Files

- `src/world/` (iluminação, ciclo), `src/core/` somente leitura, `src/ui/` (tela inicial), `src/data/`
- `production/qa/evidence/story-008-dia-noite-e-salvamento-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas de tela guardadas (dia, noite, tela inicial) em `production/qa/evidence/story-008-dia-noite-e-salvamento/` + sign-off em `production/qa/evidence/story-008-dia-noite-e-salvamento-evidence.md` (não é dispensado no `qa.level: minimal`).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/lakebound-aventura-de-pesca/story-006-hud-da-referencia.md`
- Unlocks: None
