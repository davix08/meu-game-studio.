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
var _farm: Farm
var _truck: DeliveryTruck
var _production: Production
var _field_view: CropFieldView
var _prod_timer: float = 0.0
var _opened: Dictionary = {}
var _house: HouseInterior
var _barn: BarnInterior
var _barn_spots: Array[Spot] = []
## Sleep steps: 0 awake, 1 lying down, 2 asleep (the night passes), then he gets up.
var _bed_phase: int = 0
var _bed_timer: float = 0.0
var _placing: String = ""
var _ghost: MeshInstance3D
var _ghost_door: MeshInstance3D
var _ghost_rect: Rect2i
var _ghost_ok: bool = false
var _place_bar: HBoxContainer
var _indoor_spots: Array[Spot] = []
var _ranch: RanchView
var _npcs: NpcView
var _cycle: DayNight
var _spots: Array[Spot] = []
var _spot: Spot
var _box_spot := Spot.new()
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
	TownPlan.placed = {}
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
	_farm = Farm.new(_data, _town_data, _state, _town)
	_production = Production.new(_data, _town_data, _state, _farm, Production.load_data())
	_farm.production = _production
	_field_view = CropFieldView.new()
	add_child(_field_view)
	_field_view.setup(_look, _state, _production)
	_ranch = RanchView.new()
	add_child(_ranch)
	_ranch.setup(_look, _town_data, _state, _world.terrain)

	_fisherman = Fisherman.new()
	add_child(_fisherman)
	_fisherman.setup(_look, _world.grid, _world.terrain, _data.tune("walk_speed") / WorldGrid.PIXELS_PER_BLOCK, _data.tune("run_speed") / WorldGrid.PIXELS_PER_BLOCK)
	# The village neighbors stay in the code for the city; the farm map has none (2026-11-19).
	if not _town_data.neighbors().is_empty():
		_npcs = NpcView.new()
		add_child(_npcs)
		_npcs.setup(_look, _town_data, _state, _world.grid, _world.terrain, _town)
	_truck = DeliveryTruck.new()
	add_child(_truck)
	_truck.setup(_look, _town_data, _state, _farm, _world.grid, _world.terrain)

	_fisherman.setup_water(_look.num("terrain", "water_level"), _look.num("player", "swim_depth"), _look.num("player", "swim_speed"))
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
	_progression = Progression.new(_data, _state)
	_machine = FishingMachine.new(_data, _state, rng, _world.query, roller, _progression)
	_energy = Energy.new(_data, _state, _machine)
	_clock = GameClock.new(_data, _state)
	_economy = Economy.new(_data, _state)
	var view := FishingView.new()
	add_child(view)
	view.setup(_look, _data, _machine, _fisherman, _life, _water_y)
	_cycle = DayNight.new()
	add_child(_cycle)
	_cycle.setup(_look, _world, _fisherman)
	_cycle.lights_changed.connect(_on_lights)
	_cycle.setup_indoor(_look)
	_house = HouseInterior.new()
	add_child(_house)
	_house.build(_look)
	_barn = BarnInterior.new()
	add_child(_barn)
	_barn.build(_look, _production)

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
		_set_menu_mode(true)
		_screens.show_start(FileAccess.file_exists(SaveGame.DEFAULT_PATH))


