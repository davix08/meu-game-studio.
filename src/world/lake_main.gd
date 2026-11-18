class_name LakeMain
extends Node3D
## Root script of scenes/main.tscn: builds everything in code (world, town, fisherman, camera,
## interface, fishing, day/night, neighbors) and feeds the fisherman from the joystick or the
## keyboard (WASD / arrows, Shift to run; read with Input.is_physical_key_pressed, so the InputMap
## is untouched). The input is screen-relative: it is rotated by the isometric camera yaw.
##
## Fishing (Story 003): a tap on the world casts to the water point under the finger (camera ray
## against the water plane, no physics); Space casts forward and, held, is PUXAR; Z toggles rest.
## [FishingMachine.step], [Energy.step] and [GameClock.step] run in _physics_process (fixed step).
##
## Story 006: top bar, action buttons and screens. Story 008: the clock runs, day and night,
## sleeping, autosave (timer and main events) and the start screen. Stories 009-018: the bigger
## map and the town: the context button near a building, plot, animal home or neighbor opens its
## screen (E on the keyboard); tapping a neighbor opens the request dialog.

## Distance step (in blocks) when looking for water ahead for the keyboard "cast forward".
const _FORWARD_STEP: float = 1.0

## When true the next scene load starts a new game at once (set by "Novo jogo").
static var _fresh_start: bool = false

## One place the player can use with the context button.
class Spot:
	extends RefCounted
	## Where it is (meters, x z).
	var pos: Vector2 = Vector2.ZERO
	## How close the player must be.
	var radius: float = 1.5
	## Returns the button text, or "" when the spot is not usable now.
	var label: Callable
	## Runs when the button is pressed.
	var action: Callable

var _look: WorldLook
var _data: GameData
var _town_data: TownData
var _state: GameState
var _machine: FishingMachine
var _energy: Energy
var _clock: GameClock
var _economy: Economy
var _town: Town
var _progression: Progression
var _life: WaterLife
var _world: LakeWorld
var _fisherman: Fisherman
var _camera: FollowCamera
var _stick: VirtualStick
var _fishing_hud: FishingHud
var _top: TopBar
var _actions: ActionBar
var _screens: Screens
var _sfx: Sfx
var _town_view: TownView
var _farm: FarmView
var _ranch: RanchView
var _npcs: NpcView
var _cycle: DayNight
var _gathering: Gathering
var _net: NetSession
var _beacon: LanBeacon
var _others: RemotePlayers
var _dive: Dive
var _dive_view: DiveView
var _dive_hud: DiveHud
var _diving: bool = false
var _snapshot := PlayerSnapshot.new()
var _gather_view: GatherView
var _spots: Array[Spot] = []
var _spot: Spot
var _water_plane: Plane
var _water_y: float = 0.0
var _run_threshold: float = 0.95
var _input_yaw: float = 0.0 ## Camera yaw in radians (world_look.json camera.yaw_degrees).
var _key_was_down: bool = false
var _hold_stale: bool = false
var _cancel_pending: bool = false
var _started: bool = false
var _save_timer: float = 0.0
var _save_soon: bool = false
var _e_was_down: bool = false


