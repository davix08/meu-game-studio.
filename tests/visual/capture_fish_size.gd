extends SceneTree
## Visual evidence for design/gdd/fish-catch.md AC5. Starts a fresh game, lands three
## fish through the real FishingMachine bookkeeping path (GameState.fish_caught), and
## saves the capture card, the guide and the bag as PNGs.
## Run windowed (not headless): godot --path . -s res://tests/visual/capture_fish_size.gd
## Writes to production/qa/evidence/fish-size/. It starts a new game, so it overwrites the
## user:// save of the machine it runs on: run it on a CI or dev box, not a player's install.

const OUT: String = "res://production/qa/evidence/fish-size/"

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
	var roller := FishRoller.new(data, state, RandomSource.new(11))
	for id: String in ["tilapia", "carpa"]:
		_land(state, roller, data.species_by_id(id), 0.0)
	_land(state, roller, data.species_by_id("tilapia"), 1.4)
	await _frames(40)
	await _shot("01-capture-card.png")
	var hud: Node = _main.get("_fishing_hud")
	hud.set("card_open", false)
	var screens: Screens = _main.get("_screens")
	screens.open_book()
	await _frames(10)
	await _shot("02-fish-guide.png")
	screens.open_bag()
	await _frames(10)
	await _shot("03-bag.png")
	quit(0)


## Lands a [param sp] fish; [param kg] 0 rolls the weight, else forces it (the tilápia record).
func _land(state: GameState, roller: FishRoller, sp: GameData.Species, kg: float) -> void:
	var fish: GameState.Catch = roller.roll_catch(sp)
	if kg > 0.0:
		fish.weight = kg
		fish.length = roller.fish_length(sp, kg)
		fish.value = roller.fish_value(sp, kg)
	state.bag.append(fish)
	var prev: GameState.BookEntry = state.book.get(fish.id, null)
	var entry := GameState.BookEntry.new()
	entry.count = 1 if prev == null else prev.count + 1
	entry.best = fish.weight if prev == null else maxf(prev.best, fish.weight)
	entry.longest = fish.length if prev == null else maxf(prev.longest, fish.length)
	state.book[fish.id] = entry
	state.fish_caught.emit(fish, prev == null, prev != null and fish.weight > prev.best)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