## The start menu shows the live farm close up with no HUD; the game restores both.
func _set_menu_mode(on: bool) -> void:
	for node: Control in [_top, _actions, _stick, _fishing_hud]:
		node.visible = not on
	_camera.size = _look.num("camera", "menu_size") if on else _look.num("camera", "size")
	_camera.focus_shift = _camera.basis.x * _look.num("camera", "menu_shift_x") if on else Vector3.ZERO


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
	ctx.farm = _farm
	ctx.production = _production
	_top = TopBar.new()
	root.add_child(_top)
	_top.setup(_look, _data, _state, _clock, _progression, _farm)
	_fishing_hud = FishingHud.new()
	root.add_child(_fishing_hud)
	_fishing_hud.setup(_look, _data, _state)
	_fishing_hud.bind(_machine)
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
	_actions.rod_pressed.connect(_toggle_rod)
	_screens.start_chosen.connect(_begin)
	_screens.new_game_requested.connect(_new_game)
	_screens.outfit_changed.connect(_dress)
	_screens.set_placeable(TownPlan.placeable_ids(_look))
	_screens.place_requested.connect(_start_placing)
	_place_bar = HBoxContainer.new()
	_place_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_place_bar.offset_top = -110.0
	_place_bar.offset_bottom = -30.0
	_place_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_place_bar.add_theme_constant_override(&"separation", 16)
	var hint: Label = UiKit.label(Texts.get_text("place_hint"), 20, Color.WHITE)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.add_theme_color_override(&"font_outline_color", Color.BLACK)
	hint.add_theme_constant_override(&"outline_size", 6)
	_place_bar.add_child(hint)
	var ok_button: Button = UiKit.button(_look, Texts.get_text("place_ok"), _confirm_placing)
	ok_button.custom_minimum_size = Vector2(220.0, 64.0)
	_place_bar.add_child(ok_button)
	var cancel_button: Button = UiKit.button(_look, Texts.get_text("place_cancel"), _cancel_placing)
	cancel_button.custom_minimum_size = Vector2(160.0, 64.0)
	_place_bar.add_child(cancel_button)
	_place_bar.visible = false
	root.add_child(_place_bar)


func _connect_events() -> void:
	_state.fish_caught.connect(_on_fish_caught)
	_state.town_changed.connect(_mark_save)
	_state.day_started.connect(_on_day_started)
	_economy.fish_sold.connect(_on_fish_sold)
	_machine.fish_bit.connect(_on_fish_bit)
	_farm.farm_level_up.connect(_on_farm_level_up)
	_production.material_dropped.connect(_on_material)
	_production.order_shipped.connect(_truck.pickup)


# --- Placing buildings (2026-11-22) ---

## Re-creates the buildings placed in this save; older saves get their built buildings at the
## spots they had on the fixed map.
func _restore_placements() -> void:
	for id: String in TownPlan.placeable_ids(_look):
		if _state.is_built(id) and not _state.placed.has(id):
			_state.placed[id] = TownPlan.default_spot(_look, id)
	for id: Variant in _state.placed:
		var e: Array = _state.placed[id]
		TownPlan.place(_world.grid, str(id), Rect2i(int(e[0]), int(e[1]), int(e[2]), int(e[3])), int(e[4]))
		_world.props.hide_decor_in(Rect2i(int(e[0]), int(e[1]), int(e[2]), int(e[3])))
		_town_view.add_lot(str(id))
	_after_placement()


func _after_placement() -> void:
	_ranch.refresh_areas()
	_spots.clear()
	_build_spots()


func _start_placing(id: String) -> void:
	_placing = id
	if _ghost == null:
		_ghost = MeshInstance3D.new()
		_ghost.mesh = BoxMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost.material_override = m
		add_child(_ghost)
		_ghost_door = MeshInstance3D.new()
		_ghost_door.mesh = BoxMesh.new()
		var dm := StandardMaterial3D.new()
		dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.albedo_color = _look.color("town", "ghost_door")
		_ghost_door.material_override = dm
		add_child(_ghost_door)
	_ghost.visible = true
	_ghost_door.visible = true
	_place_bar.visible = true
	_update_ghost()


## Puts the footprint in front of the farmer and colors it green (free) or red (taken).
func _update_ghost() -> void:
	var size: Vector2i = TownPlan.placeable_size(_look, _placing)
	var yaw: float = _fisherman.rotation.y
	var ahead := Vector2(sin(yaw), cos(yaw))
	var reach: float = maxf(float(size.x), float(size.y)) * 0.5 + _look.num("town", "ghost_ahead")
	var center: Vector2 = _fisherman.ground_pos + ahead * reach
	_ghost_rect = Rect2i(roundi(center.x - float(size.x) * 0.5), roundi(center.y - float(size.y) * 0.5), size.x, size.y)
	_ghost_ok = _state.map == GameState.MAP_OUTDOOR and _place_ok(_ghost_rect)
	var c := Vector3(float(_ghost_rect.position.x) + float(size.x) * 0.5, 0.25, float(_ghost_rect.position.y) + float(size.y) * 0.5)
	_ghost.position = c
	(_ghost.mesh as BoxMesh).size = Vector3(float(size.x), 0.5, float(size.y))
	(_ghost.material_override as StandardMaterial3D).albedo_color = _look.color("town", "ghost_ok" if _ghost_ok else "ghost_bad")
	_ghost_door.position = Vector3(float(_ghost_rect.position.x + size.x / 2) + 0.5, 0.1, float(_ghost_rect.end.y) + 0.5)
	(_ghost_door.mesh as BoxMesh).size = Vector3(0.9, 0.2, 0.9)