func _ready() -> void:
	_look = WorldLook.load_file()
	_data = GameData.load_from_dir()
	_town_data = TownData.load_file()
	if _look == null or _data == null or _town_data == null:
		return
	_data.town = _town_data
	_apply_performance()
	_world = LakeWorld.new()
	add_child(_world)
	_world.build(_look)

	_state = GameState.create_new(_data)
	_state.init_town(_town_data)
	var rng := RandomSource.new(_data.seed_value)
	_town = Town.new(_data, _town_data, _state, RandomSource.new(_data.seed_value + 7))
	_town_view = TownView.new()
	add_child(_town_view)
	_town_view.setup(_look, _town_data, _state, _world.grid)
	_farm = FarmView.new()
	add_child(_farm)
	_farm.setup(_look, _town_data, _state)
	_town.ensure_plots(_farm.plot_count)
	_ranch = RanchView.new()
	add_child(_ranch)
	_ranch.setup(_look, _town_data, _state, _world.terrain)

	_fisherman = Fisherman.new()
	add_child(_fisherman)
	_fisherman.setup(_look, _world.grid, _world.terrain, _data.tune("walk_speed") / WorldGrid.PIXELS_PER_BLOCK, _data.tune("run_speed") / WorldGrid.PIXELS_PER_BLOCK)
	_npcs = NpcView.new()
	add_child(_npcs)
	_npcs.setup(_look, _town_data, _state, _world.grid, _world.terrain, _town)

	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.setup(_look, _fisherman)

	_water_y = _look.num("terrain", "water_level")
	_water_plane = Plane(Vector3.UP, _water_y)
	_life = WaterLife.new()
	add_child(_life)
	_life.setup(_look, _data, _world.grid, rng, _water_y)
	_world.query.set_water_life(_life)
	var roller := FishRoller.new(_data, _state, rng)
	_dive = Dive.new(_data, _state, roller, rng)
	_dive.ended.connect(_on_dive_ended)
	_dive_view = DiveView.new()
	add_child(_dive_view)
	_dive_view.setup(_look, _data, _look.num("terrain", "water_level"))
	_progression = Progression.new(_data, _state)
	_machine = FishingMachine.new(_data, _state, rng, _world.query, roller, _progression)
	_energy = Energy.new(_data, _state, _machine)
	_clock = GameClock.new(_data, _state)
	_economy = Economy.new(_data, _state)
	_gathering = Gathering.new(_data, _state)
	_net = NetSession.new()
	_net.name = "Net" # Same node path on every peer, for the RPCs.
	add_child(_net)
	_beacon = LanBeacon.new()
	add_child(_beacon)
	_others = RemotePlayers.new()
	add_child(_others)
	_others.setup(_look, _world.grid, _world.terrain, _data.tune("walk_speed") / WorldGrid.PIXELS_PER_BLOCK, _data.tune("run_speed") / WorldGrid.PIXELS_PER_BLOCK)
	_gather_view = GatherView.new()
	add_child(_gather_view)
	_gather_view.setup(_data, _gathering, _world.terrain)
	var view := FishingView.new()
	add_child(view)
	view.setup(_look, _data, _machine, _fisherman, _life, _water_y)
	_cycle = DayNight.new()
	add_child(_cycle)
	_cycle.setup(_look, _world, _fisherman)
	_cycle.lights_changed.connect(_on_lights)

	_build_interface()
	_build_spots()
	_connect_events()
	_run_threshold = _look.num("joystick", "run_threshold")
	_input_yaw = deg_to_rad(_look.num("camera", "yaw_degrees"))
	_save_timer = _data.tune("autosave_seconds")
	_cycle.update(_state.minutes)
	_sync_position()
	if _fresh_start:
		_fresh_start = false
		_begin(true)
	else:
		_screens.show_start(FileAccess.file_exists(SaveGame.DEFAULT_PATH))


func _build_interface() -> void:
	var hud := Hud.new()
	add_child(hud)
	hud.setup(_look)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme(_look)
	hud.add_child(root)
	_stick = VirtualStick.new()
	root.add_child(_stick)
	_stick.setup(_look)
	_sfx = Sfx.new()
	add_child(_sfx)
	_sfx.setup(_look)
	var ctx := GameContext.new()
	ctx.data = _data
	ctx.town_data = _town_data
	ctx.state = _state
	ctx.economy = _economy
	ctx.town = _town
	ctx.progression = _progression
	ctx.energy = _energy
	ctx.clock = _clock
	ctx.gathering = _gathering
	ctx.net = _net
	ctx.beacon = _beacon
	_top = TopBar.new()
	root.add_child(_top)
	_top.setup(_look, _data, _state, _clock, _progression)
	_fishing_hud = FishingHud.new()
	root.add_child(_fishing_hud)
	_fishing_hud.setup(_look, _data, _state)
	_fishing_hud.bind(_machine)
	_dive_hud = DiveHud.new()
	root.add_child(_dive_hud)
	_dive_hud.setup(_look)
	_dive_hud.shoot_pressed.connect(_dive_shoot)
	_dive_hud.surface_pressed.connect(func() -> void: _dive.surface())
	_actions = ActionBar.new()
	root.add_child(_actions)
	_actions.setup(_look)
	_screens = Screens.new()
	root.add_child(_screens)
	_screens.setup(_look, ctx, _sfx)
	_top.settings_pressed.connect(_open_settings)
	_actions.bag_pressed.connect(_screens.open_bag)
	_actions.book_pressed.connect(_screens.open_book)
	_actions.rest_pressed.connect(_toggle_rest)
	_actions.shop_pressed.connect(_open_shop_if_near)
	_actions.context_pressed.connect(_use_spot)
	_screens.start_chosen.connect(_begin)
	_screens.new_game_requested.connect(_new_game)
	_screens.outfit_changed.connect(_dress)


