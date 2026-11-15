# Epic: Lakebound — Aventura de Pesca (migração para 3D no Godot)

> **Source**: `design/game-brief.md` (workflow minimal: o brief é o design)
> **Engine**: Godot 4.7 · GDScript · renderizador Mobile (Android)
> **Reference build**: protótipo 2D `prototypes/lakebound/` (tag `one-shot/lakebound`): regras, dados e números.

## Goal
Levar o Lakebound atual para um mundo 3D estilizado em Godot, sem perder nenhum sistema (pesca, disputa, espécies, economia, loja, energia, dia e noite, livro, níveis, salvamento).

## Scope
Features 8 a 15 do brief (etapas 1 a 8 do plano). Construção, hortas, animais e barcos jogáveis vêm depois (aparecem só como cenário).

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Base: dados e lógica do jogo no Godot | Logic | Complete | N/A |
| 002 | Esqueleto 3D: terreno, lago, câmera e pescador | Visual/Feel | Ready | N/A |
| 003 | Pesca em 3D com a barra de disputa | Integration | Ready | N/A |
| 004 | Cenário I: propriedade e vila | Visual/Feel | Ready | N/A |
| 005 | Cenário II: rio, cachoeiras, píer em L, ilhota e modelos melhores | Visual/Feel | Ready | N/A |
| 006 | HUD da referência funcionando | UI | Ready | N/A |
| 007 | Telas em 3D: loja, Livro, bolsa e subida de nível | UI | Ready | N/A |
| 008 | Dia e noite em 3D e salvamento automático ligado | Visual/Feel | Ready | N/A |
