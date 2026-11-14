extends GdUnitTestSuite
## TouchControls.snap_to_8_directions: joystick to digital directions.


func test_inside_deadzone_is_neutral() -> void:
	assert_vector(TouchControls.snap_to_8_directions(Vector2(0.1, 0.05), 0.25)).is_equal(Vector2.ZERO)


func test_mostly_right_snaps_right() -> void:
	assert_vector(TouchControls.snap_to_8_directions(Vector2(0.9, 0.2), 0.25)).is_equal(Vector2(1, 0))


func test_diagonal_snaps_to_diagonal() -> void:
	assert_vector(TouchControls.snap_to_8_directions(Vector2(0.6, -0.6), 0.25)).is_equal(Vector2(1, -1))