func _connect_events() -> void:
	_state.fish_caught.connect(_on_fish_caught)
	_state.town_changed.connect(_mark_save)
	_gathering.materials_changed.connect(_on_materials_changed)
	_net.player_joined.connect(_on_player_joined)
	_net.player_left.connect(_on_player_left)
	_net.remote_state.connect(_others.apply)
	_net.remote_catch.connect(_on_remote_catch)
	_net.session_started.connect(_on_session_started)
	_net.session_ended.connect(_on_session_ended)
	_state.day_started.connect(_on_day_started)
	_economy.fish_sold.connect(_on_fish_sold)
	_machine.fish_bit.connect(_on_fish_bit)


func _open_settings() -> void:
	_sfx.play(&"click")
	_screens.open_settings()


func _on_fish_caught(fish: GameState.Catch, _is_new: bool, _is_record: bool) -> void:
	_sfx.play(&"catch")
	_save_soon = true
	_net.send_catch(fish.id, fish.weight, fish.length)


# --- Diving (design/gdd/diving.md) ---

func _start_dive() -> void:
	match _dive.start():
		Dive.StartResult.NO_ENERGY:
			_sfx.play(&"error")
			_screens.toast(Texts.get_text("dive_no_energy"))
		Dive.StartResult.BAG_FULL:
			_sfx.play(&"error")
			_screens.toast(Texts.get_text("dive_bag_full"))
		Dive.StartResult.OK:
			_sfx.play(&"cast")
			_diving = true
			_actions.visible = false
			_fishing_hud.visible = false
			_dive_hud.visible = true
			_dive_view.begin(_dive)


func _dive_process(delta: float) -> void:
	var dir: Vector2 = _stick.value
	var keys: Vector2 = _keyboard_direction()
	if keys != Vector2.ZERO:
		dir = keys
	if _screens.is_open():
		dir = Vector2.ZERO
	_dive.step(delta, dir.rotated(-_input_yaw))
	if not _diving:
		return # Out of air during this step: already back on the surface.
	_dive_view.sync(delta)
	_dive_hud.show_dive(_dive, delta)
	var space: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if space and not _key_was_down:
		_dive_shoot()
	_key_was_down = space
	_send_presence(delta)


func _dive_shoot() -> void:
	if not _dive.can_shoot():
		return
	var hit: Dive.DiveFish = _dive.shoot()
	_sfx.play(&"catch" if hit != null else &"click")
	_screens.toast(Texts.fmt("dive_hit", [_data.species_by_id(hit.fish.id).name]) if hit != null else Texts.get_text("dive_miss"))


func _on_dive_ended(reason: Dive.EndReason, kept: Array[GameState.Catch]) -> void:
	var speared: int = _dive.haul.size()
	_diving = false
	_dive_view.finish()
	_camera.make_current()
	_dive_hud.visible = false
	_actions.visible = true
	_fishing_hud.visible = true
	for fish: GameState.Catch in kept:
		_state.bag.append(fish)
		var flags: Array[bool] = _state.record_catch(fish)
		_state.fish_caught.emit(fish, flags[0], flags[1])
	_progression.check_level_up()
	var lost_air: int = speared - Dive.kept_count(reason, speared, float(_data.dive["loss_fraction"]))
	var overflow: int = speared - lost_air - kept.size()
	var text: String = Texts.fmt("dive_surfaced", [kept.size()])
	if reason == Dive.EndReason.OUT_OF_AIR:
		text = Texts.fmt("dive_out_of_air", [lost_air, speared]) if lost_air > 0 else Texts.fmt("dive_out_of_air_safe", [kept.size()])
	if overflow > 0:
		text += " " + Texts.fmt("dive_bag_overflow", [overflow])
	_screens.toast(text)
	_mark_save()


# --- Coop (design/gdd/coop-lan.md) ---

func _on_player_joined(peer_id: int, slot: int) -> void:
	_others.add_player(peer_id, slot)
	_screens.toast(Texts.fmt("coop_joined", [slot + 1]))
	_advertise()


func _on_player_left(peer_id: int) -> void:
	_others.remove_player(peer_id)
	_advertise()


