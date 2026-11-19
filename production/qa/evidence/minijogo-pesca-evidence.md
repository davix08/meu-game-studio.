# Evidence: minijogo de pesca com o visual novo (2026-11-19)

**Change**: the fishing fight is now drawn by `src/ui/fight_panel.gd`, in a chunky pixel style after the user's reference picture (our own art, drawn in code).

The panel shows:
- a wooden board under a fishing rod with its reel;
- lures and a glass tube for the catch progress;
- an underwater window with sand, swaying seaweed, coral and bubbles, where the fish swims and the hook hangs on its line.

The rules of `FishingMachine` are unchanged: the fish swims in the middle of the catch zone (a lighter band), and the hook is the marker raised by holding PUXAR. While the fight is on, the side buttons and the joystick are hidden, so only PUXAR remains. The hint reads "Segure PUXAR para manter o anzol no peixe".

**Captured**: Godot 4.7.2, Xvfb, gl_compatibility (brighter than the phone).
**Sign-off**: pending the user on the phone.
