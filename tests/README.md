# Tests

`tests/.gdignore` makes the Godot editor skip this folder, because the gdUnit4
addon is not installed yet and every suite fails to parse without it
("Could not find base class GdUnitTestSuite").

**Delete `tests/.gdignore` once `/test-setup` has installed gdUnit4** in
`addons/gdUnit4/`, or the test runner will not find these suites.