func _on_remote_catch(peer_id: int, species_id: String, weight: float, length: float) -> void:
	if not _data.has_species(species_id):
		return
	var slot: int = _net.slots.get(peer_id, 0)
	var kg: String = String.num(weight, int(_data.fixed("weight_decimals"))).replace(".", ",")
	_screens.toast(Texts.fmt("coop_caught", [slot + 1, _data.species_by_id(species_id).name, kg, Texts.length_text(length, _data.fixed("meters_from_cm"))]))


func _on_session_started() -> void:
	_screens.toast(Texts.get_text("coop_hosting") if _net.is_host() else Texts.get_text("coop_connected"))
	_advertise()
	_screens.refresh_if_open()


func _on_session_ended(reason: String) -> void:
	_others.clear()
	_beacon.stop()
	if reason != "left":
		_screens.toast(Texts.get_text("coop_end_" + reason))
	_screens.refresh_if_open()


func _advertise() -> void:
	if _net.is_host():
		_beacon.advertise(Texts.fmt("coop_room_name", [LanBeacon.local_ip()]), _net.player_count())


func _send_presence(delta: float) -> void:
	if not _net.is_active():
		return
	_snapshot.pos = _fisherman.ground_pos
	_snapshot.yaw = _fisherman.rotation.y
	_snapshot.pose = _fisherman.pose
	_snapshot.cast_progress = _fisherman.cast_progress
	_snapshot.has_rod = _state.has_rod()
	_snapshot.rod_color = _data.rod_by_id(_state.rod).color if _state.has_rod() else ""
	_net.send_state(_snapshot, delta)


func _on_fish_sold(_count: int, _coins: int) -> void:
	_save_soon = true


func _on_fish_bit(_species: GameData.Species) -> void:
	_sfx.play(&"bite")


func _on_materials_changed() -> void:
	_dress()
	_mark_save()


func _mark_save() -> void:
	_save_soon = true


## Starts play: a new game ([param fresh]) or the saved one.
func _begin(fresh: bool) -> void:
	if not fresh:
		SaveGame.apply(_state, _data, SaveGame.read())
		var pos := Vector2(_state.position.x, _state.position.z) / WorldGrid.PIXELS_PER_BLOCK
		if _state.position != Vector3.ZERO and _world.grid.box_free(pos.x, pos.y, 0.25, 0.16):
			_fisherman.teleport(pos)
		_town.ensure_plots(_farm.plot_count)
		_state.town_changed.emit()
	_town.ensure_requests()
	_dress()
	_sfx.set_enabled(_state.sound_on)
	_sync_position()
	_started = true
	_save()


func _new_game() -> void:
	if FileAccess.file_exists(SaveGame.DEFAULT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.DEFAULT_PATH))
	_fresh_start = true
	get_tree().reload_current_scene()


func _dress() -> void:
	_fisherman.set_outfit(Screens.outfit_colors(_town_data, _state))
	_fisherman.set_rod_visible(_state.has_rod())
	if _state.has_rod():
		_fisherman.set_rod_color(Color.html(_data.rod_by_id(_state.rod).color))


func _process(delta: float) -> void:
	if _fisherman == null:
		return
	_cycle.update(_state.minutes)
	if _diving:
		_dive_process(delta)
		return
	var dir: Vector2 = _stick.value
	var run: bool = dir.length() >= _run_threshold
	var keys: Vector2 = _keyboard_direction()
	if keys != Vector2.ZERO:
		dir = keys
		run = Input.is_physical_key_pressed(KEY_SHIFT)
	var phase: FishingMachine.Phase = _machine.phase
	if not _started or _screens.is_open():
		dir = Vector2.ZERO
	if phase == FishingMachine.Phase.BITE or phase == FishingMachine.Phase.FIGHT or phase == FishingMachine.Phase.CAUGHT or _fishing_hud.card_open:
		dir = Vector2.ZERO
	elif dir != Vector2.ZERO and (phase == FishingMachine.Phase.CAST or phase == FishingMachine.Phase.WAIT):
		_cancel_pending = true
	# Screen-space input (up = -y, right = +x) to world ground direction (x, z): the camera is
	# yawed by +_input_yaw around Y, so rotate the input by -_input_yaw (Vector2.rotated).
	_fisherman.step(delta, dir.rotated(-_input_yaw), run)
	_actions.set_resting(_state.resting)
	_update_spot()
	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	if e_down and not _e_was_down and _started and not _screens.is_open():
		_use_spot()
	_e_was_down = e_down
	_send_presence(delta)


