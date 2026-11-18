# Coop on the Same Wi-Fi (thin slice)

> Status: Approved as a thin stand-in (autonomous session, 2026-11-18, under the user's
> "take the recommended decisions" instruction) · Source: `design/game-brief.md` Intent
> (1–4 players), Build order step 5, provisional decisions (same Wi-Fi, money per player)
> · Code: `src/net/`, `src/world/remote_players.gd`, `Screens.open_coop`

## 1. Overview
Up to 4 phones on the same Wi-Fi play in the same lake. One player **creates a room**
(Configurações → Jogar junto). Friends see it in a list and **join**, or type the
host's IP if the router blocks discovery. Each player sees the others walking, casting
and fighting fish in their own color with a name tag. Every catch is announced to
everyone. **Each player keeps their own game**: money, bag, guide, gear and save. This
is the "thin stand-in" the brief asks for: it gets the code ready for networking early,
without yet sharing the world's state.

## 2. Player Fantasy
"We're fishing together." Seeing a friend on the pier and reading "Jogador 2 pegou Carpa
· 4,51 kg · 63 cm" turns every catch into a small moment between friends.

## 3. Detailed Rules
1. Transport: Godot ENet (UDP), port 7777. The host is peer 1. At most 4 players (host + 3).
2. Discovery: while a room is open, the host broadcasts `MYSTICTIDES1|<name>|<players>|<port>`
   on UDP 7779 every second. The Jogar junto screen listens and lists rooms heard in the
   last 4 s. A full room shows "Cheia".
3. Join by IP: a text field takes the host's IP (shown on the host's screen as "Seu IP").
4. Slots: the host gives each player the lowest free slot 0–3 and sends the slot table to
   everyone. The slot picks the remote player's vest, hat band and shirt color, and their
   tag "Jogador N" (N = slot + 1).
5. Presence: each player sends position, facing, fishing pose, cast progress and rod
   color 10 times a second (unreliable, ordered). Remote fishermen walk toward the latest
   position, run when more than 0.8 blocks behind, and teleport when more than 3 behind.
6. Catches: landing a fish sends {species, weight, length} reliably. Every other player
   gets a toast.
7. Leaving: "Sair da sala" leaves. When the host leaves, the room ends for everyone
   ("O anfitrião fechou a sala."). A failed join says "Não foi possível conectar."
8. Not shared in this slice (each phone keeps its own): world clock, day/night, fish in
   the water, gathering spots, farm, shop and coins. That is listed in §5 and is the next
   coop step.
9. Untrusted input: every presence packet is validated (size, types, color) and clamped.
   Bad packets are dropped. Beacon names are cut to 32 characters and cannot inject fields.

## 4. Formulas
- Presence bandwidth per player: 10 Hz × ~60 bytes ≈ 0.6 KB/s. Each player receives
  3 × 0.6 ≈ 1.8 KB/s with 4 players. This is negligible on Wi-Fi.
- Remote smoothing: move at walk speed (3.25 blocks/s) or run speed (5.5 blocks/s).
  Running starts when the gap is > 0.8 blocks. Snapping happens when the gap is > 3 blocks
  (about 0.5 s of running). At 10 Hz updates (0.1 s apart), a running player moves
  ≤ 0.55 blocks between updates, so smoothing never needs to snap during normal play.

## 5. Edge Cases
- Two players in one spot: allowed. Fishermen do not collide with each other.
- The host's day ends (sleep) but the guest's doesn't: clocks are not shared yet, so each
  phone keeps its own time. This is a known gap, deferred to the next coop step.
- A packet arrives from a peer with no slot yet: presence is ignored until the slot table
  arrives.
- The router blocks broadcast (common in guest networks): the list stays on
  "Procurando salas…". Join by IP still works.
- No Wi-Fi: "Seu IP: sem Wi-Fi". Creating a room still works (useful with a hotspot).
- Android permissions needed in the export preset: `INTERNET`, `ACCESS_NETWORK_STATE`,
  `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (for receiving the broadcast).
  There is no export preset yet (Android SDK not reachable in the build session). Add
  these when the preset is created.

## 6. Dependencies
- Uses: `Fisherman` (remote avatars), `FishingMachine`/`GameState.fish_caught` (catch
  announcements), `Screens` (Jogar junto), `Texts`.
- Used by: future shared-world coop (shared clock, farm and spots) and diving with friends.

## 7. Tuning Knobs
| Knob | Where | Default | Safe range | Effect |
|---|---|---|---|---|
| `DEFAULT_PORT` | `net_session.gd` | 7777 | 1024–65535 | Game port |
| `SEND_HZ` | `net_session.gd` | 10 | 5–30 | Presence rate (smoothness vs. traffic) |
| `MAX_PLAYERS` | `net_session.gd` | 4 | 2–4 | Room size (the brief says 4) |
| `LanBeacon.INTERVAL` / `TIMEOUT` | `lan_beacon.gd` | 1 s / 4 s | timeout ≥ 3× interval | Room list freshness |
| `SNAP_DISTANCE` / `RUN_DISTANCE` | `remote_players.gd` | 3 / 0.8 blocks | snap > run | Remote smoothing |

These are network constants, not gameplay balance. They live in code next to their
protocol, with the rationale above.

## 8. Acceptance Criteria
- [x] AC1: A snapshot survives a wire round trip. Malformed snapshots are rejected, and out-of-range values are clamped.
- [x] AC2: Beacons round-trip. Foreign or malformed packets are ignored, and a room name cannot inject fields.
- [x] AC3 (integration, two real processes on 127.0.0.1): the host and client each receive the other's presence and catch. The host is slot 0 and the client slot 1. `tests/integration/net/run_coop_test.sh`, PASS 2026-11-18. The timeout failure path was seen failing on the first run.
- [x] AC4 (visual, two full games): the host's room screen ("Anfitrião · 2/4", "Jogador 2 entrou!"), and the guest's fisherman on the pier with the "Jogador 2" tag and the catch toast. Evidence: `production/qa/evidence/coop/01–02`.
- [ ] AC5: Two real Android phones on one Wi-Fi. **NOT VERIFIED**: no Android build is possible in this environment.

AC1–AC2: `tests/unit/net/net_wire_test.gd` (7 tests).
