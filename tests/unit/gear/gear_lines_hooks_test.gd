extends MiniSuite
## Lines and hooks (design/gdd/gear-upgrades.md acceptance criteria).

const TOLERANCE: float = 0.0001
const DT: float = 0.05
const MAX_STEPS: int = 2000

var _ended: int = -1


func _make(line: String) -> Array:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	state.rod = "bambu"
	state.rods_owned = PackedStringArray(["bambu"])
	state.line = line
	state.lines_owned = PackedStringArray([line])
	var rng := RandomSource.new(5)
	var machine := FishingMachine.new(data, state, rng, null, FishRoller.new(data, state, rng), Progression.new(data, state))
	return [data, state, machine]


func _fight_until_end(machine: FishingMachine, sp: GameData.Species, kg: float) -> int:
	_ended = -1
	machine.fishing_ended.connect(func(reason: FishingMachine.EndReason) -> void: _ended = reason)
	var fish := GameState.Catch.new()
	fish.id = sp.id
	fish.weight = kg
	machine.species = sp
	machine.hooked = fish
	machine.overweight = kg > machine.line_max_kg()
	machine.call("_start_fight")
	for i: int in MAX_STEPS:
		machine.step(DT, false, false) # Never pulling: progress drains to zero.
		if machine.phase == FishingMachine.Phase.IDLE:
			break
	return _ended


func test_line_mult_is_one_up_to_max_kg() -> void:
	var m: FishingMachine = _make("nylon")[2]
	assert_near(m.line_mult(6.0), 1.0, TOLERANCE, "at max_kg")
	assert_near(m.line_mult(0.5), 1.0, TOLERANCE, "light fish")


func test_line_mult_drops_with_square_root_over_max() -> void:
	# Worked example in the GDD: improvised line (2 kg), 6 kg tucunaré -> (2/6)^0.5 = 0.577.
	var m: FishingMachine = _make("improvisada")[2]
	assert_near(m.line_mult(6.0), sqrt(2.0 / 6.0), TOLERANCE, "6 kg on 2 kg line")


func test_line_mult_never_below_floor() -> void:
	var s: Array = _make("nylon")
	var data: GameData = s[0]
	var m: FishingMachine = s[2]
	assert_near(m.line_mult(20000.0), data.tune("line_min_mult"), TOLERANCE, "whale shark on nylon")


func test_overweight_fish_escaping_breaks_the_line() -> void:
	var s: Array = _make("improvisada")
	var data: GameData = s[0]
	var reason: int = _fight_until_end(s[2], data.species_by_id("tucunare"), 5.0)
	assert_eq(reason, FishingMachine.EndReason.LINE_BROKE, "end reason")


func test_light_fish_escaping_is_line_slack() -> void:
	var s: Array = _make("nylon")
	var data: GameData = s[0]
	var reason: int = _fight_until_end(s[2], data.species_by_id("tilapia"), 1.0)
	assert_eq(reason, FishingMachine.EndReason.LINE_SLACK, "end reason")


func test_crafting_the_rod_gives_the_improvised_line() -> void:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	assert_eq(state.line, "", "no line at start")
	state.materials = {"galho": 1, "fibra": 3, "linha": 1}
	Gathering.new(data, state).craft("vara_artesanal")
	assert_eq(state.line, "improvisada", "line equipped")
	assert_true(state.lines_owned.has("improvisada"), "line owned")


func test_buy_line_and_hook_equips_them() -> void:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	state.coins = 1000
	var economy := Economy.new(data, state)
	assert_eq(economy.buy_gear(Economy.GearKind.LINE, "nylon"), Economy.Result.OK, "buy nylon")
	assert_eq(state.line, "nylon", "nylon equipped")
	assert_eq(economy.buy_gear(Economy.GearKind.HOOK, "aco"), Economy.Result.OK, "buy hook")
	assert_eq(state.hook, "aco", "hook equipped")
	assert_eq(state.coins, 1000 - data.line_by_id("nylon").price - data.hook_by_id("aco").price, "coins spent")
	assert_eq(economy.buy_gear(Economy.GearKind.LINE, "improvisada"), Economy.Result.LOCKED_BY_LEVEL, "improvised line not sold")


func test_hook_widens_the_react_window_and_zone() -> void:
	var s: Array = _make("nylon")
	var data: GameData = s[0]
	var state: GameState = s[1]
	var plain: FishingMachine = s[2]
	plain.species = data.species_by_id("carpa")
	var fish := GameState.Catch.new()
	fish.id = "carpa"
	fish.weight = 2.0
	plain.hooked = fish
	plain.call("_start_fight")
	var plain_zone: float = plain.zone_width
	plain.cancel()
	state.hook = "pro"
	plain.species = data.species_by_id("carpa")
	plain.hooked = fish
	plain.call("_start_fight")
	assert_near(plain.zone_width - plain_zone, data.hook_by_id("pro").zone, TOLERANCE, "zone bonus")


func test_old_save_with_rod_gets_a_nylon_line() -> void:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	var save: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.to_dict(state)))
	save.erase("lines_owned")
	save.erase("line")
	save["rods_owned"] = ["bambu"]
	save["rod"] = "bambu"
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, save)
	assert_eq(loaded.line, data.fixed_text("legacy_line"), "legacy line")


func test_save_round_trip_keeps_line_and_hook() -> void:
	var data: GameData = GameData.load_from_dir()
	var state: GameState = GameState.create_new(data)
	state.coins = 1000
	var economy := Economy.new(data, state)
	economy.buy_gear(Economy.GearKind.LINE, "nylon")
	economy.buy_gear(Economy.GearKind.HOOK, "aco")
	var loaded: GameState = GameState.create_new(data)
	SaveGame.apply(loaded, data, JSON.parse_string(JSON.stringify(SaveGame.to_dict(state))))
	assert_eq(loaded.line, "nylon", "line")
	assert_eq(loaded.hook, "aco", "hook")
