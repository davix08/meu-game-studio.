# Game Brief: Lakebound — Aventura de Pesca

## In your words

PROJETO: LAKEBOUND — AVENTURA DE PESCA 2D

1. VISÃO GERAL

Desenvolva um jogo chamado Lakebound — Aventura de Pesca, um simulador de pesca 2D com gráficos pixel art, visão superior (Top-Down), exploração e progressão de personagem.

O jogo deve ser desenvolvido para dispositivos Android, priorizando controles por toque e uma interface adaptada para telas de celulares.

A experiência deve combinar:

- Simulador de pesca.
- Exploração de mapas.
- Coleção de peixes.
- Evolução de equipamentos.
- Sistema econômico.
- Progressão por níveis.
- Ciclo de dia e noite.
- Gerenciamento de energia.

2. ESTILO VISUAL

Utilize gráficos 2D em Pixel Art, com inspiração em jogos RPG clássicos.

Características:

- Câmera Top-Down.
- Personagens em Pixel Art.
- Animações fluidas.
- Água com animações de ondas.
- Vegetação animada.
- Peixes nadando pelo mapa.
- Efeitos visuais durante a pesca.
- Cenários detalhados.
- Interface com estética retrô.

Utilize uma paleta de cores naturais, com predominância de verde, azul, marrom e tons de natureza.

A resolução interna pode ser de 320x180, com escala adaptativa para diferentes telas.

3. MAPA PRINCIPAL

O jogador começa no mapa chamado Lago Esmeralda.

O cenário deve conter:

- Um grande lago.
- Áreas de terra exploráveis.
- Vegetação.
- Árvores.
- Plantas aquáticas.
- Pequenas ilhas.
- Casa de pesca.
- Áreas próprias para pescar.

O jogador deve conseguir caminhar livremente pelas áreas permitidas.

Implemente colisões para impedir que o personagem atravesse árvores, construções e outros obstáculos.

4. PERSONAGEM

O jogador controla um pescador.

Características:

- Movimento em quatro direções.
- Animações de caminhada.
- Animação de corrida.
- Animação de pesca.
- Animação de espera.
- Animação ao capturar um peixe.
- Animação de descanso.

O personagem deve possuir uma vara de pesca e equipamentos que podem ser melhorados.

5. SISTEMA DE PESCA

A pesca é a principal mecânica do jogo.

Funcionamento:

1. O jogador se aproxima da água.
2. Toca na área do lago onde deseja lançar a linha.
3. O personagem executa a animação de lançamento.
4. A boia cai na água.
5. O jogador espera o peixe morder.
6. Quando o peixe morder, aparece um aviso.
7. O jogador precisa tocar e segurar o botão PUXAR.
8. Uma barra de disputa aparece na tela.
9. O jogador precisa manter o indicador dentro da zona verde.
10. Quando o progresso chega a 100%, o peixe é capturado.

Se o jogador não reagir a tempo ou perder o controle da disputa, o peixe poderá escapar.

A dificuldade deve variar conforme o tipo de peixe.

6. SISTEMA DE PEIXES

Implemente 35 espécies de peixes diferentes.

Raridades

- Comum.
- Incomum.
- Raro.
- Épico.
- Lendário.

Cada peixe deve possuir:

- Nome.
- Sprite próprio.
- Raridade.
- Peso mínimo.
- Peso máximo.
- Valor de venda.
- Dificuldade de captura.

Espécies

Comuns:

- Sardinha.
- Tilápia.
- Cavala.
- Acará-azul.
- Piaba-azul.
- Perca-verde.
- Camarão.

Incomuns:

- Tucunaré.
- Carpa.
- Salmão.
- Peixe-palhaço.
- Baiacu.
- Cirurgião-azul.
- Caranguejo.
- Peixe-dourado.

Raros:

- Koi.
- Peixe-leão.
- Cavalo-marinho.
- Choco.
- Polvo.
- Lagosta.
- Peixe-fantasma.
- Tubarão-azul.

Épicos:

- Peixe-espada.
- Arraia-jamanta.
- Atum-amarelo.
- Tubarão-martelo.
- Celacanto.
- Náutilo.
- Moreia-verde.

Lendários:

- Peixe-lua.
- Lula-gigante.
- Tubarão-baleia.
- Arowana-dourada.
- Peixe-remo.

Os peixes mais raros devem ter menor probabilidade de aparecer.

7. SISTEMA DE NÍVEIS

O jogador começa no nível 1.

A progressão acontece através da descoberta de novas espécies de peixes.

Cada nível libera uma nova categoria de raridade.

Progressão:

- Nível 1: Iniciante — peixes comuns.
- Nível 2: Pescador — peixes incomuns.
- Nível 3: Veterano — peixes raros.
- Nível 4: Mestre — peixes épicos.
- Nível 5: Lenda — peixes lendários.
- Nível 6: Lenda do Lago — coleção completa.

Ao subir de nível:

