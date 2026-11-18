class_name MiniSuite
extends RefCounted
## Minimal test base used until gdUnit4 is installed (/test-setup). Each test_* method
## runs on a fresh instance; failed asserts are collected, not thrown.
##
## Usage: extend it in tests/unit/<system>/<system>_<feature>_test.gd and run
## [code]godot --headless --path . -s res://tests/run_unit.gd[/code] (exit 1 on a failure).

var failures: PackedStringArray = PackedStringArray()


## Records a failure when [param condition] is false.
func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Records a failure when [param actual] differs from [param expected] by more than [param tolerance].
func assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


## Records a failure when [param actual] != [param expected].
func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
