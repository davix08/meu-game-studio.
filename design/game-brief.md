# Game Brief: Mystic Tides

## In your words
Documento completo do jogador, na íntegra: `design/source/projeto_jogo_pescaria_claude.txt`.

Mensagens no chat (2026-11-18), palavra por palavra:

> E) Novo jogo para smartphone Android

> A base é essa [pesqueiro_base_1.zip]. Usaremos os gráficos, modelo de jogo, jogabilidade.
> Porém, seguiremos o texto que irei te encaminhar a seguir. Manterá apenas os elementos gráficos e jogabilidade.
> No texto que vou encaminhar, acrescente uma possibilidade de multijogador Coop para até , 4 players simultâneo

> Perfeito, a base é essa
> Por hora, manteremos o nome como: Mystic Tides
> As ideias são: possibilidade de mergulhar para pescar e explorar com arma, arpão (mesma ideia de Dave The Diver).
> Na nossa doca, fazenda, possibilidade de decorar, a fazenda, decorar a casa, plantar (mesma ideia de Stardew Valey).
> Na pescaria, os peixei deve ter peso, tamanho, raridade.
> Com o desenvolver do jogo deve haver a possibilidade de novas áreas com novos peixes.
> Possibilidade de melhoria de equipamentos e novos equipamentos para novos tipos de peixes.
> Acrescente isso no projeto

**Pitch:** Um pescador iniciante numa pequena doca pesca da margem, mergulha com arpão, cuida e decora a própria fazenda e abre novas águas, sozinho ou com até 3 amigos.

**Genre:** aventura de pescaria + exploração subaquática + vida na fazenda (simulação/gerenciamento)

**Controls:** Android, horizontal. Analógico virtual esquerdo move (8 direções), analógico direito mira ferramenta/arpão/lançamento, botão de correr junto ao esquerdo, botão contextual de interação, barra de inventário rápido embaixo entre os analógicos, menu compacto no canto superior direito (Inventário, Guia de peixes, Configurações).

**Question:** A pescaria da base, com peixes de peso, tamanho e raridade, sustenta o ciclo pescar → vender → melhorar → abrir nova área? E pescar junto com amigos deixa isso mais divertido?

**Hooks:**
- Duas formas de pescar: vara na superfície e mergulho com arpão no fundo.
- Cada peixe pesado e medido, com recordes no guia.
- Uma doca e fazenda que são suas e que você decora.
- Até 4 pescadores juntos.

**Intent:** needs N players: 1–4 (coop opcional; o jogo inteiro joga sozinho) · you said

## Look and references
- Look: o visual da base pesqueiro_base_1 (Lakebound), mantido como está: 3D low-poly isométrico, água com shader, cachoeira, ciclo de dia e noite, cidade, fazenda e rancho. *(you said: "usaremos os gráficos")* Isso substitui o "2D Pixel Art" do documento.
- References: Dave the Diver (mergulho com arpão, alternando superfície e fundo, *you said*); Stardew Valley (plantar e decorar casa e fazenda, *you said*). Só o tipo de experiência: nenhum personagem, mapa, sprite, nome, interface ou música desses jogos *(documento, §1)*.
- View: 3D · Camera: isométrica ortográfica fixa (35,264° de inclinação, 45° de rotação), seguindo o jogador *(da base)*. No coop: uma câmera por aparelho.

## First minute
Igual à base, no início descrito no documento: o pescador acorda na doca sem vara. Anda com o analógico, vê galhos e fibras brilhando e coleta com o botão contextual. Monta a vara artesanal no banco da doca e lança na água. Sente a primeira mordida, puxa no minijogo e vê "Tilápia — 1,4 kg, 38 cm, Comum" ir para o guia. *(inferred (strong): documento §9–11 + jogabilidade da base)*

## Challenge
O primeiro problema real aparece em uns 3 minutos: um peixe raro rompe a linha da vara artesanal. Perder custa a isca e o peixe, nunca dinheiro nem itens. Depois vêm espécies mais fortes que pedem vara, linha ou molinete melhores. Em seguida, regiões que só abrem com barco, equipamento ou nível. No mergulho, o oxigênio limita o tempo: ao chegar a zero, você volta à superfície e perde parte do que pegou naquele mergulho, sem perder o progresso. *(provisional)*

## Core loop
- Pescar (vara ou arpão) e coletar → peixes com peso, tamanho e raridade, além de materiais e tesouros.
- Vender e completar o guia → dinheiro e XP.
- Melhorar e comprar equipamento, plantar, decorar → pescar peixes maiores e abrir novas áreas com novas espécies.
- No coop, cada jogador pesca o seu peixe; o dinheiro de cada um é separado e a fazenda é compartilhada. *(provisional)*