- Apresente uma tela especial.
- Mostre as novas espécies desbloqueadas.
- Libere equipamentos na loja.
- Entregue uma recompensa em moedas.

8. ECONOMIA E LOJA

Crie uma loja de pesca dentro de uma construção próxima ao lago.

O jogador deve entrar na construção e se aproximar do balcão para abrir a loja.

Vender peixes

O jogador pode vender todos os peixes armazenados na bolsa.

O valor depende da raridade e do peso do peixe.

Comprar equipamentos

Implemente:

Varas:

- Vara de bambu.
- Vara de fibra.
- Vara de carbono.
- Vara de titânio.
- Vara lendária.

As varas melhores devem proporcionar:

- Lançamentos mais longos.
- Zona verde maior durante a captura.
- Maior facilidade para capturar peixes difíceis.

Iscas:

- Isca simples.
- Minhoca gorda.
- Isca cheirosa.
- Isca brilhante.
- Camarão real.
- Isca dourada.

As iscas devem reduzir o tempo de espera e melhorar as possibilidades de encontrar peixes melhores.

Também implemente:

- Lanche que recupera energia.
- Isca da sorte que aumenta temporariamente a chance de peixes raros.

Os equipamentos devem ser desbloqueados progressivamente.

9. SISTEMA DE ENERGIA

O personagem possui uma barra de energia de 0 a 100%.

Ações como lançar a linha consomem energia.

Quando a energia acaba, o jogador precisa descansar.

Implemente:

- Barra de energia.
- Consumo de energia nas pescarias.
- Recuperação ao descansar.
- Recuperação através de alimentos comprados na loja.

10. CICLO DE DIA E NOITE

Implemente um relógio interno.

O jogo começa durante o dia.

O ambiente deve mudar visualmente conforme o horário.

Períodos:

- Manhã.
- Tarde.
- Noite.
- Madrugada.

Durante a noite, aplique uma iluminação mais escura no cenário.

Quando o jogador chega ao horário limite, deve dormir automaticamente e iniciar um novo dia, recuperando toda a energia.

11. LIVRO DE PEIXES

Crie um sistema de coleção chamado LIVRO DE PEIXES.

Ele deve apresentar todas as 35 espécies disponíveis.

Cada espécie deve ter:

- Ilustração.
- Nome.
- Raridade.
- Maior peso capturado.
- Quantidade de capturas.

Peixes ainda não descobertos devem aparecer como silhuetas ou interrogações.

O livro deve mostrar o progresso da coleção.

Exemplo: 12/35 peixes descobertos.

12. INTERFACE

A interface deve apresentar:

- Nome da região.
- Dia atual.
- Horário.
- Quantidade de moedas.
- Nível do jogador.
- Energia.
- Quantidade de peixes na bolsa.
- Valor estimado dos peixes armazenados.

Botões:

- PUXAR.
- ZZZ (descansar).
- ENTRAR.
- LOJA.
- SAIR.
- LIVRO.

As telas de loja, coleção e evolução devem ser adaptadas para celulares.

13. CONTROLES ANDROID

Implemente controles por toque:

- Tocar no chão: movimentar o personagem.
- Tocar na água: lançar a linha.
- Segurar PUXAR: controlar a captura.
- Tocar em ZZZ: descansar.
- Tocar em LIVRO: abrir a coleção.
- Tocar em ENTRAR: acessar a casa de pesca.
- Tocar em LOJA: abrir o comércio.
- Tocar em SAIR: deixar a construção.

Também mantenha suporte opcional a teclado para testes no computador.

14. SALVAMENTO

Implemente salvamento automático.

O jogo deve guardar:

- Moedas.
- Nível.
- Dia.
- Horário.
- Energia.
- Peixes capturados.
- Livro de coleção.
- Vara equipada.
- Isca equipada.
- Iscas da sorte disponíveis.

O progresso deve continuar disponível quando o jogador fechar e abrir o jogo novamente.

15. REQUISITOS TÉCNICOS

Desenvolva uma estrutura organizada e modular.

Separe:

- Sistema de movimentação.
- Sistema de pesca.
- Sistema de peixes.
- Sistema econômico.
- Sistema de níveis.
- Sistema de energia.
- Sistema de tempo.
- Sistema de inventário.
- Sistema de salvamento.
- Interface.
- Renderização e animações.

O jogo deve funcionar em Android, apresentar bom desempenho e possuir controles responsivos.

16. ORIENTAÇÕES IMPORTANTES

Não desenvolva apenas uma demonstração visual.

Todas as mecânicas precisam funcionar de verdade.

Não utilize botões decorativos ou sistemas simulados sem funcionamento.

Priorize uma primeira versão jogável, estável e completa, com todas as funcionalidades descritas.

Não remova mecânicas existentes durante futuras atualizações.

Antes de adicionar novos recursos, verifique se eles são compatíveis com os sistemas já implementados.

