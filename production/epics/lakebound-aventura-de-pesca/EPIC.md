# Epic: Lakebound — Aventura de Pesca (migração para 3D no Godot)

> **Source**: `design/game-brief.md` (workflow minimal: o brief é o design)
> **Engine**: Godot 4.7 · GDScript · renderizador Mobile (Android)
> **Reference build**: protótipo 2D `prototypes/lakebound/` (tag `one-shot/lakebound`): regras, dados e números.

## Goal
Levar o Lakebound atual para um mundo 3D estilizado em Godot, sem perder nenhum sistema (pesca, disputa, espécies, economia, loja, energia, dia e noite, livro, níveis, salvamento).

## Scope
Features 8 a 15 do brief (etapas 1 a 8 do plano) e os 10 sistemas da cidade (cada um em versão simples e depois aprofundado). Construção, hortas, animais e barcos jogáveis vêm depois (aparecem só como cenário).

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Base: dados e lógica do jogo no Godot | Logic | Complete | N/A |
| 002 | Esqueleto 3D: terreno, lago, câmera e pescador | Visual/Feel | Complete | N/A |
| 003 | Pesca em 3D com a barra de disputa | Integration | Complete | N/A |
| 004 | Cenário I: propriedade e vila | Visual/Feel | Complete | N/A |
| 005 | Cenário II: rio, cachoeiras, píer em L, ilhota e modelos melhores | Visual/Feel | Ready | N/A |
| 006 | HUD da referência funcionando | UI | Ready | N/A |
| 007 | Telas em 3D: loja, Livro, bolsa e subida de nível | UI | Ready | N/A |
| 008 | Dia e noite em 3D e salvamento automático ligado | Visual/Feel | Ready | N/A |
| 009 | Mapa maior com a vila ao redor do lago (versão simples) | Visual/Feel | Ready | N/A |
| 010 | Armazém (depósito) (versão simples) | UI | Ready | N/A |
| 011 | Oficina de melhoria de varas (versão simples) | UI | Ready | N/A |
| 012 | Casas dos vizinhos e pedidos de peixe (versão simples) | Integration | Ready | N/A |
| 013 | Vizinhos (NPCs) com rotina (versão simples) | Integration | Ready | N/A |
| 014 | Cervejaria-restaurante (versão simples) | Integration | Ready | N/A |
| 015 | Campos de plantio (versão simples) | Integration | Ready | N/A |
| 016 | Pasto com animais (versão simples) | Integration | Ready | N/A |
| 017 | Loja de roupas (versão simples) | UI | Ready | N/A |
| 018 | Papel de prefeito da cidade (versão simples) | UI | Ready | N/A |
| 019 | Aprofundar: mapa maior com a vila ao redor do lago | Visual/Feel | Ready | N/A |
| 020 | Aprofundar: armazém (depósito) | UI | Ready | N/A |
| 021 | Aprofundar: oficina de melhoria de varas | UI | Ready | N/A |
| 022 | Aprofundar: casas dos vizinhos e pedidos de peixe | Integration | Ready | N/A |
| 023 | Aprofundar: vizinhos (NPCs) com rotina | Integration | Ready | N/A |
| 024 | Aprofundar: cervejaria-restaurante | Integration | Ready | N/A |
| 025 | Aprofundar: campos de plantio | Integration | Ready | N/A |
| 026 | Aprofundar: pasto com animais | Integration | Ready | N/A |
| 027 | Aprofundar: loja de roupas | UI | Ready | N/A |
| 028 | Aprofundar: papel de prefeito da cidade | UI | Ready | N/A |