## The footprint is free: grass, flowers or sand, nothing solid except the loose trees and rocks
## of the farm (the builders clear those), and the door block can be walked.
func _place_ok(rect: Rect2i) -> bool:
	var grid: WorldGrid = _world.grid
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var t: int = grid.tile_at(x, y)
			if t != WorldGrid.Tile.GRASS and t != WorldGrid.Tile.FLOWERS and t != WorldGrid.Tile.SAND:
				return false
			if grid.has_solid_flag(x, y) and not _loose_prop_at(Vector2i(x, y)):
				return false
	var door := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)
	return grid.tile_at(door.x, door.y) >= 0 and not grid.is_water(door.x, door.y) and (not grid.has_solid_flag(door.x, door.y) or _loose_prop_at(door))


func _loose_prop_at(cell: Vector2i) -> bool:
	for index: int in _world.props.cuttable():
		var p: WorldGrid.Placement = _world.grid.placements[index]
		if p.cell == cell and p.zone == "":
			return true
	return false


## Removes the loose trees and rocks under [param rect] (and its door) for good.
func _clear_under(rect: Rect2i) -> void:
	_world.props.hide_decor_in(rect)
	var door := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)
	for index: int in _world.props.cuttable():
		var p: WorldGrid.Placement = _world.grid.placements[index]
		if p.zone == "" and (rect.has_point(p.cell) or p.cell == door):
			_state.chopped[str(index)] = 1 << 30
			_set_cut(index, true)


func _confirm_placing() -> void:
	if not _ghost_ok or not _place_ok(_ghost_rect):
		_sfx.play(&"error")
		_screens.toast(Texts.get_text("place_bad"))
		return
	if _farm.build_blocker(_placing) != Farm.Result.OK:
		_sfx.play(&"error")
		_screens.toast(Texts.get_text("build_missing"))
		_cancel_placing()
		return
	_clear_under(_ghost_rect)
	TownPlan.place(_world.grid, _placing, _ghost_rect, 0)
	_farm.build(_placing)
	_state.placed[_placing] = [_ghost_rect.position.x, _ghost_rect.position.y, _ghost_rect.size.x, _ghost_rect.size.y, 0]
	_town_view.add_lot(_placing)
	_after_placement()
	_sfx.play(&"level")
	_screens.toast(Texts.get_text("built_ok"))
	_save_soon = true
	_cancel_placing()


func _cancel_placing() -> void:
	_placing = ""
	if _ghost != null:
		_ghost.visible = false
		_ghost_door.visible = false
	_place_bar.visible = false


# --- The house (2026-11-22) ---

func _label_sofa() -> String:
	return Texts.get_text("act_sofa_stop") if _state.resting else Texts.get_text("act_sofa")


func _enter_house() -> void:
	if not _machine.is_idle():
		return
	_sfx.play(&"click")
	_state.map = GameState.MAP_INDOOR
	_apply_space()
	_fisherman.teleport(_house.entry())
	_save_soon = true


func _exit_house() -> void:
	_sfx.play(&"click")
	_state.resting = false
	_state.map = GameState.MAP_OUTDOOR
	_apply_space()
	_fisherman.teleport(Vector2(WorldGrid.DOOR) + Vector2(0.5, 1.4))
	_save_soon = true


func _enter_barn() -> void:
	if not _machine.is_idle():
		return
	_sfx.play(&"click")
	_state.resting = false
	_state.map = GameState.MAP_BARN
	_apply_space()
	_fisherman.teleport(_barn.entry())
	_save_soon = true