func _physics_process(delta: float) -> void:
	if _machine == null or not _started:
		return
	_sync_position()
	if _cancel_pending:
		_cancel_pending = false
		_machine.cancel()
	var hold: bool = _fishing_hud.pull.held
	var press: bool = _fishing_hud.pull.take_press()
	var key_down: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if key_down and not _key_was_down:
		press = true
	_key_was_down = key_down
	hold = hold or key_down
	if _fishing_hud.card_open or _screens.is_open():
		press = false
		hold = false
	var phase: FishingMachine.Phase = _machine.phase
	# A button held since the cast must be released once before it counts as PUXAR on the bite.
	if phase == FishingMachine.Phase.CAST or phase == FishingMachine.Phase.WAIT:
		_hold_stale = hold
		hold = false
	else:
		if not hold:
			_hold_stale = false
		if _hold_stale:
			hold = false
	if press:
		if phase == FishingMachine.Phase.IDLE:
			_cast_forward()
		elif phase == FishingMachine.Phase.CAST:
			_machine.cancel()
			press = false
	_life.step(delta)
	_machine.step(delta, hold, press)
	_energy.step(delta)
	_clock.step(delta)
	if _machine.phase == FishingMachine.Phase.FIGHT:
		_fishing_hud.on_fight_step(delta)
	_save_timer -= delta
	if _save_timer <= 0.0 or _save_soon:
		_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _started:
			_save()


## Writes the save now (autosave timer, main events, closing or leaving the game).
func _save() -> void:
	_save_timer = _data.tune("autosave_seconds")
	_save_soon = false
	_sync_position()
	_npcs.store()
	SaveGame.write(_state)


func _unhandled_input(event: InputEvent) -> void:
	if _machine == null or not _started or _screens.is_open():
		return
	# Touches cast directly (one cast per touch); only a real mouse (DEVICE_ID_MOUSE, 4.7) casts
	# on click, so the mouse events Godot emulates from touches never cast a second time.
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_tap(touch.position)
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.device == InputEvent.DEVICE_ID_MOUSE and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_tap(click.position)
	elif event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and key.physical_keycode == KEY_Z:
			_toggle_rest()


## A tap on the world: a neighbor opens the dialog (Story 013); otherwise it casts.
func _tap(screen_pos: Vector2) -> void:
	var who: String = _npcs.npc_at_screen(_camera, screen_pos, _look.num("npc", "tap_radius") * 60.0)
	if who != "" and _machine.is_idle():
		_sfx.play(&"click")
		_screens.open_neighbor(who)
		return
	_cast_at_screen(screen_pos)


## Casts to the water point under [param screen_pos]: the camera ray meets the water plane.
func _cast_at_screen(screen_pos: Vector2) -> void:
	var hit: Variant = _water_plane.intersects_ray(_camera.project_ray_origin(screen_pos), _camera.project_ray_normal(screen_pos))
	if hit != null:
		var point: Vector3 = hit
		_try_cast(point)


## Casts toward where the fisherman looks, to the farthest water within the rod's range.
func _cast_forward() -> void:
	var blocker: FishingMachine.CastResult = _machine.cast_blocker()
	if blocker != FishingMachine.CastResult.CAST:
		_show_cast_result(blocker)
		return
	var yaw: float = _fisherman.rotation.y
	var ahead := Vector3(sin(yaw), 0.0, cos(yaw))
	var from := Vector3(_fisherman.ground_pos.x, _water_y, _fisherman.ground_pos.y)
	var reach: float = _data.rod_for(_state).cast_range / WorldGrid.PIXELS_PER_BLOCK
	var distance: float = reach - 0.05 ## Just inside the range, so rounding never gives OUT_OF_RANGE.
	while distance >= _FORWARD_STEP:
		var point: Vector3 = from + ahead * distance
		if _world.query.is_water(LakeWorldQuery.to_query_pos(Vector3(point.x, 0.0, point.z))):
			_try_cast(point)
			return
		distance -= _FORWARD_STEP
	_fishing_hud.show_toast("cast_no_water_ahead")


