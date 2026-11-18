extends SceneTree
## Visual evidence for design/gdd/gear-upgrades.md: the shop's Linhas tab and the
## "too heavy for your line" warning in a fight. Run windowed:
## godot --path . -s res://tests/visual/capture_gear.gd (overwrites this machine's save).

const OUT: String = "res://production/qa/evidence/gear/"

var _main: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	_main.set("_fresh_start", true)
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(30)
	var data: GameData = _main.get("_data")
	var state: GameState = _main.get("_state")
	var gathering: Gathering = _main.get("_gathering")
	state.materials = {"galho": 1, "fibra": 5}
	gathering.craft("linha")
	gathering.craft("vara_artesanal")
	state.coins = 700
	var screens: Screens = _main.get("_screens")
	screens.open_shop(Screens.ShopTab.LINES)
	await _frames(10)
	await _shot("01-shop-lines.png")
	screens.close()
	var fisherman: Fisherman = _main.get("_fisherman")
	fisherman.teleport(Vector2(45.5, 29.5))
	await _frames(20)
	var machine: FishingMachine = _main.get("_machine")
	var fish := GameState.Catch.new()
	fish.id = "tucunare"
	fish.weight = 5.2
	machine.species = data.species_by_id("tucunare")
	machine.hooked = fish
	machine.overweight = fish.weight > machine.line_max_kg()
	machine.target = Vector3(machine.origin.x, 0.0, machine.origin.z + 40.0)
	machine.call("_start_fight")
	machine.progress = 0.6
	await _frames(12)
	await _shot("02-fight-too-heavy.png")
	quit(0)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