func _exit_barn() -> void:
	_sfx.play(&"click")
	_state.map = GameState.MAP_OUTDOOR
	_apply_space()
	_fisherman.teleport(TownPlan.lot_door(_look, "galpao") + Vector2(0.0, 0.8))
	_save_soon = true


## Puts the fisherman, camera and light in the house, the barn or back on the farm.
func _apply_space() -> void:
	var in_house: bool = _state.map == GameState.MAP_INDOOR
	var in_barn: bool = _state.map == GameState.MAP_BARN
	var inside: bool = in_house or in_barn
	_fisherman.blocked_fn = _house.is_blocked if in_house else (_barn.is_blocked if in_barn else Callable())
	_fisherman.height_fn = _house.floor_height if in_house else (_barn.floor_height if in_barn else Callable())
	_fisherman.set_rod_visible(_state.rod_out and not inside)
	_cycle.indoor = inside
	var bounds: Rect2 = _house.bounds() if in_house else (_barn.bounds() if in_barn else Rect2())
	var view: float = _look.num("camera", "indoor_size") if in_house else (_look.num("barn", "camera_size") if in_barn else _look.num("camera", "size"))
	_camera.set_bounds(bounds, view)
	_cycle.update(_state.minutes)


## Sleep (2026-11-22): the farmer lies down in bed, the night passes behind the sleep screen
## and he gets up next to the bed ([method _update_bed] runs the steps).
func _sleep_in_bed() -> void:
	if _bed_phase != 0:
		return
	_sfx.play(&"click")
	_state.resting = false
	var lie: Array = _house.lie_spot(_look.num("player", "model_height"))
	_fisherman.lie_down(lie[0], lie[1])
	_bed_phase = 1
	_bed_timer = _look.num("interior", "lie_seconds")


func _update_bed(delta: float) -> void:
	if _bed_phase == 0:
		return
	_bed_timer -= delta
	if _bed_timer > 0.0:
		return
	if _bed_phase == 1:
		_bed_phase = 2
		_bed_timer = _look.num("interior", "wake_seconds")
		_clock.sleep_new_day(false)
	else:
		_bed_phase = 0
		_fisherman.stand_up()


func _use_plot_tap(i: int) -> void:
	match _production.plot_stage(i):
		0:
			_sfx.play(&"click")
			_screens.open_plant(i)
		2:
			var r: Production.Result = _production.harvest(i)
			_sfx.play(&"coin" if r == Production.Result.OK else &"error")
			if r != Production.Result.OK:
				_screens.toast(Texts.get_text("silo_full"))
		_:
			var crop: Dictionary = _production.crop(str(_state.crop_plots[i]["crop"]))
			_screens.toast(Texts.fmt("plot_left", [str(crop["name"]), _screens._ptime(_production.seconds_left(float(_state.crop_plots[i]["ready_at"])))]))


func _on_material(id: String) -> void:
	_sfx.play(&"level")
	_screens.toast(Texts.fmt("material_drop", [_town_data.good_name(id)]))


func _on_farm_level_up(level: int) -> void:
	_sfx.play(&"level")
	_screens.toast(Texts.fmt("farm_up", [level]))


func _open_settings() -> void:
	_sfx.play(&"click")
	_screens.open_settings()


func _on_fish_caught(fish: GameState.Catch, _is_new: bool, _is_record: bool) -> void:
	_sfx.play(&"catch")
	_farm.add_xp(_farm.xp_for_catch(_data.species_by_id(fish.id).rarity))
	_production.roll_drop("fish")
	_save_soon = true


func _on_fish_sold(_count: int, _coins: int) -> void:
	_save_soon = true


func _on_fish_bit(_species: GameData.Species) -> void:
	_sfx.play(&"bite")


func _mark_save() -> void:
	_save_soon = true


