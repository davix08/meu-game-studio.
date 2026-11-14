extends GdUnitTestSuite
## HealthComponent: damage, healing, invulnerability, death.


func _make(max_hp: int) -> HealthComponent:
	var h: HealthComponent = auto_free(HealthComponent.new())
	h.max_health = max_hp
	h.reset()
	return h


func test_take_damage_reduces_health() -> void:
	var h := _make(3)
	var applied := h.take_damage(1)
	assert_int(applied).is_equal(1)
	assert_int(h.current_health).is_equal(2)


func test_take_damage_never_goes_below_zero() -> void:
	var h := _make(3)
	var applied := h.take_damage(10)
	assert_int(applied).is_equal(3)
	assert_int(h.current_health).is_equal(0)
	assert_bool(h.is_dead()).is_true()


func test_take_damage_while_invulnerable_does_nothing() -> void:
	var h := _make(3)
	h.invulnerable = true
	assert_int(h.take_damage(1)).is_equal(0)
	assert_int(h.current_health).is_equal(3)


func test_died_emitted_once_at_zero() -> void:
	var h := _make(2)
	var deaths := [0]
	h.died.connect(func() -> void: deaths[0] += 1)
	h.take_damage(2)
	h.take_damage(1)
	assert_int(deaths[0]).is_equal(1)


func test_heal_caps_at_max() -> void:
	var h := _make(5)
	h.take_damage(2)
	assert_int(h.heal(10)).is_equal(2)
	assert_int(h.current_health).is_equal(5)


func test_fraction_reports_remaining_ratio() -> void:
	var h := _make(4)
	h.take_damage(1)
	assert_float(h.fraction()).is_equal_approx(0.75, 0.0001)