## Goal & fail state
- Objetivo: completar o guia de peixes em todas as regiões e transformar a doca numa base completa. Uma sessão está completa quando você vende uma pescaria e melhora alguma coisa (equipamento, casa ou plantação).
- Falha: não existe game over. O peixe escapa (linha rompida). O oxigênio acaba no mergulho (volta à superfície e perde parte da coleta). A energia acaba (o dia termina).

## Features
- [x] Mundo explorável: doca, lago, água, vegetação, colisões, câmera seguindo *(da base)*
- [x] Pesca com vara: lançar, mordida, minijogo de tensão, captura *(da base)*
- [ ] Peixes com peso, tamanho e raridade (tamanho e "Raridade" visíveis), com guia de peixes e recordes
- [ ] Coleta + fabricação da primeira vara artesanal
- [ ] Loja: vender peixes, comprar e melhorar equipamento (vara, linha, molinete, isca)
- [ ] Mergulho com arpão num primeiro ponto de mergulho (oxigênio, arpão, peixes do fundo) (thin stand-in)
- [ ] Coop local para até 4 jogadores no mesmo mundo (thin stand-in)

## Your systems
- pesca com vara (peso, tamanho, raridade) · in the slice
- guia/enciclopédia de peixes · in the slice
- coleta de recursos e fabricação · in the slice
- loja, melhorias e novos equipamentos para novos peixes · in the slice
- mergulho com arpão, faca e oxigênio · thin stand-in
- multijogador coop até 4 · thin stand-in
- fazenda: plantar e colher · later
- decorar casa e fazenda · later
- lago particular de peixes · later
- animais e pets · later
- novas áreas com novos peixes (rio, ilhas, oceano, profundo, gelo, ruínas) · later
- barcos · later
- NPCs, missões e competições · later
- clima · later
- construções da doca (oficina, aquário, laboratório, restaurante, estaleiro) · later
- salvamento local · in the slice *(da base)*

## Keep
- Os gráficos da base Lakebound (3D isométrico, água, cachoeira, dia/noite): as partes de 2D do documento não valem *(you said)*
- A jogabilidade de pesca da base (lançar, fisgar, puxar) *(you said)*

## Avoid
- Toda a direção de gráfico 2D / Pixel Art / câmera Top-Down 2D do documento (§2, §3, §23): ignorada. A base gráfica é a do Lakebound *(you said)*
- Copiar personagens, mapas, sprites, nomes, interface ou músicas de Stardew Valley ou Dave the Diver *(documento §1)*
- Botões decorativos, telas falsas, ou funcionalidade dita como pronta sem estar *(documento §1, §24)*
- Progressão que exige repetir uma única atividade *(documento §19)*
- Clima e horário punitivos demais *(documento §17)*
- Pesca impossível sem isca *(documento §11)*

## Out of scope
- Coop pela internet (servidores, matchmaking): primeiro só mesma rede Wi-Fi *(provisional)*
- Regiões além do lago inicial e do 1º ponto de mergulho: Etapa 6
- Fazenda, decoração, animais, lago particular: Etapa 4
- Barcos, NPCs, missões, competições, clima: Etapas 6–7
- Arte 2D pixel art do documento: substituída pela base 3D

## Build order
1. Trazer a base para o repositório, renomear para Mystic Tides e confirmar que roda no PC e no Android (o documento pede "começar do zero", mas isso foi substituído pela base).
2. Peixes com peso, tamanho e raridade, com guia de peixes e recordes. É a pescaria do jogo, então vem primeiro. Objetivo: encher o guia; perda: o peixe escapa.
3. Coleta e fabricação da vara artesanal (Etapa 2 do documento).
4. Loja, melhorias e equipamentos novos que liberam peixes novos (Etapa 3).
5. Coop local para 2–4 jogadores: arriscado, entra cedo para o código já nascer preparado para rede.
6. Primeiro mergulho com arpão (Etapa 5).
7. Fazenda e decoração (Etapa 4), depois novas áreas, barcos, NPCs (Etapa 6), polimento e APK (Etapa 7).

---
**Kill condition:** se, depois de duas rodadas de ajuste, pescar com peso, tamanho e raridade ainda não der vontade de "só mais um peixe". *(guessed)*

**Who it's for / what they feel:** jogadores de celular que querem uma rotina tranquila de pescar e evoluir, sozinhos ou com amigos no sofá. *(guessed)*

**Games you love / don't:** Gosta de Dave the Diver (mergulho com arpão) e Stardew Valley (fazenda e decoração).
