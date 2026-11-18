extends MiniSuite
## House and yard decoration (design/gdd/decoration.md acceptance criteria).


func _make() -> Array:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	state.coins = 1000
	state.level = 5
	return [data, state, Decor.new(data, state)]


func test_place_pays_the_price() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var decor: Decor = s[2]
	assert_eq(decor.place("casa_1", "vaso"), Decor.Result.OK, "placed")
	assert_eq(state.decor["casa_1"], "vaso", "in slot")
	assert_eq(state.coins, 1000 - data.decor_by_id("vaso").price, "paid")


func test_swap_refunds_half_of_the_old_piece() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var decor: Decor = s[2]
	decor.place("casa_1", "lanterna")
	var after_first: int = state.coins
	decor.place("casa_1", "banco")
	var expected: int = after_first + floori(data.decor_by_id("lanterna").price * data.decor_refund) - data.decor_by_id("banco").price
	assert_eq(state.coins, expected, "swap cost")
	assert_eq(state.decor["casa_1"], "banco", "swapped")


func test_remove_refunds_and_empties() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var decor: Decor = s[2]
	decor.place("casa_2", "estatua")
	var before: int = state.coins
	assert_eq(decor.remove("casa_2"), Decor.Result.OK, "removed")
	assert_eq(state.coins, before + floori(data.decor_by_id("estatua").price * data.decor_refund), "refund")
	assert_true(not state.decor.has("casa_2"), "empty")
	assert_eq(decor.remove("casa_2"), Decor.Result.EMPTY, "nothing to remove")


func test_blockers_level_coins_same_unknown() -> void:
	var s: Array = _make()
	var state: GameState = s[1]
	var decor: Decor = s[2]
	state.level = 1
	assert_eq(decor.place_blocker("casa_1", "estatua"), Decor.Result.LOCKED_BY_LEVEL, "level")
	state.level = 5
	state.coins = 10
	assert_eq(decor.place("casa_1", "vaso"), Decor.Result.NOT_ENOUGH_COINS, "coins")
	assert_eq(state.coins, 10, "nothing spent")
	assert_eq(decor.place_blocker("nowhere", "vaso"), Decor.Result.UNKNOWN, "slot")
	assert_eq(decor.place_blocker("casa_1", "nothing"), Decor.Result.UNKNOWN, "item")
	state.coins = 1000
	decor.place("casa_1", "vaso")
	assert_eq(decor.place_blocker("casa_1", "vaso"), Decor.Result.SAME, "same")


func test_trophy_picks_the_heaviest_fish() -> void:
	var s: Array = _make()
	var state: GameState = s[1]
	var decor: Decor = s[2]
	assert_eq(decor.best_fish()[0], "", "no fish yet")
	for pair: Array in [["tilapia", 1.4], ["carpa", 6.2], ["perca", 0.9]]:
		var f := GameState.Catch.new()
		f.id = pair[0]
		f.weight = pair[1]
		state.record_catch(f)
	assert_eq(decor.best_fish()[0], "carpa", "heaviest")


func test_save_round_trip_keeps_decor_and_drops_unknown() -> void:
	var s: Array = _make()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var decor: Decor = s[2]
	decor.place("quintal_1", "bandeira")
	var save: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.to_dict(state)))
	save["decor"]["fake_slot"] = "vaso"
	save["decor"]["casa_3"] = "fake_item"
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, save)
	assert_eq(loaded.decor.get("quintal_1"), "bandeira", "kept")
	assert_eq(loaded.decor.size(), 1, "unknown dropped")


func test_every_slot_stands_on_free_ground() -> void:
	var data: GameData = GameData.load_from_dir()
	var look: WorldLook = WorldLook.load_file()
	var grid := WorldGrid.new()
	TownPlan.plan(grid, look)
	LakeEstate.plan(grid, look)
	for slot_id: String in data.decor_slots:
		var p: Vector2 = data.decor_slots[slot_id]
		assert_true(grid.box_free(p.x, p.y, 0.3, 0.3), "%s on free ground" % slot_id)
