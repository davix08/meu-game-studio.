extends SceneTree
## Visual evidence for design/gdd/coop-lan.md: two full games on one machine. Run the
## guest first (headless is fine), then the host windowed:
##   godot --headless --path . -s res://tests/visual/capture_coop.gd -- guest &
##   godot --path . -s res://tests/visual/capture_coop.gd -- host
## The host saves the room screen and the world with the guest's fisherman and catch toast.
## Starts new games, so it overwrites this machine's user:// save.

const OUT: String = "res://production/qa/evidence/coop/"
const PORT: int = 7802

var _main: Node
var _role: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_role = args[0] if args.size() > 0 else "host"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	_main.set("_fresh_start", true)
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(20)
	var net: NetSession = _main.get("_net")
	var state: GameState = _main.get("_state")
	var gathering: Gathering = _main.get("_gathering")
	var fisherman: Fisherman = _main.get("_fisherman")
	state.materials = {"galho": 1, "fibra": 5}
	gathering.craft("linha")
	gathering.craft("vara_artesanal")
	if _role == "guest":
		var connected: Array = [false]
		net.session_started.connect(func() -> void: connected[0] = true)
		var ended: Array = [false]
		for attempt: int in 30: # The host may not have opened the room yet: retry.
			net.join("127.0.0.1", PORT)
			await _frames(60)
			if connected[0]:
				break
		net.session_ended.connect(func(_r: String) -> void: ended[0] = true)
		fisherman.teleport(Vector2(44.5, 26.5))
		for i: int in 1500:
			await process_frame
			if ended[0]:
				break
			if i == 200:
				var fish := GameState.Catch.new()
				fish.id = "carpa"
				fish.weight = 4.51
				fish.length = 63.0
				var entry := GameState.BookEntry.new()
				entry.count = 1
				entry.best = fish.weight
				entry.longest = fish.length
				state.book["carpa"] = entry
				state.fish_caught.emit(fish, true, false)
		quit(0)
		return
	net.host(PORT)
	fisherman.teleport(Vector2(46.0, 28.0))
	var screens: Screens = _main.get("_screens")
	for i: int in 400:
		await process_frame
		if net.player_count() >= 2:
			break
	screens.open_coop()
	await _frames(10)
	await _shot("01-room-hosting.png")
	screens.close()
	var toast: Label = screens.get("_toast")
	for i: int in 900: # Wait for the guest's catch announcement.
		await process_frame
		if toast.visible and toast.text.contains("pegou"):
			break
	await _frames(10)
	await _shot("02-guest-in-world.png")
	quit(0 if net.player_count() >= 2 else 1)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", OUT + file)
