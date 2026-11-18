extends SceneTree
## Visual evidence for design/gdd/diving.md: the buoy and Mergulhar button at the pier
## end, the underwater arena with fish, a harpoon hit, low air, and the surface result.
## Run windowed: godot --path . -s res://tests/visual/capture_dive.gd (overwrites this machine's save).

const OUT: String = "res://production/qa/evidence/diving/"

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
	var fisherman: Fisherman = _main.get("_fisherman")
	fisherman.teleport(Vector2(float(data.dive["spot"]["x"]), float(data.dive["spot"]["y"])))
	await _frames(30)
	await _shot("01-dive-spot.png")
	_main.call("_start_dive")
	await _frames(40)
	await _shot("02-underwater.png")
	var dive: Dive = _main.get("_dive")
	var target: Dive.DiveFish = dive.fish[0]
	target.pos = dive.diver + dive.facing * 2.5
	target.vel = Vector2.ZERO
	_main.call("_dive_shoot")
	await _frames(6)
	await _shot("03-harpoon-hit.png")
	dive.oxygen = dive.oxygen_max * 0.15
	await _frames(20)
	await _shot("04-low-air.png")
	dive.oxygen = 0.05
	await _frames(20)
	await _shot("05-back-on-surface.png")
	quit(0)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
