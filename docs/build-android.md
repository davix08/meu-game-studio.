# Building the Android test APK

How the test APK of 2026-11-22 was made (Godot 4.7.2, no Gradle, debug build: the owner's
admin mode is available in it).

1. Export templates 4.7.2: only `android_debug.apk`, `android_release.apk` and `version.txt`
   from `Godot_v4.7.2-stable_export_templates.tpz`, into
   `~/.local/share/godot/export_templates/4.7.2.stable/`.
2. Android SDK: the full SDK is not needed without Gradle. Godot only checks for
   `platform-tools/adb` and `build-tools/<ver>/apksigner`; `apksigner` and `zipalign` came from
   the Ubuntu packages of the same names. Set Editor Settings
   `export/android/android_sdk_path` to that folder.
3. `export_presets.cfg` (not in git: it may hold keystore passwords) with an "Android" preset:
   `gradle_build/use_gradle_build=false`, arm64-v8a and armeabi-v7a, `package/signed=false`,
   `package/unique_name="com.lakebound.jogo"`, `screen/immersive_mode=true`.
4. `godot --headless --path . --import`, then
   `godot --headless --path . --export-debug "Android" lakebound-unsigned.apk`.
5. `zipalign -f -p 4 lakebound-unsigned.apk aligned.apk`, then
   `apksigner sign --ks debug.keystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out Lakebound-teste.apk aligned.apk`
   and `apksigner verify Lakebound-teste.apk`.

project.godot sets `textures/vram_compression/import_etc2_astc=true` (needed on Android) and a
landscape (sensor) orientation.

An APK signed with a different debug key cannot install over the old one: uninstall first.
For the store, make a release keystore (keep it out of git) and use `--export-release`.
