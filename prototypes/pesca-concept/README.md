<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone? -->
<!-- Date: 2026-11-18 -->
# Protótipo: pesca (minijogo de pesca)

**Status:** in-progress (aguardando o playtest do usuário)

## Hipótese
Se o jogador lança a linha, fisga na mordida e controla a tensão com um único
botão de polegar, pegar um peixe vai parecer tenso e recompensador. Saberemos que
é verdade se um jogador novo pegar 3 dos 5 primeiros peixes fisgados, perder pelo
menos 1 (linha partida ou fuga) e continuar jogando por escolha depois de 5 minutos.

## Como jogar
Um botão no canto inferior direito (no PC: mouse ou barra de espaço):
1. **LANÇAR:** segure e solte com a barra de força na faixa verde (lançamento
   perfeito: mais longe, mais chance de peixe raro).
2. **Espere:** tocar antes da hora assusta o peixe.
3. **FISGAR!:** quando a boia afunda e aparece "!", toque em menos de 0,9 s.
4. **PUXAR:** segure para puxar (a tensão sobe e o peixe chega mais perto) e
   solte quando a tensão chegar no vermelho (o peixe foge um pouco). Tensão no
   máximo por 0,35 s parte a linha. Nos arranques do peixe a tela treme.

Rodar no PC: abra `prototypes/pesca-concept/project.godot` no Godot 4.7 e aperte F5.
Autoteste: `godot --headless --path prototypes/pesca-concept -- --autotest`.
Simulação de equilíbrio: `godot --headless --path prototypes/pesca-concept -s sim.gd`.

## Espécies (originais, provisórias)
| Espécie | Raridade | Força | Arranques/s |
|---|---|---|---|
| Lambari-prata | Comum | 0,32 | 0,2 |
| Tilápia-do-cais | Comum | 0,50 | 0,35 |
| Traíra-listrada | Incomum | 0,68 | 0,5 |
| Robalo-dourado | Raro | 0,85 | 0,6 |

## Simulação (200 brigas por espécie, `sim.gd`)
| Estratégia | Lambari | Tilápia | Traíra | Robalo |
|---|---|---|---|---|
| Cuidadosa (solta perto do vermelho) | 100% | 100% | 100% | 100% |
| Humana (decide a cada 0,3 s) | 100% | 100% | 70% | 65% |
| Só segura | 100% | 33% | 0% | 0% |
| Nunca puxa | 0% (foge) | 0% | 0% | 0% |

Conclusão provisória: a habilidade importa e os peixes fortes exigem atenção.
O "sentir" só um playtest real responde.

## Achados
_A preencher após o playtest._
