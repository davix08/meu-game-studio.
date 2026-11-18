extends SceneTree
## Visual evidence for design/gdd/gathering-crafting.md: a fresh game (no rod, glowing
## spots near the spawn), the bench with the recipes, and the crafted rod in hand.
## Run windowed: godot --path . -s res://tests/visual/capture_first_rod.gd
## Starts a new game, so it overwrites this machine's user:// save.

const OUT: String = "res://production/qa/evidence/first-rod/"

var _main: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	_main.set("_fresh_start", true)
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(40)
	await _shot("01-start-no-rod.png")
	var data: GameData = _main.get("_data")
	var gathering: Gathering = _main.get("_gathering")
	var fisherman: Fisherman = _main.get("_fisherman")
	# Walk up to the first fiber spot so the context button shows "Coletar".
	var fiber: GameData.GatherNode = null
	for n: GameData.GatherNode in data.gather_nodes:
		if n.kind == "fibra":
			fiber = n
			break
	fisherman.teleport(fiber.pos + Vector2(0.6, 0.0))
	await _frames(20)
	await _shot("02-gather-button.png")
	for n: GameData.GatherNode in data.gather_nodes:
		if n.kind != "minhoca":
			_main.call("_gather", n)
	await _frames(5)
	var screens: Screens = _main.get("_screens")
	screens.open_bench()
	await _frames(10)
	await _shot("03-bench-ready.png")
	gathering.craft("linha")
	gathering.craft("vara_artesanal")
	screens.open_bench()
	await _frames(10)
	await _shot("04-bench-rod-made.png")
	screens.close()
	fisherman.teleport(Vector2(45.5, 28.5))
	await _frames(30)
	await _shot("05-rod-in-hand.png")
	quit(0)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
