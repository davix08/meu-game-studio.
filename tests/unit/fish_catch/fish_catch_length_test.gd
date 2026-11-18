extends MiniSuite
## Fish size from weight (design/gdd/fish-catch.md, AC1–AC4).

const TOLERANCE: float = 0.001


func _data() -> GameData:
	return GameData.load_from_dir()


func test_length_at_weight_bounds_matches_cm_range() -> void:
	var data: GameData = _data()
	var roller := FishRoller.new(data, GameState.create_new(data), RandomSource.new(1))
	for sp: GameData.Species in data.species:
		assert_near(roller.fish_length(sp, sp.kg_min), sp.cm_min, TOLERANCE, "%s at kg_min" % sp.id)
		assert_near(roller.fish_length(sp, sp.kg_max), sp.cm_max, TOLERANCE, "%s at kg_max" % sp.id)


func test_length_heavier_fish_is_never_shorter() -> void:
	var data: GameData = _data()
	var roller := FishRoller.new(data, GameState.create_new(data), RandomSource.new(1))
	const STEPS: int = 50
	for sp: GameData.Species in data.species:
		var previous: float = -1.0
		for i: int in STEPS + 1:
			var w: float = lerpf(sp.kg_min, sp.kg_max, float(i) / STEPS)
			var cm: float = roller.fish_length(sp, w)
			assert_true(cm >= previous, "%s shorter at %s kg" % [sp.id, w])
			previous = cm


func test_length_tilapia_worked_example_is_41_cm() -> void:
	# The worked example in the GDD Formulas section: 1.4 kg tilápia -> 41 cm.
	var data: GameData = _data()
	var roller := FishRoller.new(data, GameState.create_new(data), RandomSource.new(1))
	assert_near(roller.fish_length(data.species_by_id("tilapia"), 1.4), 41.0, TOLERANCE, "tilapia 1.4 kg")


func test_length_out_of_range_weight_is_clamped() -> void:
	var data: GameData = _data()
	var sp: GameData.Species = data.species_by_id("tilapia")
	assert_near(FishRoller.length_for(sp, 0.0, 1.0, 0), sp.cm_min, TOLERANCE, "below range")
	assert_near(FishRoller.length_for(sp, 99.0, 1.0, 0), sp.cm_max, TOLERANCE, "above range")


func test_roll_catch_uses_one_random_draw() -> void:
	var data: GameData = _data()
	var rng := RandomSource.new(7)
	var roller := FishRoller.new(data, GameState.create_new(data), rng)
	roller.roll_catch(data.species_by_id("carpa"))
	var reference := RandomSource.new(7)
	reference.next_float()
	assert_eq(rng.next_float(), reference.next_float(), "next draw after roll_catch")


func test_roll_catch_sets_length_from_weight() -> void:
	var data: GameData = _data()
	var roller := FishRoller.new(data, GameState.create_new(data), RandomSource.new(3))
	var sp: GameData.Species = data.species_by_id("salmao")
	var fish: GameState.Catch = roller.roll_catch(sp)
	assert_near(fish.length, roller.fish_length(sp, fish.weight), TOLERANCE, "length matches weight")


func test_save_round_trip_keeps_length() -> void:
	var data: GameData = _data()
	var state: GameState = GameState.create_new(data)
	var fish := GameState.Catch.new()
	fish.id = "carpa"
	fish.weight = 5.0
	fish.length = 70.0
	fish.value = 30
	state.bag.append(fish)
	var entry := GameState.BookEntry.new()
	entry.count = 2
	entry.best = 5.0
	entry.longest = 70.0
	state.book["carpa"] = entry
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, JSON.parse_string(JSON.stringify(SaveGame.to_dict(state))))
	assert_near(loaded.bag[0].length, 70.0, TOLERANCE, "bag length")
	assert_near(loaded.book["carpa"].longest, 70.0, TOLERANCE, "book longest")


func test_old_save_without_length_derives_it_from_weight() -> void:
	var data: GameData = _data()
	var state: GameState = GameState.create_new(data)
	var save: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.to_dict(state)))
	save["bag"] = [{"id": "tilapia", "weight": 1.4, "value": 12}]
	save["book"] = {"tilapia": {"count": 1, "best": 1.4}}
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, save)
	assert_near(loaded.bag[0].length, 41.0, TOLERANCE, "bag length from weight")
	assert_near(loaded.book["tilapia"].longest, 41.0, TOLERANCE, "book longest from best")
