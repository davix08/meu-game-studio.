extends GdUnitTestSuite
## ResultsGrade: score and letter grade.


func test_perfect_run_scores_full_marks() -> void:
	var s := ResultsGrade.score(60.0, 3, 3, 3, 5)
	assert_float(s).is_equal_approx(100.0, 0.001)
	assert_str(ResultsGrade.letter(s)).is_equal("S")


func test_slow_run_without_extras_is_low_grade() -> void:
	var s := ResultsGrade.score(480.0, 1, 3, 0, 0)
	assert_str(ResultsGrade.letter(s)).is_equal("D")


func test_letter_boundaries() -> void:
	assert_str(ResultsGrade.letter(80.0)).is_equal("A")
	assert_str(ResultsGrade.letter(79.9)).is_equal("B")
