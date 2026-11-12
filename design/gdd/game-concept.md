# Game Concept: The Last Cast

*Created: 2026-11-12*
*Status: Draft*

> Fonte: documento de visão do usuário ("Projeto completo — jogo de pescaria 2D
> para Android"), formalizado via `/brainstorm`. As 7 etapas daquele documento
> estão mapeadas nos Scope Tiers abaixo.

---

## Elevator Pitch

> É um jogo de pescaria e exploração em pixel art para Android, em que você sai de
> uma doca simples e vai crescendo: pesca, cultiva sua propriedade e mergulha em
> águas cada vez mais fundas, descobrindo espécies e segredos.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Aventura de pescaria + simulação de vida/fazenda + exploração subaquática |
| **Platform** | Mobile (Android, orientação horizontal) |
| **Target Audience** | Casual a mid-core; Exploradores e Realizadores (ver Target Player Profile) |
| **Player Count** | Single-player |
| **Session Length** | 10–30 min (sessões curtas de celular), com sessões mais longas possíveis |
| **Monetization** | Nenhuma definida ainda |
| **Estimated Scope** | Medium (3–6 meses, solo) para MVP + Vertical Slice; Full Vision é Large (multi-anual, solo) |
| **Comparable Titles** | Stardew Valley, Dave the Diver (apenas referência de tipo de experiência; vendas: não pesquisado) |

---

## Core Fantasy

Começar com quase nada — uma doca, as mãos vazias — e ver um cantinho de mundo
ganhar vida por causa do seu trabalho e da sua curiosidade. Cada peixe novo, cada
ferramenta melhorada e cada metro mais fundo no mar são provas visíveis de que você
evoluiu.

---

## Unique Hook

É como um jogo de pescaria e fazenda relaxante, **e também** a superfície e o fundo
do mar formam um único ciclo: o que você pesca e cultiva financia o equipamento de
mergulho, e o que encontra no fundo (minérios, tesouros, espécies raras) melhora a
pesca e a propriedade. Duas metades que se alimentam, não dois jogos colados.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Submission** (relaxation, comfort zone) | 1 | Loops calmos de coletar, pescar e cultivar; sem punição pesada |
| **Discovery** (exploration, secrets) | 2 | Guia de peixes com silhuetas, regiões novas, tesouros e áreas secretas |
| **Sensation** (sensory pleasure) | 3 | Pixel art detalhada, água animada, feedback de coleta e captura |
| **Fantasy** (make-believe, role-playing) | 4 | Pescador iniciante que vira dono de uma estrutura de pesca |
| **Challenge** (obstacle course, mastery) | 5 | Minijogo de tensão da linha; gestão de oxigênio no mergulho |
| **Expression** (self-expression, creativity) | 6 | Casa, propriedade e lago personalizáveis (pós-MVP) |
| **Narrative** (drama, story arc) | 7 | NPCs e missões leves (pós-MVP) |
| **Fellowship** (social connection) | N/A | Single-player |

### Key Dynamics (Emergent player behaviors)

- O jogador explora "só mais um canto" para completar silhuetas do guia de peixes.
- O jogador planeja a próxima compra (vara, linha, isca) e volta a pescar para pagá-la.
- O jogador experimenta iscas e locais diferentes para atrair espécies específicas.
- O jogador alterna entre atividades (pesca, coleta, depois fazenda e mergulho) em vez de repetir uma só.

### Core Mechanics (Systems we build)

1. Movimentação top-down com controles touch (analógicos virtuais, corrida, interação contextual).
2. Coleta de recursos e fabricação (crafting), começando pela vara artesanal.
3. Pesca com lançamento, mordida e minijogo de tensão da linha, com espécies de atributos distintos.
4. Economia de venda e compra com melhorias de equipamento que mudam o funcionamento real.
5. Guia/enciclopédia de peixes com descoberta progressiva e recordes.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Exploração livre; o jogador escolhe a ordem das atividades e melhorias | Core |
| **Competence** | Minijogo de pesca melhora com prática e equipamento; peixes maiores e raros | Core |
| **Relatedness** | NPCs e comunidade da doca (pós-MVP) | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — How: completar o guia de peixes, recordes de tamanho/peso, progressão de equipamento
- [x] **Explorers** — How: mapa explorável, regiões novas, mergulho, segredos e tesouros
- [ ] **Socializers** — How: fora do escopo (single-player)
- [ ] **Killers/Competitors** — How: competições de pesca contra NPCs, só na visão completa

### Flow State Design

- **Onboarding curve**: os primeiros 10 minutos ensinam andar → coletar galhos/fibras → fabricar a vara → primeiro peixe, um verbo por vez.
- **Difficulty scaling**: espécies mais fortes e raras aparecem em locais/regiões mais avançados; equipamento melhor compensa.
- **Feedback clarity**: sinais claros de mordida, barra de tensão legível, guia que registra recordes.
- **Recovery from failure**: perder um peixe custa só alguns segundos; sem perda de itens. No mergulho, avisos claros de oxigênio e retorno seguro.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Caminhar pelo cenário, coletar um recurso ou lançar a linha e disputar o peixe no
minijogo de tensão. O lançamento e a captura precisam ser satisfatórios sozinhos:
resposta imediata ao toque, sinal de mordida claro, recompensa visual na captura.

### Short-Term (5-15 minutes)
Pescar alguns peixes → vender → comprar ou fabricar uma melhoria → testar a melhoria
num ponto de pesca melhor. "Só mais um peixe para comprar a linha nova."

### Session-Level (30-120 minutes)
Uma meta curta concluída por sessão: fabricar a primeira vara, desbloquear uma
espécie, comprar um equipamento. Ponto de parada natural ao vender e salvar;
motivo para voltar: a próxima silhueta no guia ou a próxima melhoria.

### Long-Term Progression
Nível e experiência, equipamentos melhores, propriedade e fazenda, mergulho e
novas regiões. O objetivo de longo prazo é completar o guia de peixes e explorar
todas as águas.

### Retention Hooks
- **Curiosity**: silhuetas no guia, áreas ainda não exploradas, pontos de mergulho bloqueados
- **Investment**: equipamento, propriedade e recordes que o jogador não quer perder
- **Social**: nenhum (single-player)
- **Mastery**: dominar o minijogo de pesca para capturar peixes maiores

---

## Game Pillars

### Pillar 1: Sempre em movimento no toque
Todo controle funciona bem com os polegares, em tela pequena e na horizontal.

*Design test*: na dúvida entre mais um botão na tela e menos poluição visual,
ficamos com a tela limpa.

### Pillar 2: Cada atividade alimenta as outras
Pescar, coletar, plantar e mergulhar se ajudam mutuamente; nenhuma é obrigatória para sempre.

*Design test*: um sistema novo precisa se ligar a pelo menos um sistema existente;
se ele funciona isolado, não entra.

### Pillar 3: Descoberta gentil
Explorar e coletar é sempre recompensado; errar não pune pesado.

*Design test*: ao definir uma consequência (oxigênio acabando, peixe perdido),
escolhemos a opção justa que preserva o progresso.

### Anti-Pillars (What This Game Is NOT)

- **NOT uma cópia de Stardew Valley ou Dave the Diver**: nomes, personagens, arte, mapas, interface e músicas são originais; as referências orientam só o tipo de experiência.
- **NOT multiplayer nem monetização agressiva**: exigiria infraestrutura e design que um primeiro jogo solo não comporta, e quebraria a Descoberta gentil.
- **NOT escopo infinito antes da base jogável**: sistemas avançados (barcos, regiões, NPCs, clima) esperam a base estável; isso protege "Sempre em movimento no toque".

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Stardew Valley | Progressão de vida rural, fazenda, pesca como atividade | Pesca é o centro, não um extra; mundo e arte originais | Valida o loop relaxante de várias atividades |
| Dave the Diver | Mergulho com oxigênio, arpão, superfície ↔ fundo | Sem restaurante como núcleo; o fundo alimenta a pesca e a propriedade | Valida o ciclo superfície/fundo |

**Non-game inspirations**: não definidas ainda.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | Não definido (sugestão: 14+) |
| **Gaming experience** | Casual a mid-core |
| **Time availability** | Sessões curtas de 10–30 min no celular |
| **Platform preference** | Celular Android |
| **Current games they play** | Jogos de fazenda/vida e de pescaria no celular |
| **What they're looking for** | Um jogo calmo com progressão visível e descoberta |
| **What would turn them away** | Controles touch ruins, punição pesada, telas cheias de botões |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.7, GDScript (já configurado; renderer Compatibility para Android) |
| **Key Technical Challenges** | Controles touch responsivos e adaptáveis; minijogo de pesca com boa sensação; sistema de save robusto; desempenho em celulares |
| **Art Style** | Pixel art moderna e detalhada, câmera top-down 2D |
| **Art Pipeline Complexity** | Medium (2D customizado); arte provisória gerada por código até haver assets originais |
| **Audio Needs** | Moderate (ambiente, feedback de coleta e pesca) |
| **Networking** | None |
| **Content Volume** | MVP: 1 mapa inicial, ~5–8 espécies, ~10–15 itens |
| **Procedural Systems** | Nenhum planejado (aleatoriedade só em mordida, tamanho e peso dos peixes) |

---

## Risks and Open Questions

### Design Risks
- O minijogo de pesca pode não sustentar o interesse se for raso ou repetitivo.
- Coleta e crafting iniciais podem parecer tarefa antes da primeira pesca.

### Technical Risks
- Analógicos virtuais e layout de HUD em várias proporções de tela.
- Exportação Android (SDK, templates) ainda não testada neste ambiente; sem teste em aparelho real.

### Market Risks
- Gênero com concorrentes estabelecidos (não pesquisado).

### Scope Risks
- A visão completa (7 etapas) excede em muito o prazo de "meses" para um primeiro jogo solo; mitigado pelo recorte do MVP.
- Arte pixel art detalhada é trabalhosa; assets provisórios podem durar mais que o planejado.

### Open Questions
- O minijogo de tensão é divertido? Resposta: protótipo jogável na Etapa 2.
- Os controles touch são confortáveis? Resposta: teste no PC e, quando possível, num aparelho Android.

---

## MVP Definition

**Core hypothesis**: o ciclo coletar → fabricar a vara → pescar → vender → melhorar
é divertido em sessões de 10–30 minutos no celular.

**Required for MVP**:
1. Personagem controlável por toque num mapa inicial explorável (doca, água, vegetação, colisões).
2. Coleta de recursos e fabricação da primeira vara.
3. Pesca com lançamento, mordida e minijogo de tensão; primeiras espécies.
4. Venda de peixes, dinheiro, experiência e guia de peixes.
5. Salvamento e carregamento.

**Explicitly NOT in MVP** (defer to later):
- Propriedade, fazenda e animais (Etapa 4)
- Mergulho (Etapa 5)
- Barcos, regiões novas, NPCs e missões (Etapa 6)
- Clima, ciclo dia/noite, competições (Etapa 7)

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Mapa inicial, primeiras espécies | Etapas 1–2: movimentação, coleta, crafting, pesca, venda, save | ~6–10 semanas |
| **Vertical Slice** | Mapa inicial completo + loja | Etapa 3: loja, equipamentos, progressão de nível | ~4–6 semanas a mais |
| **Alpha** | Propriedade + primeiro ambiente subaquático | Etapas 4–5: fazenda, animais, lago, mergulho | Visão futura (meses) |
| **Full Vision** | Todas as regiões | Etapas 6–7: barcos, regiões, NPCs, clima, polimento, APK final | Visão futura (multi-anual) |

---

## Next Steps

- [x] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine`)
- [ ] **Prototype core idea** (`/prototype`) — Etapa 1 jogável no Godot
- [ ] Visual identity (`/art-bible`)
- [ ] Decompose concept into systems (`/map-systems`)
- [ ] Design each system (`/design-system [system-name]`)
- [ ] Build vertical slice in Pre-Production (`/vertical-slice`)
- [ ] Plan first milestone (`/sprint-plan new`)