## Starts play: a new game ([param fresh]) or the saved one.
func _begin(fresh: bool) -> void:
	_set_menu_mode(false)
	if not fresh:
		SaveGame.apply(_state, _data, SaveGame.read())
		var pos := Vector2(_state.position.x, _state.position.z) / WorldGrid.PIXELS_PER_BLOCK
		if _state.position != Vector3.ZERO and _world.grid.box_free(pos.x, pos.y, 0.25, 0.16):
			_fisherman.teleport(pos)
	# Placed buildings first: boxes, animals and spots of a loaded save look their lots up.
	for key: Variant in _state.chopped:
		_set_cut(int(str(key)), true)
	_restore_placements()
	_state.town_changed.emit()
	_production.setup_state()
	_apply_space()
	if _state.map == GameState.MAP_INDOOR:
		_fisherman.teleport(_house.entry())
	elif _state.map == GameState.MAP_BARN:
		_fisherman.teleport(_barn.entry())
	_town_view.set_production(_production)
	for zone: String in _state.expanded:
		_open_area(zone)
	_state.town_changed.connect(_check_areas)
	_town.ensure_requests()
	_dress()
	_apply_rod()
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
	_fisherman.set_rod_color(Color.html(_data.rod_by_id(_state.rod).color))


func _process(delta: float) -> void:
	if _fisherman == null:
		return
	_cycle.update(_state.minutes)
	var dir: Vector2 = _stick.value
	var run: bool = dir.length() >= _run_threshold
	var keys: Vector2 = _keyboard_direction()
	if keys != Vector2.ZERO:
		dir = keys
		run = Input.is_physical_key_pressed(KEY_SHIFT)
	var phase: FishingMachine.Phase = _machine.phase
	_update_bed(delta)
	if not _started or _screens.is_open() or _bed_phase != 0:
		dir = Vector2.ZERO
	if phase == FishingMachine.Phase.BITE or phase == FishingMachine.Phase.FIGHT or phase == FishingMachine.Phase.CAUGHT or _fishing_hud.card_open:
		dir = Vector2.ZERO
	elif dir != Vector2.ZERO and (phase == FishingMachine.Phase.CAST or phase == FishingMachine.Phase.WAIT):
		_cancel_pending = true
	# Screen-space input (up = -y, right = +x) to world ground direction (x, z): the camera is
	# yawed by +_input_yaw around Y, so rotate the input by -_input_yaw (Vector2.rotated).
	_fisherman.step(delta, dir.rotated(-_input_yaw), run)
	if _fisherman.swimming and dir != Vector2.ZERO:
		_state.energy = maxf(0.0, _state.energy - _look.num("player", "swim_energy_per_second") * delta)
	_actions.set_resting(_state.resting)
	if _placing != "":
		_update_ghost()
	# During the minigame only PUXAR matters: the side buttons and the joystick step aside.
	var fighting: bool = phase == FishingMachine.Phase.FIGHT or phase == FishingMachine.Phase.CAUGHT
	_actions.visible = not fighting and _placing == "" and _started
	_fishing_hud.pull.visible = _placing == "" and not _fishing_hud.card_open
	_stick.visible = not fighting and _started
	# Fishing only happens outside: no cast button or water hint in the house or the barn.
	_fishing_hud.visible = _started and _state.map == GameState.MAP_OUTDOOR
	_update_spot()
	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	if e_down and not _e_was_down and _started and not _screens.is_open():
		_use_spot()
	_e_was_down = e_down


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
	if press and phase == FishingMachine.Phase.IDLE and not _state.rod_out:
		_toggle_rod()
		press = false
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
	_prod_timer -= delta
	if _prod_timer <= 0.0:
		_prod_timer = 1.0
		_production.tick()
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
	if _npcs != null:
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
		pass


## A tap on the world: a field plot plants or harvests (2026-11-22); a neighbor opens the
## dialog (Story 013); otherwise it casts.
func _tap(screen_pos: Vector2) -> void:
	var ground: Variant = Plane(Vector3.UP, 0.15).intersects_ray(_camera.project_ray_origin(screen_pos), _camera.project_ray_normal(screen_pos))
	if ground != null and _state.map == GameState.MAP_OUTDOOR:
		var g: Vector3 = ground
		var plot: int = _field_view.plot_at(Vector2(g.x, g.z))
		if plot >= 0:
			_use_plot_tap(plot)
			return
	var who: String = _npcs.npc_at_screen(_camera, screen_pos, _look.num("npc", "tap_radius") * 60.0) if _npcs != null else ""
	if who != "" and _machine.is_idle():
		_sfx.play(&"click")
		_screens.open_neighbor(who)
		return
	_cast_at_screen(screen_pos)


