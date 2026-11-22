# Evidence: test APK, more storage, chest in the house (2026-11-22)

| Asked | Result |
|---|---|
| An APK to test | `Lakebound-teste.apk` (74 MB, debug, arm64-v8a + armeabi-v7a) exported with Godot 4.7.2 and signed with a debug key; `apksigner verify`: v2 and v3 signatures OK; the game files (scenes, models, sounds, data) are inside. Steps: docs/build-android.md. Not run on a phone or emulator here. |
| More room in the barn | Barn 50 → 150 (+50 per upgrade, up to 8 chests); silo 50 → 100 (+50 per upgrade) |
| A chest in the house | "Baú" by the north wall of the house, +120 for the barn goods, filled after the barn chests; it opens the chests screen. Test: capacity 270, chests 75/75, 75/75, house 50/120 with 200 wood (`01`, `02`) |
