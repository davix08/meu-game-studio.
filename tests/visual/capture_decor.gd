extends SceneTree
## Visual evidence for design/gdd/decoration.md: empty slot markers, the Decorar screen,
## and the yard with pieces placed (trophy showing the heaviest fish).
## Run windowed: godot --path . -s res://tests/visual/capture_decor.gd (overwrites this machine's save).

const OUT: String = "res://production/qa/evidence/decoration/"

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
	var decor: Decor = _main.get("_decor")
	var fisherman: Fisherman = _main.get("_fisherman")
	state.coins = 3000
	state.level = 3
	fisherman.teleport(data.decor_slots["casa_2"] + Vector2(0.5, 0.4))
	await _frames(20)
	await _shot("01-empty-slots.png")
	var screens: Screens = _main.get("_screens")
	screens.open_decor("casa_2")
	await _frames(10)
	await _shot("02-decor-screen.png")
	screens.close()
	var f := GameState.Catch.new()
	f.id = "carpa"
	f.weight = 6.2
	f.length = 72.0
	state.record_catch(f)
	for pair: Array in [["casa_1", "vaso"], ["casa_2", "trofeu"], ["casa_3", "lanterna"], ["quintal_1", "banco"], ["quintal_2", "arbusto"], ["quintal_3", "bandeira"]]:
		decor.place(pair[0], pair[1])
	await _frames(20)
	await _shot("03-decorated.png")
	quit(0)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
