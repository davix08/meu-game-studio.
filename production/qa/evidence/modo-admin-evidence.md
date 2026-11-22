# Evidence: owner admin mode (2026-11-22)

The owner's test mode lives in Ajustes › Modo admin.

## Two locks

- **Debug builds only**: the button and the code run only in debug builds (`OS.is_debug_build()`), that is, the editor and debug exports. Release exports have no admin mode.
- **Password**: the owner creates it in the game the first time.
  - Only a salted SHA-256 hash is kept, in `user://admin.json` on that device. It is never in the code nor in the repository.
  - Five wrong tries lock it for 60 s.

## Buttons

- +10,000 and +100,000 coins.
- +100 of every good.
- +1 farm level, or the top level.
- Full energy.
- Axe and pickaxe.
- Finish every timer now.
- Silo and barn +5 levels.
- Leave the mode, or erase the password from this device.

## Checks

The test passed every step:
- the mode is available in a debug build;
- a short password is refused;
- the password file holds no plain text;
- a wrong password is refused and the right one accepted;
- the lock holds after 5 wrong tries;
- every cheat applies: coins 100030, wood 100, level 20, tools, the plot ripe, silo capacity 175.

**Screenshots**: 01 settings, 02 password, 03 panel.
