extends MiniSuite
## Harpoon dive rules (design/gdd/diving.md acceptance criteria).

const TOLERANCE: float = 0.0001


func _make() -> Array:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	var rng := RandomSource.new(9)
	var dive := Dive.new(data, state, FishRoller.new(data, state, rng), rng)
	return [data, state, dive]


## Puts one fish straight ahead of the diver at [param distance] blocks.
func _fish_ahead(dive: Dive, distance: float) -> Dive.DiveFish:
	var f: Dive.DiveFish = dive.fish[0]
	f.pos = dive.diver + Vector2.RIGHT * distance
	f.vel = Vector2.ZERO
	for other: Dive.DiveFish in dive.fish:
		if other != f:
			other.pos = dive.diver + Vector2(0.0, 5.0) # Out of the shot line.
	return f


func test_start_spends_energy_fills_air_and_spawns_fish() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var dive: Dive = s[2]
	var before: float = state.energy
	assert_eq(dive.start(), Dive.StartResult.OK, "start")
	assert_near(state.energy, before - float(data.dive["energy_cost"]), TOLERANCE, "energy")
	assert_near(dive.oxygen, float(data.dive["oxygen_seconds"]), TOLERANCE, "air")
	assert_eq(dive.fish.size(), int(data.dive["fish_count"]), "fish count")


func test_start_refused_without_energy_changes_nothing() -> void:
	var s: Array = _make()
	var state: GameState = s[1]
	var dive: Dive = s[2]
	state.energy = 1.0
	assert_eq(dive.start(), Dive.StartResult.NO_ENERGY, "refused")
	assert_near(state.energy, 1.0, TOLERANCE, "energy untouched")
	assert_true(not dive.active, "not diving")


func test_level_one_dive_only_has_common_fish() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var dive: Dive = s[2]
	dive.start()
	for f: Dive.DiveFish in dive.fish:
		assert_eq(data.species_by_id(f.fish.id).rarity, 0, "%s is common" % f.fish.id)


func test_harpoon_hits_fish_in_line_and_range() -> void:
	var s: Array = _make()
	var dive: Dive = s[2]
	dive.start()
	var f: Dive.DiveFish = _fish_ahead(dive, 3.0)
	assert_true(dive.shoot(Vector2.RIGHT) == f, "hit")
	assert_eq(dive.haul.size(), 1, "in haul")
	assert_true(not dive.fish.has(f), "removed from water")


func test_harpoon_misses_out_of_range_and_behind() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var dive: Dive = s[2]
	dive.start()
	_fish_ahead(dive, float(data.dive["harpoon_range"]) + 0.5)
	assert_true(dive.shoot(Vector2.RIGHT) == null, "too far")
	dive.step(float(data.dive["harpoon_reload"]), Vector2.ZERO)
	_fish_ahead(dive, 2.0)
	assert_true(dive.shoot(Vector2.LEFT) == null, "behind")


func test_harpoon_must_reload() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var dive: Dive = s[2]
	dive.start()
	_fish_ahead(dive, 2.0)
	dive.shoot(Vector2.LEFT) # Miss, starts the reload.
	assert_true(not dive.can_shoot(), "reloading")
	assert_true(dive.shoot(Vector2.RIGHT) == null, "no shot while reloading")
	dive.step(float(data.dive["harpoon_reload"]), Vector2.ZERO)
	assert_true(dive.can_shoot(), "reloaded")


func test_surfacing_keeps_the_whole_haul() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var dive: Dive = s[2]
	dive.start()
	for i: int in 3:
		_fish_ahead(dive, 2.0)
		dive.shoot(Vector2.RIGHT)
		dive.step(float(data.dive["harpoon_reload"]), Vector2.ZERO)
	assert_eq(dive.surface().size(), 3, "all kept")


func test_running_out_of_air_keeps_half_rounded_up() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var dive: Dive = s[2]
	var kept: Array = []
	dive.ended.connect(func(_r: Dive.EndReason, k: Array[GameState.Catch]) -> void: kept.assign(k))
	dive.start()
	for i: int in 3:
		_fish_ahead(dive, 2.0)
		dive.shoot(Vector2.RIGHT)
		dive.step(float(data.dive["harpoon_reload"]), Vector2.ZERO)
	dive.step(float(data.dive["oxygen_seconds"]), Vector2.ZERO)
	assert_true(not dive.active, "dive over")
	assert_eq(kept.size(), 2, "ceil(3 * 0.5)")


func test_kept_count_formula() -> void:
	assert_eq(Dive.kept_count(Dive.EndReason.SURFACED, 5, 0.5), 5, "surfaced")
	assert_eq(Dive.kept_count(Dive.EndReason.OUT_OF_AIR, 5, 0.5), 3, "out of air 5")
	assert_eq(Dive.kept_count(Dive.EndReason.OUT_OF_AIR, 0, 0.5), 0, "nothing")
	assert_eq(Dive.kept_count(Dive.EndReason.OUT_OF_AIR, 1, 0.5), 1, "one fish kept")


func test_diver_and_fish_stay_inside_the_arena() -> void:
	var s: Array = _make()
	var dive: Dive = s[2]
	dive.start()
	for i: int in 400:
		dive.step(0.05, Vector2(1.0, 1.0))
	assert_true(dive.diver.x <= dive.arena.x - 0.5 and dive.diver.y <= dive.arena.y - 0.5, "diver inside")
	for f: Dive.DiveFish in dive.fish:
		assert_true(f.pos.x >= 0.5 and f.pos.x <= dive.arena.x - 0.5 and f.pos.y >= 0.5 and f.pos.y <= dive.arena.y - 0.5, "fish inside")


func test_record_catch_is_shared_with_fishing() -> void:
	var s: Array = _make()
	var state: GameState = s[1]
	var fish := GameState.Catch.new()
	fish.id = "perca"
	fish.weight = 1.0
	fish.length = 30.0
	var first: Array[bool] = state.record_catch(fish)
	var heavier := GameState.Catch.new()
	heavier.id = "perca"
	heavier.weight = 1.2
	heavier.length = 32.0
	var second: Array[bool] = state.record_catch(heavier)
	assert_true(first[0] and not first[1], "first is new")
	assert_true(not second[0] and second[1], "second is a record")
	assert_eq(state.book["perca"].count, 2, "count")
