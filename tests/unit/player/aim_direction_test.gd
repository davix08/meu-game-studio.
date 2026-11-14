extends GdUnitTestSuite
## Aim.direction: eight-way aiming rules.


func test_neutral_input_aims_where_facing() -> void:
	assert_vector(Aim.direction(Vector2.ZERO, -1, true, false)).is_equal(Vector2.LEFT)


func test_up_only_aims_straight_up() -> void:
	assert_vector(Aim.direction(Vector2(0, -1), 1, true, false)).is_equal(Vector2.UP)


func test_up_right_aims_diagonal() -> void:
	var d := Aim.direction(Vector2(1, -1), 1, true, false)
	assert_vector(d).is_equal_approx(Vector2(1, -1).normalized(), Vector2(0.001, 0.001))


func test_down_on_ground_without_lock_shoots_forward() -> void:
	assert_vector(Aim.direction(Vector2(0, 1), 1, true, false)).is_equal(Vector2.RIGHT)


func test_down_in_air_aims_down() -> void:
	assert_vector(Aim.direction(Vector2(0, 1), 1, false, false)).is_equal(Vector2.DOWN)


func test_down_on_ground_with_lock_aims_diagonal_down() -> void:
	var d := Aim.direction(Vector2(0, 1), -1, true, true)
	assert_vector(d).is_equal_approx(Vector2(-1, 1).normalized(), Vector2(0.001, 0.001))