## Asks the machine to cast to [param world_point] (meters, on the water plane).
func _try_cast(world_point: Vector3) -> void:
	_sync_position()
	_dress()
	var result: FishingMachine.CastResult = _machine.cast_at(LakeWorldQuery.to_query_pos(Vector3(world_point.x, 0.0, world_point.z)))
	if result == FishingMachine.CastResult.CAST:
		_fisherman.face_toward(world_point)
		_sfx.play(&"cast")
	else:
		_show_cast_result(result)


func _show_cast_result(result: FishingMachine.CastResult) -> void:
	if result != FishingMachine.CastResult.BUSY:
		_fishing_hud.show_toast("cast_" + FishingMachine.CastResult.keys()[result].to_lower())


func _toggle_rest() -> void:
	var result: Energy.Result = _energy.toggle_rest()
	if result == Energy.Result.BUSY_FISHING:
		_fishing_hud.show_toast("rest_busy")
	elif result == Energy.Result.ENERGY_FULL:
		_fishing_hud.show_toast("rest_full")


func _on_day_started(day: int, auto: bool) -> void:
	_town.on_new_day()
	_fisherman.teleport(WorldGrid.SPAWN)
	_screens.show_sleep(day, auto)
	_save_soon = true


func _on_lights(on: bool) -> void:
	_world.estate.set_lights(on)
	_town_view.set_lights(on)
	_ranch.set_night(on)


# --- Context button (Stories 006, 010-018) ---

func _build_spots() -> void:
	var reach: float = _look.num("town", "door_reach")
	_add_spot(_shop_point(), reach, _label_fixed.bind("act_shop"), _screens.open_shop.bind(Screens.ShopTab.SELL))
	var screens_by_lot: Dictionary = {
		"prefeitura": ["act_cityhall", _screens.open_cityhall],
		"armazem": ["act_warehouse", _screens.open_warehouse],
		"oficina": ["act_workshop", _screens.open_workshop],
		"restaurante": ["act_restaurant", _screens.open_restaurant],
		"roupas": ["act_clothes", _screens.open_clothes],
	}
	for id: String in TownPlan.lot_ids(_look):
		var name: String = str(_town_data.lot(id).get("name", id))
		if screens_by_lot.has(id):
			var entry: Array = screens_by_lot[id]
			_add_spot(TownPlan.lot_door(_look, id), reach, _label_lot.bind(id, str(entry[0]), name), _open_lot.bind(id, entry[1]))
		elif id.begins_with("casa_"):
			for n: Variant in _town_data.neighbors():
				var nb: Dictionary = n
				if str(nb["lot"]) == id:
					_add_spot(TownPlan.lot_door(_look, id), reach, _label_talk.bind(str(nb["name"])), _screens.open_neighbor.bind(str(nb["id"])))
		elif id == "campos":
			_add_spot(TownPlan.lot_door(_look, id) + Vector2(1.0, 0.0), reach, _label_site.bind(id, name), _screens.toast.bind(Texts.get_text("not_built")))
	_add_spot(_bench_point(), reach, _label_fixed.bind("act_bench"), _open_bench)
	var dive_spot := Vector2(float(_data.dive["spot"]["x"]), float(_data.dive["spot"]["y"]))
	_add_spot(dive_spot, float(_data.dive["spot"]["reach"]), _label_fixed.bind("act_dive"), _start_dive)
	for n: GameData.GatherNode in _data.gather_nodes:
		_add_spot(n.pos, _look.num("town", "door_reach"), _label_gather.bind(n), _gather.bind(n))
	for i in _farm.plot_count:
		_add_spot(_farm.anchor(i), 1.1, _plot_label.bind(i), _use_plot.bind(i))
	for home: String in ["galinheiro", "pasto"]:
		var key: String = "act_coop" if home == "galinheiro" else "act_pasture"
		_add_spot(_ranch.anchor(home), reach, _label_fixed.bind(key), _screens.open_ranch.bind(home))


func _add_spot(pos: Vector2, radius: float, label: Callable, action: Callable) -> void:
	var spot := Spot.new()
	spot.pos = pos
	spot.radius = radius
	spot.label = label
	spot.action = action
	_spots.append(spot)


func _label_gather(n: GameData.GatherNode) -> String:
	return Texts.fmt("act_gather", [_data.material_by_id(n.kind).name]) if _gathering.is_available(n.id) else ""


func _gather(n: GameData.GatherNode) -> void:
	if _gathering.gather(n.id) == Gathering.Result.OK:
		_sfx.play(&"coin")
		_screens.toast(Texts.fmt("gathered", [_data.gather_amount[n.kind], _data.material_by_id(n.kind).name]))
		_mark_save()
	else:
		_sfx.play(&"error")
		_screens.toast(Texts.get_text("gather_gone"))


