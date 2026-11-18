extends MiniSuite
## Gathering and the bench (design/gdd/gathering-crafting.md acceptance criteria).


func _setup() -> Array:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	return [data, state, Gathering.new(data, state)]


func _first_node(data: GameData, kind: String) -> GameData.GatherNode:
	for n: GameData.GatherNode in data.gather_nodes:
		if n.kind == kind:
			return n
	return null


func test_new_game_starts_without_rod_and_cannot_cast() -> void:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	var machine := FishingMachine.new(data, state, RandomSource.new(1), null, FishRoller.new(data, state, RandomSource.new(1)), Progression.new(data, state))
	assert_true(not state.has_rod(), "new game has no rod")
	assert_eq(state.rods_owned.size(), 0, "rods owned")
	assert_eq(machine.cast_blocker(), FishingMachine.CastResult.NO_ROD, "cast blocker")


func test_gather_adds_material_and_hides_spot() -> void:
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var g: Gathering = s[2]
	var node: GameData.GatherNode = _first_node(data, "fibra")
	assert_eq(g.gather(node.id), Gathering.Result.OK, "first gather")
	assert_eq(state.material_count("fibra"), data.gather_amount["fibra"], "fibra count")
	assert_true(not g.is_available(node.id), "spot hidden")
	assert_eq(g.gather(node.id), Gathering.Result.GONE, "second gather")


func test_spot_comes_back_after_respawn_minutes() -> void:
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var g: Gathering = s[2]
	var node: GameData.GatherNode = _first_node(data, "galho")
	g.gather(node.id)
	state.minutes += data.gather_respawn["galho"] - 1.0
	assert_true(not g.is_available(node.id), "still gone one minute early")
	state.minutes += 1.0
	assert_true(g.is_available(node.id), "back on time")


func test_spot_comes_back_across_days() -> void:
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var g: Gathering = s[2]
	var node: GameData.GatherNode = _first_node(data, "galho")
	g.gather(node.id)
	state.day += 1
	assert_true(g.is_available(node.id), "next day")


func test_artisan_rod_needs_all_materials() -> void:
	var s: Array = _setup()
	var state: GameState = s[1]
	var g: Gathering = s[2]
	state.materials = {"galho": 1, "fibra": 3}
	assert_eq(g.craft("vara_artesanal"), Gathering.Result.MISSING, "no linha yet")
	assert_eq(state.material_count("fibra"), 3, "nothing consumed on failure")


func test_full_first_rod_path_equips_artisan_rod() -> void:
	# The intended first minutes: gather every galho and fibra spot once, then craft.
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var g: Gathering = s[2]
	for n: GameData.GatherNode in data.gather_nodes:
		if n.kind == "galho" or n.kind == "fibra":
			g.gather(n.id)
	assert_eq(g.craft("linha"), Gathering.Result.OK, "linha")
	assert_eq(g.craft("vara_artesanal"), Gathering.Result.OK, "rod")
	assert_true(state.has_rod(), "has a rod")
	assert_eq(state.rod, "artesanal", "equipped")
	assert_eq(g.craft("vara_artesanal"), Gathering.Result.OWNED, "only once")


func test_worm_bait_recipe_unlocks_and_equips_bait() -> void:
	var s: Array = _setup()
	var state: GameState = s[1]
	var g: Gathering = s[2]
	state.materials = {"minhoca": 4}
	assert_eq(g.craft("isca_minhoca"), Gathering.Result.OK, "craft")
	assert_true(state.baits_owned.has("minhoca"), "bait owned")
	assert_eq(state.bait, "minhoca", "bait equipped")
	assert_eq(state.material_count("minhoca"), 0, "worms consumed")


func test_artisan_rod_is_not_sold_in_shop() -> void:
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	state.coins = 99999
	assert_eq(Economy.new(data, state).buy_gear(Economy.GearKind.ROD, "artesanal"), Economy.Result.LOCKED_BY_LEVEL, "not for sale")
	assert_true(not state.rods_owned.has("artesanal"), "not owned")


func test_save_round_trip_keeps_materials_and_timers() -> void:
	var s: Array = _setup()
	var data: GameData = s[0]
	var state: GameState = s[1]
	var g: Gathering = s[2]
	var node: GameData.GatherNode = _first_node(data, "minhoca")
	g.gather(node.id)
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, JSON.parse_string(JSON.stringify(SaveGame.to_dict(state))))
	assert_eq(loaded.material_count("minhoca"), 1, "minhoca saved")
	assert_true(not Gathering.new(data, loaded).is_available(node.id), "timer saved")
	assert_true(not loaded.has_rod(), "still no rod")


func test_every_spot_stands_on_free_ground() -> void:
	var data: GameData = GameData.load_from_dir()
	var look: WorldLook = WorldLook.load_file()
	var grid := WorldGrid.new()
	TownPlan.plan(grid, look)
	LakeEstate.plan(grid, look)
	for n: GameData.GatherNode in data.gather_nodes:
		assert_true(grid.box_free(n.pos.x, n.pos.y, 0.2, 0.2), "%s is on a free block" % n.id)
