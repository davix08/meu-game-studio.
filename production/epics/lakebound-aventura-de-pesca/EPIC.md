# Epic: Lakebound — Aventura de Pesca (migração para 3D no Godot)

> **Source**: `design/game-brief.md` (workflow minimal: o brief é o design)
> **Engine**: Godot 4.7 · GDScript · renderizador Mobile (Android)
> **Reference build**: protótipo 2D `prototypes/lakebound/` (tag `one-shot/lakebound`): regras, dados e números.

## Goal
Levar o Lakebound atual para um mundo 3D estilizado em Godot, sem perder nenhum sistema (pesca, disputa, espécies, economia, loja, energia, dia e noite, livro, níveis, salvamento).

## Scope
Features 8 a 10 do brief (etapas 1 a 3 do plano). Propriedade, construção, hortas, animais e barcos vêm depois.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Base: dados e lógica do jogo no Godot | Logic | Ready | N/A |
| 002 | Esqueleto 3D: terreno, lago, câmera e pescador | Visual/Feel | Ready | N/A |
| 003 | Pesca em 3D com a barra de disputa | Integration | Ready | N/A |
