# Game Brief: Errante de Vesper *(provisional title)*

## In your words
- "Vamos recriar esse jogo, usando esse projeto, mas com a engine godot engine 4 para celular https://github.com/JulianBiancardi/Cuphead"
- "Use a estrutura desse projeto ent"
- "Blz então vamos fazer igualzinho a estrutura base do cuphead mas sem copiar personagens, chefes, sprites, músicas e fases do Cuphead."
- "O tema vai ser do elden righ a história dele, como o jogo vai ser só pra mim divertir eu não vou publicar em lugar nenhum ent podemos fazer esse tema"

> Note: the code structure follows the reference repo's architecture (player state
> machine, damage components, observer bus, level manager, one folder per boss).
> The content is original: the Cuphead and Elden Ring characters, bosses, story,
> art and music are not used. The setting below is a new dark-fantasy world in a
> similar mood *(provisional — change freely)*.

**Pitch:** A cursed knight runs, dashes and parries through boss duels against the stone guardians of a fallen kingdom, on a phone. *(inferred (strong))*

**Genre:** 2D run-and-gun boss rush

**Controls:** Floating joystick on the left (move, 8-way aim). Buttons on the right: PULO (jump; again in the air = parry), DASH, EX (EX shot with 1 card; super when the meter is full), MIRA (hold to stand still and aim). Auto-fire on by default; TIRO button when it is off. Keyboard for desktop testing: WASD/arrows, Space, J, Shift, K, L.

**Question:** Do the touch controls feel precise enough to dodge, parry and aim through a 3-phase boss? *(guessed)*

**Hooks:** Parry the gold-colored attacks in mid-air to fill the super meter; boss phases change the attack set. *(inferred (strong))*

## Look and references
- Look: dusk dark fantasy: purple and rose sky bands, a broken pale moon, black ruined towers. Characters are drawn shapes for now: a hooded knight with a visor glow and a light lance; the boss is a towering stone sentinel with glowing cyan runes. Gold = parryable, everywhere. *(provisional)*
- References: the reference repo's code structure (from you); the genre's boss-duel structure. *(inferred (strong))*
- View: 2D · Camera: fixed, one screen arena, landscape 1280x720.

## First minute
Title → "Lutar: Vigia Petrificado". "PREPARE-SE" → "LUTE!". Auto-fire hits the boss straight away; the first stone volley arcs in, and every third stone is gold: jump and tap PULO again on it to parry, bounce and earn a card. *(guessed)*

## Challenge
Three hit points. Phase 2 (66% boss health) adds falling shards; phase 3 (33%) adds leaping slams with double shockwaves and faster attacks. Death shows how far through the boss you got. *(guessed)*

## Core loop
- Dodge and read telegraphed attacks → shoot to deal damage and fill the meter.
- Parry gold attacks → bonus cards → spend on EX or a super beam.
- Lose → retry immediately, knowing the pattern better.

## Goal & fail state
- Win: bring the boss to 0 HP; results screen grades time, health, parries and super cards (D–S).
- Fail: player HP reaches 0 → defeat menu with the boss progress bar, retry or title.

## Features
- [x] Player state machine: ground/run, duck, air (jump, coyote, buffer, variable height), dash, hit, dead
- [x] Shooting with 8-way aim, EX shot and super beam, fed by a super meter
- [x] Parry on parryable (gold) projectiles
- [x] Boss framework with health-threshold phases (data-driven) + first boss, 3 phases, 4 attacks
- [x] Multi-touch on-screen controls + auto-fire option
- [x] HUD, pause (also on app focus loss), defeat and results screens
- [ ] Real art and animation (sprites replacing the drawn placeholders)
- [ ] Sound effects and music (original)

## Your systems
- player state machine · in the slice
- weapons, EX and super · in the slice
- parry · in the slice
- bosses with phases · in the slice
- touch controls · in the slice
- tutorial level · later
- flying (ship) levels · later
- world map, shop, charms · later

## Keep
-

## Avoid
- Copying Cuphead or Elden Ring characters, bosses, sprites, music, levels or story *(agreed)*

## Out of scope
- Tutorial level (build-order step 3)
- Flying/ship levels (step 4)
- World map, shop, extra weapons, charms (step 5)
- Multiplayer and online features

## Build order
1. One boss duel, end to end on a phone: movement, shooting, parry, 3 phases, win/lose. *(this build)*
2. Feel pass on device: tune `assets/data/player/player_stats.tres`, touch layout, telegraphs.
3. Tutorial arena (dummy targets, a parry practice object).
4. Second boss, then a flying-level controller.
5. World map, weapon selection, charms.

---
**Kill condition:** if the touch controls still can't parry reliably after two tuning rounds, switch to a simpler control scheme (auto-aim, tap-to-parry). *(guessed)*

**Who it's for / what they feel:** you, playing on your phone: hard but fair duels where every death teaches something.

**Games you love / don't:** Cuphead (structure); Elden Ring (theme and mood).
