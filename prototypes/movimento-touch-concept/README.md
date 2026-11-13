<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable? -->
<!-- Date: 2026-11-13 -->
# Protótipo: movimento-touch (The Last Cast)

**Status:** in-progress (aguardando o playtest do usuário)

## Hipótese
Se o jogador mover o personagem pelo analógico virtual esquerdo (com botão de correr),
andar pela doca e pela margem vai parecer imediato e confortável. Saberemos que é
verdade se, em 2 minutos, ele percorrer o mapa todo, contornar árvores e pedras sem
travar e parar na beira da água sem cair, sem precisar olhar para os polegares.

## Como rodar
1. Instale o Godot 4.7 (https://godotengine.org/download).
2. Abra `prototypes/movimento-touch-concept/project.godot` no Godot e aperte F5
   (ou: `godot --path prototypes/movimento-touch-concept`).
3. Controles:
   - **Toque/mouse:** arraste no canto inferior esquerdo para andar; toque no
     botão laranja (»») para ligar/desligar a corrida; arraste no canto inferior
     direito para mirar (só mostra a seta).
   - **Teclado (atalho de teste):** WASD anda, Shift corre.
4. Autoteste: `godot --headless --path prototypes/movimento-touch-concept -- --autotest`
   imprime 8 linhas PASS/FAIL.

## O que existe
Mapa 1280×768 gerado em código (grama, trilha, areia, espuma animada, água com
shader, doca de madeira), 46 árvores, 18 pedras, 30 arbustos com colisão, y-sort,
personagem em 8 direções com animação simples de andar/correr, câmera suave com
limites, analógico dinâmico com zona morta (18%), diagonal normalizada.

Valores: andar 70 px/s, correr 125 px/s, aceleração 900 px/s², viewport 640×360
escalado (pixel art), renderer Compatibility.

## Resultado do autoteste (2026-11-13, Godot 4.7.2)
Todos os 8 passaram: stick move (70 px/s), diagonal = reta (70,0 vs 70,0),
zona morta ignora toque pequeno, corrida (125 px/s), mira, água bloqueia na
margem, doca andável até o fim, tronco de árvore bloqueia.
Screenshots em `shots/`.

## Achados
_A preencher após o playtest._
