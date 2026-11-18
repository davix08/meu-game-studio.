# Tests

## Unit tests (run now)

```
godot --headless --path . --import
godot --headless --path . -s res://tests/run_unit.gd
```

Exit 0 means all passed. Exit 1 means a test failed, a suite did not load, or no tests were found.

The runner (`tests/run_unit.gd`) and the base class (`tests/mini_suite.gd`) are a
stand-in for gdUnit4, which could not be downloaded in the session that wrote
them. When `/test-setup` installs gdUnit4 (`addons/gdUnit4/`), move each suite to
`extends GdUnitTestSuite`. The asserts map one-to-one. `commands.test` in
`project.yaml` already names the gdUnit4 runner.

Naming: `tests/unit/<system>/<system>_<feature>_test.gd`, functions `test_<scenario>_<expected>`.

## Integration tests

```
bash tests/integration/net/run_coop_test.sh
```

Two real Godot processes (host and client on 127.0.0.1) exchange coop presence and a
catch. Exit 0 only when both sides pass.

## Visual evidence

Scripts in `tests/visual/` run the real game windowed and save PNGs to
`production/qa/evidence/`. On a machine without a display, use `xvfb-run -a`:

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 --rendering-driver opengl3 -s res://tests/visual/capture_fish_size.gd
```

Coop needs two games: start the guest first (headless, its own HOME so the saves don't
clash), then the host windowed:

```
HOME=/tmp/guesthome godot --headless --path . -s res://tests/visual/capture_coop.gd -- guest &
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 --rendering-driver opengl3 -s res://tests/visual/capture_coop.gd -- host
```