func _open_bench() -> void:
	_sfx.play(&"click")
	_screens.open_bench()


## The dock bench (world_look.json estate bench_*), where the player crafts.
func _bench_point() -> Vector2:
	var bench: Rect2i = EstateMeshes.cell_rect(_look, "bench")
	return Vector2(float(bench.position.x) + float(bench.size.x) * 0.5, float(bench.end.y) + 0.5)


func _label_fixed(key: String) -> String:
	return Texts.get_text(key)


func _label_lot(id: String, key: String, name: String) -> String:
	return Texts.get_text(key) if _state.is_built(id) else Texts.fmt("act_site", [name])


func _label_talk(name: String) -> String:
	return Texts.fmt("act_talk", [name])


func _label_site(id: String, name: String) -> String:
	return "" if _state.is_built(id) else Texts.fmt("act_site", [name])


func _shop_point() -> Vector2:
	var shop: Rect2i = EstateMeshes.cell_rect(_look, "shop")
	return Vector2(float(shop.end.x) + 0.5, float(shop.position.y) + 1.5)


func _open_lot(id: String, open: Callable) -> void:
	if _state.is_built(id):
		_sfx.play(&"click")
		open.call()
	else:
		_screens.toast(Texts.get_text("not_built"))


func _plot_label(i: int) -> String:
	if not _farm.usable(i) or i >= _state.plots.size():
		return ""
	match _town.stage(i):
		Town.Stage.EMPTY:
			return Texts.get_text("plant")
		Town.Stage.RIPE:
			return Texts.get_text("harvest")
	return Texts.get_text("plot_title") if bool(_state.plots[i]["watered"]) else Texts.get_text("water")


## Waters or harvests at once; empty or already watered plots open the plot screen.
func _use_plot(i: int) -> void:
	var stage: Town.Stage = _town.stage(i)
	if stage == Town.Stage.RIPE:
		var crop: Dictionary = _town_data.crop(str(_state.plots[i]["crop"]))
		var r: Town.Result = _town.harvest(i)
		if r == Town.Result.OK:
			_sfx.play(&"coin")
			_screens.toast(Texts.fmt("harvested", [int(crop["harvest"]), str(crop["name"])]))
		else:
			_screens.toast(Texts.get_text("no_energy") if r == Town.Result.NO_ENERGY else Texts.get_text("not_ready"))
	elif stage != Town.Stage.EMPTY and not bool(_state.plots[i]["watered"]):
		var w: Town.Result = _town.water(i)
		_sfx.play(&"click" if w == Town.Result.OK else &"error")
		_screens.toast(Texts.get_text("watered") if w == Town.Result.OK else Texts.get_text("no_energy"))
	else:
		_screens.open_plot(i)


## Finds the nearest usable spot in reach and shows the context button.
func _update_spot() -> void:
	_spot = null
	var text: String = ""
	if _started and not _screens.is_open() and _machine.is_idle():
		var me: Vector2 = _fisherman.ground_pos
		var best: float = INF
		for spot: Spot in _spots:
			var d: float = me.distance_to(spot.pos)
			if d <= spot.radius and d < best:
				var label: String = spot.label.call()
				if label != "":
					best = d
					_spot = spot
					text = label
	_actions.show_context(text)


func _use_spot() -> void:
	if _spot != null:
		_spot.action.call()


func _open_shop_if_near() -> void:
	if _fisherman.ground_pos.distance_to(_shop_point()) <= _look.num("town", "door_reach") * 2.0:
		_sfx.play(&"click")
		_screens.open_shop()
	else:
		_sfx.play(&"error")
		_screens.toast(Texts.get_text("shop_far"))


## The machine measures distances in 2D pixel units on the ground plane.
func _sync_position() -> void:
	_state.position = LakeWorldQuery.to_query_pos(Vector3(_fisherman.ground_pos.x, 0.0, _fisherman.ground_pos.y))


func _keyboard_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	return dir.normalized()


func _apply_performance() -> void:
	var viewport: Viewport = get_viewport()
	viewport.msaa_3d = _look.integer("performance", "msaa_3d") as Viewport.MSAA
	viewport.scaling_3d_scale = _look.num("performance", "render_scale")
