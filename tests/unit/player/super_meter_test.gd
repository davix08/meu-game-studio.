extends GdUnitTestSuite
## SuperMeter: filling by damage and parry, spending cards.


func test_add_damage_fills_fractional_cards() -> void:
	var m := SuperMeter.new(5, 0.01, 1.0)
	m.add_damage(150)
	assert_float(m.value).is_equal_approx(1.5, 0.0001)
	assert_int(m.full_cards()).is_equal(1)


func test_add_parry_adds_one_card() -> void:
	var m := SuperMeter.new(5, 0.01, 1.0)
	m.add_parry()
	assert_int(m.full_cards()).is_equal(1)


func test_meter_is_capped_at_max_cards() -> void:
	var m := SuperMeter.new(5, 0.01, 1.0)
	for i in 10:
		m.add_parry()
	assert_float(m.value).is_equal_approx(5.0, 0.0001)
	assert_bool(m.is_full()).is_true()


func test_spend_without_enough_cards_fails_and_keeps_value() -> void:
	var m := SuperMeter.new(5, 0.01, 1.0)
	m.add_damage(50)
	assert_bool(m.spend(1)).is_false()
	assert_float(m.value).is_equal_approx(0.5, 0.0001)


func test_spend_removes_whole_cards() -> void:
	var m := SuperMeter.new(5, 0.01, 1.0)
	m.add_parry()
	m.add_parry()
	assert_bool(m.spend(1)).is_true()
	assert_int(m.full_cards()).is_equal(1)