OBJETIVO FINAL: Criar um simulador de pesca 2D em Pixel Art, com exploração, coleção de espécies, progressão, economia e uma experiência divertida para Android.

**Pitch:** Um simulador de pesca top-down em pixel art: explore o Lago Esmeralda, dispute cada peixe numa barra de tensão, venda, melhore a vara e complete o Livro com 35 espécies.

**Genre:** simulador de pesca / coleção com exploração

**Controls:** tocar no chão para andar, tocar na água para lançar, segurar PUXAR na disputa; botões ZZZ, LIVRO, ENTRAR, LOJA, SAIR. Teclado: WASD/setas para andar, Shift para correr, clique para lançar, Espaço para PUXAR, E para entrar/loja, Z para descansar, L para o livro, Esc para sair *(inferred (strong))*

**Question:** A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira? *(guessed)*

**Hooks:** a disputa com zona verde que muda conforme o peixe e a vara; o Livro de Peixes com silhuetas a descobrir.

**Intent:** payoff builds *(provisional)*

## Look and references
- Look: pixel art estilo RPG clássico, resolução interna 320x180 com escala inteira; paleta natural: verde (grama, copas), azul em degradê (água, mais escuro no fundo), marrom (terra, madeira), creme (interface retrô); água com ondas animadas, plantas balançando, sombras de peixes nadando; a noite cobre o mapa de azul escuro, com a janela da casa de pesca acesa; cada personagem e peixe desenhado, nunca emoji nem círculos simples.
- References: RPGs clássicos em pixel art (a visão de cima, a interface retrô) *(inferred (strong))*.
- View: 2D · Camera: top-down, seguindo o pescador, presa às bordas do mapa.

## First minute
O pescador acorda na margem às 6h ao lado da casa de pesca, com vara de bambu e isca simples. Uma dica curta aponta a água. Ele anda até a beira e toca na água: a boia cai, em alguns segundos surge um "!". Ele segura PUXAR, a barra aparece, a primeira Sardinha é fácil de manter na zona verde. "NOVA ESPÉCIE!", e o Livro marca 1/35.

## Challenge
Comuns são tranquilos. O primeiro aperto vem lá pelo minuto 3 a 5: peixes incomuns que dão trancos e têm zona verde menor, e a energia que acaba e obriga a descansar ou comprar lanche. Perder um peixe custa só a energia do lançamento. Raros, épicos e lendários exigem vara e isca melhores. *(provisional)*

## Core loop
- Lançar → esperar a mordida → disputar na barra → peixe na bolsa (e no Livro, se for nova espécie)
- Bolsa cheia ou energia baixa → loja → vender → comprar vara, isca ou lanche
- Novas espécies → subir de nível → nova raridade e novos itens na loja
- Fim do dia → dormir → novo dia com energia cheia

## Goal & fail state
- Objetivo: chegar a Lenda do Lago (35/35 descobertos); uma sessão parece completa ao subir um nível.
- Sem game over: o peixe pode escapar, e a energia zerada obriga a descansar.

## Features
- [x] Lago Esmeralda explorável com colisões, ilhas, vegetação e casa de pesca com balcão
- [x] Pesca completa: lançar, mordida, PUXAR, barra com zona verde e progresso, dificuldade por peixe
- [x] 35 espécies em 5 raridades, cada uma com sprite próprio, peso, valor e dificuldade
- [x] Loja: vender a bolsa; 5 varas, 6 iscas, lanche e isca da sorte, liberados por nível
- [x] 6 níveis com tela de evolução, espécies liberadas e recompensa em moedas
- [x] Energia, descanso, relógio de dia e noite em 4 períodos, sono automático
- [x] Livro de Peixes, interface completa, controles de toque e teclado, salvamento automático

## Your systems
- movimentação e colisão · in the slice
- pesca · in the slice
- peixes e raridades · in the slice
- economia e loja · in the slice
- níveis · in the slice
- energia · in the slice
- dia e noite · in the slice
- inventário (bolsa) · in the slice
- Livro de Peixes · in the slice
- salvamento automático · in the slice

## Keep
-

## Avoid
- demonstração só visual, botões decorativos, sistemas simulados sem funcionamento
- remover mecânicas existentes em atualizações futuras

## Out of scope
- APK nativo Android: este build roda no navegador do celular, com toque em tela cheia: grow it
- outros mapas além do Lago Esmeralda: grow it

## Build order
1. Lago Esmeralda com pesca completa, 35 espécies, loja, níveis, energia, dia e noite, Livro, interface e salvamento: a primeira versão jogável e completa pedida.

---
**Kill condition:** se a disputa na barra continuar sem graça depois de duas rodadas de ajuste. *(guessed)*

**Who it's for / what they feel:** quem gosta de jogos calmos de coleção e quer "mais um lançamento" no celular. *(guessed)*

**Games you love / don't:** RPGs clássicos em pixel art *(inferred (strong))*