## Casts to the water point under [param screen_pos]: the camera ray meets the water plane.
func _cast_at_screen(screen_pos: Vector2) -> void:
	if not _state.rod_out:
		return
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
	if _fisherman.swimming:
		_fishing_hud.show_toast("cast_swimming")
		return
	_sync_position()
	_fisherman.set_rod_color(Color.html(_data.rod_by_id(_state.rod).color))
	var result: FishingMachine.CastResult = _machine.cast_at(LakeWorldQuery.to_query_pos(Vector3(world_point.x, 0.0, world_point.z)))
	if result == FishingMachine.CastResult.CAST:
		_fisherman.face_toward(world_point)
		_sfx.play(&"cast")
	else:
		_show_cast_result(result)


func _show_cast_result(result: FishingMachine.CastResult) -> void:
	if result != FishingMachine.CastResult.BUSY:
		_fishing_hud.show_toast("cast_" + FishingMachine.CastResult.keys()[result].to_lower())


## Puts the rod away or takes it out (only while not fishing).
func _toggle_rod() -> void:
	if not _machine.is_idle():
		_screens.toast(Texts.get_text("rod_busy"))
		return
	_state.rod_out = not _state.rod_out
	_apply_rod()
	_sfx.play(&"click")
	_screens.toast(Texts.get_text("rod_taken") if _state.rod_out else Texts.get_text("rod_stowed"))
	_save_soon = true


func _apply_rod() -> void:
	_fisherman.set_rod_visible(_state.rod_out)
	_fishing_hud.rod_out = _state.rod_out
	_actions.set_rod(_state.rod_out)


func _toggle_rest() -> void:
	var result: Energy.Result = _energy.toggle_rest()
	if result == Energy.Result.BUSY_FISHING:
		_fishing_hud.show_toast("rest_busy")
	elif result == Energy.Result.ENERGY_FULL:
		_fishing_hud.show_toast("rest_full")


