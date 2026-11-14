extends GdUnitTestSuite
## Boss.phase_for_fraction: phase selection from health thresholds.

const THRESHOLDS := [1.0, 0.66, 0.33]


func _t() -> PackedFloat32Array:
	return PackedFloat32Array(THRESHOLDS)


func test_full_health_is_first_phase() -> void:
	assert_int(Boss.phase_for_fraction(1.0, _t())).is_equal(0)


func test_just_above_threshold_stays_in_phase() -> void:
	assert_int(Boss.phase_for_fraction(0.67, _t())).is_equal(0)


func test_at_threshold_enters_next_phase() -> void:
	assert_int(Boss.phase_for_fraction(0.66, _t())).is_equal(1)


func test_low_health_is_last_phase() -> void:
	assert_int(Boss.phase_for_fraction(0.1, _t())).is_equal(2)