func _on_day_started(day: int, auto: bool) -> void:
	_town.on_new_day()
	if _state.map == GameState.MAP_BARN:
		# Falling asleep in the barn: he wakes up at home, on the farm.
		_state.map = GameState.MAP_OUTDOOR
		_apply_space()
	if _state.map == GameState.MAP_INDOOR:
		_screens.show_sleep(day, auto)
		_fisherman.teleport(_house.spot("bed"))
		for index: int in _farm.regrow():
			_set_cut(index, false)
		_save_soon = true
		return
	for index: int in _farm.regrow():
		_set_cut(index, false)
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
	if TownPlan.has_lot(_look, "galpao"):
		_add_spot(TownPlan.lot_door(_look, "galpao"), reach, _label_fixed.bind("act_enter_barn"), _enter_barn)
	if TownPlan.has_lot(_look, "silo"):
		_add_spot(TownPlan.lot_door(_look, "silo"), reach, _label_fixed.bind("silo_name"), _screens.open_silo)
	for home: String in ["galinheiro", "curral", "chiqueiro", "ovelhas"]:
		if TownPlan.has_lot(_look, home):
			_add_spot(TownPlan.lot_door(_look, home), reach, _label_home.bind(home), _use_home.bind(home))
	for id: Variant in _production.factory_ids():
		var fid: String = str(id)
		if TownPlan.has_lot(_look, fid):
			_add_spot(TownPlan.lot_door(_look, fid), reach, _label_factory.bind(fid), _use_factory.bind(fid))
	if TownPlan.has_lot(_look, "plantacao"):
		_add_spot(TownPlan.lot_door(_look, "plantacao"), reach + 1.0, _label_fixed.bind("act_field"), _screens.open_field)
	_add_spot(Vector2(WorldGrid.DOOR) + Vector2(0.5, 1.2), reach, _label_fixed.bind("act_enter"), _enter_house)
	_indoor_spots.clear()
	for entry: Array in [["door", "act_exit", _exit_house], ["bed", "act_sleep", _sleep_in_bed], ["sofa", "act_sofa", _toggle_rest]]:
		var spot := Spot.new()
		spot.pos = _house.spot(str(entry[0]))
		spot.radius = 1.3
		spot.label = _label_sofa if entry[0] == "sofa" else _label_fixed.bind(str(entry[1]))
		spot.action = entry[2]
		_indoor_spots.append(spot)
	_barn_spots.clear()
	for entry: Array in [["door", "act_exit", _exit_barn, 1.3], ["chests", "act_chests", _screens.open_chests, 3.0]]:
		var spot := Spot.new()
		spot.pos = _barn.spot(str(entry[0]))
		spot.radius = float(entry[3])
		spot.label = _label_upstairs if entry[0] == "chests" else _label_fixed.bind(str(entry[1]))
		spot.action = entry[2]
		_barn_spots.append(spot)
	if TownPlan.has_lot(_look, "quadro"):
		_add_spot(TownPlan.lot_door(_look, "quadro"), reach, _label_fixed.bind("act_orders"), _screens.open_orders)
	if TownPlan.has_lot(_look, "barraca"):
		_add_spot(TownPlan.lot_door(_look, "barraca"), reach, _label_fixed.bind("act_stall"), _screens.open_stall.bind(-1, "", 1, -1))
	for id: String in TownPlan.expansion_ids(_look):
		_add_spot(TownPlan.expansion_sign(_look, id), reach + 0.5, _label_expand.bind(id), _screens.open_expand.bind(id))
	if _look.has("town", "city_gate"):
		var g: Array = _look.raw("town", "city_gate")
		_add_spot(Vector2(float(g[0]) - 0.5, float(g[1]) + float(g[3]) * 0.5), 2.5, _label_fixed.bind("act_city"), _screens.toast.bind(Texts.get_text("city_soon")))
	for index: int in _world.props.cuttable():
		var p: WorldGrid.Placement = _world.grid.placements[index]
		if p.zone != "":
			continue
		var rock: bool = p.kind == &"rock"
		_add_spot(Vector2(p.cell) + Vector2(0.5, 0.5), 1.35, _label_cut.bind(index, rock), _cut.bind(index, rock))


func _label_fixed(key: String) -> String:
	return Texts.get_text(key)


## "Baús" only up on the barn loft (the ground under it is close but not the same floor).
func _label_upstairs() -> String:
	return Texts.get_text("act_chests") if _fisherman.position.y > _look.num("barn", "loft_height") * 0.8 else ""


func _label_expand(id: String) -> String:
	if _state.expanded.has(id):
		return ""
	return Texts.fmt("act_expand", [str(_production.expansion(id).get("name", id))])


## True when lot [param id] sits in an expansion area that is still closed.
func _in_closed_area(id: String) -> bool:
	for zone: String in TownPlan.expansion_ids(_look):
		if not _state.expanded.has(zone) and TownPlan.expansion_rect(_look, zone).intersects(TownPlan.lot_rect(_look, id)):
			return true
	return false


func _label_factory(id: String) -> String:
	if _in_closed_area(id):
		return ""
	var name: String = str(_town_data.lot(id).get("name", id))
	if not _state.is_built(id):
		return Texts.fmt("act_build", [name])
	var done: int = _production.factory_done(id)
	return Texts.fmt("act_collect", [done]) if done > 0 else name


func _use_factory(id: String) -> void:
	_sfx.play(&"click")
	if not _state.is_built(id):
		_screens.open_build(id)
	elif _production.factory_done(id) > 0 and _production.collect_factory(id) == Production.Result.OK:
		_sfx.play(&"coin")
		_screens.toast(Texts.get_text("collected"))
	else:
		_screens.open_factory(id)


func _label_home(home: String) -> String:
	if _in_closed_area(home):
		return ""
	var name: String = str(_town_data.lot(home).get("name", home))
	if not _state.is_built(home):
		return Texts.fmt("act_build", [name])
	var ready: int = _production.ready_in(home)
	if ready > 0:
		return Texts.fmt("act_milk", [ready]) if home == "curral" else Texts.fmt("act_collect", [ready])
	return name


## An animal home door: build it, collect (or milk) what is ready, or open its screen.
func _use_home(home: String) -> void:
	if not _state.is_built(home):
		_sfx.play(&"click")
		_screens.open_build(home)
	elif _production.ready_in(home) > 0:
		var r: Production.Result = _production.collect_home(home)
		_sfx.play(&"coin" if r == Production.Result.OK else &"error")
		_screens.toast(Texts.get_text("collected") if r == Production.Result.OK else Texts.get_text("barn_full"))
	else:
		_sfx.play(&"click")
		_screens.open_ranch(home)


func _label_cut(index: int, rock: bool) -> String:
	if _state.chopped.has(str(index)):
		return ""
	return Texts.get_text("act_rock" if rock else "act_chop")


## Cuts the tree or breaks the rock of placement [param index].
func _cut(index: int, rock: bool) -> void:
	var r: Farm.Result = _farm.gather(index, rock)
	if r == Farm.Result.OK:
		_set_cut(index, true)
		_sfx.play(&"coin")
		_screens.toast(Texts.fmt("broke" if rock else "chopped", [int(_town_data.num("farm_life", "stone_yield" if rock else "wood_yield"))]))
	else:
		_sfx.play(&"error")
		var why: String = Texts.get_text("no_energy")
		if r == Farm.Result.BAG_FULL:
			why = Texts.get_text("barn_full")
		elif r == Farm.Result.MISSING:
			why = Texts.get_text("need_pickaxe" if rock else "need_axe")
		_screens.toast(why)


## Opens the trees of an expansion area that was just bought (or loaded as bought).
func _check_areas() -> void:
	for zone: String in _state.expanded:
		if not _opened.has(zone):
			_open_area(zone)


func _open_area(zone: String) -> void:
	_opened[zone] = true
	for index in _world.grid.placements.size():
		if _world.grid.placements[index].zone == zone:
			_world.props.set_cut(index, true)
	TownPlan.open_expansion(_world.grid, _look, zone)


## Hides or shows a cut tree or rock and frees or blocks its block.
func _set_cut(index: int, cut: bool) -> void:
	if index < 0 or index >= _world.grid.placements.size():
		return
	var cell: Vector2i = _world.grid.placements[index].cell
	_world.props.set_cut(index, cut)
	_world.grid.set_solid(cell.x, cell.y, not cut)


func _add_spot(pos: Vector2, radius: float, label: Callable, action: Callable) -> void:
	var spot := Spot.new()
	spot.pos = pos
	spot.radius = radius
	spot.label = label
	spot.action = action
	_spots.append(spot)


## Finds the nearest usable spot in reach and shows the context button.
func _update_spot() -> void:
	_spot = null
	var text: String = ""
	if _started and not _screens.is_open() and _machine.is_idle() and _bed_phase == 0:
		var me: Vector2 = _fisherman.ground_pos
		var best: float = INF
		for spot: Spot in (_indoor_spots if _state.map == GameState.MAP_INDOOR else (_barn_spots if _state.map == GameState.MAP_BARN else _spots)):
			var d: float = me.distance_to(spot.pos)
			if d <= spot.radius and d < best:
				var label: String = spot.label.call()
				if label != "":
					best = d
					_spot = spot
					text = label
		var boxes: Array[Vector2] = _truck.box_spots() if _state.map == GameState.MAP_OUTDOOR else ([] as Array[Vector2])
		for i in boxes.size():
			var d: float = me.distance_to(boxes[i])
			if d <= _look.num("town", "door_reach") and d < best:
				best = d
				_box_spot.action = _open_box.bind(i)
				_spot = _box_spot
				text = Texts.get_text("act_box")
	_actions.show_context(text)


func _open_box(index: int) -> void:
	if _farm.open_box(index) == Farm.Result.OK:
		_sfx.play(&"coin")
		_screens.toast(Texts.get_text("box_opened"))


func _use_spot() -> void:
	if _spot != null:
		_spot.action.call()


## The shop is on the phone (farm map): it opens anywhere.
func _open_shop_if_near() -> void:
	_sfx.play(&"click")
	_screens.open_shop()


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
