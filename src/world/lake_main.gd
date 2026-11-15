class_name LakeMain
extends Node3D
## Root script of scenes/main.tscn: builds everything in code (world, fisherman, camera, HUD,
## joystick, fishing) and feeds the fisherman from the joystick or the keyboard (WASD / arrows,
## Shift to run; read with Input.is_physical_key_pressed, so the InputMap is untouched). The input
## is screen-relative: it is rotated by the isometric camera yaw before moving the fisherman.
##
## Fishing (Story 003): a tap on the world casts to the 3D water point under the finger (camera ray
## against the water plane, no physics); Space casts forward and, held, is PUXAR; Z toggles rest.
## [FishingMachine.step] and [Energy.step] run in _physics_process (fixed step). The machine works
## in 2D pixel units: the player position is synced as ground position x 16 every step.
## While a fish bites, fights or is caught the fisherman does not walk; walking while casting or
## waiting reels the line in.
##
## Story 002/003 (design/game-brief.md, MVP features 9 and 10). Walk and run speeds come from
## config.json (px/s, through [GameData]) and are converted to m/s by the 16 px per block scale.

## Distance step (in blocks) when looking for water ahead for the keyboard "cast forward".
const _FORWARD_STEP: float = 1.0

var _look: WorldLook
var _data: GameData
var _state: GameState
var _machine: FishingMachine
var _energy: Energy
var _life: WaterLife
var _world: LakeWorld
var _fisherman: Fisherman
var _camera: FollowCamera
var _stick: VirtualStick
var _fishing_hud: FishingHud
var _water_plane: Plane
var _water_y: float = 0.0
var _run_threshold: float = 0.95
var _input_yaw: float = 0.0 ## Camera yaw in radians (world_look.json camera.yaw_degrees).
var _key_was_down: bool = false
var _hold_stale: bool = false
var _cancel_pending: bool = false


func _ready() -> void:
	_look = WorldLook.load_file()
	_data = GameData.load_from_dir()
	if _look == null or _data == null:
		return
	_apply_performance()
	_world = LakeWorld.new()
	add_child(_world)
	_world.build(_look)

	_fisherman = Fisherman.new()
	add_child(_fisherman)
	_fisherman.setup(_look, _world.grid, _world.terrain, _data.tune("walk_speed") / WorldGrid.PIXELS_PER_BLOCK, _data.tune("run_speed") / WorldGrid.PIXELS_PER_BLOCK)

	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.setup(_look, _fisherman)

	var hud := Hud.new()
	add_child(hud)
	hud.setup(_look)
	_stick = VirtualStick.new()
	hud.add_child(_stick)
	_stick.setup(_look)
	_run_threshold = _look.num("joystick", "run_threshold")
	_input_yaw = deg_to_rad(_look.num("camera", "yaw_degrees"))

	_water_y = _look.num("terrain", "water_level")
	_water_plane = Plane(Vector3.UP, _water_y)
	_state = GameState.create_new(_data)
	var rng := RandomSource.new(_data.seed_value)
	_life = WaterLife.new()
	add_child(_life)
	_life.setup(_look, _data, _world.grid, rng, _water_y)
	_world.query.set_water_life(_life)
	var roller := FishRoller.new(_data, _state, rng)
	var progression := Progression.new(_data, _state)
	_machine = FishingMachine.new(_data, _state, rng, _world.query, roller, progression)
	_energy = Energy.new(_data, _state, _machine)
	var view := FishingView.new()
	add_child(view)
	view.setup(_look, _data, _machine, _fisherman, _life, _water_y)
	_fishing_hud = FishingHud.new()
	hud.add_child(_fishing_hud)
	_fishing_hud.setup(_look, _data, _state)
	_fishing_hud.bind(_machine)
	_fishing_hud.rest_pressed.connect(_toggle_rest)
	_fisherman.set_rod_color(Color.html(_data.rod_by_id(_state.rod).color))
	_sync_position()


func _process(delta: float) -> void:
	if _fisherman == null:
		return
	var dir: Vector2 = _stick.value
	var run: bool = dir.length() >= _run_threshold
	var keys: Vector2 = _keyboard_direction()
	if keys != Vector2.ZERO:
		dir = keys
		run = Input.is_physical_key_pressed(KEY_SHIFT)
	var phase: FishingMachine.Phase = _machine.phase
	if phase == FishingMachine.Phase.BITE or phase == FishingMachine.Phase.FIGHT or phase == FishingMachine.Phase.CAUGHT or _fishing_hud.card_open:
		dir = Vector2.ZERO
	elif dir != Vector2.ZERO and (phase == FishingMachine.Phase.CAST or phase == FishingMachine.Phase.WAIT):
		_cancel_pending = true
	# Screen-space input (up = -y, right = +x) to world ground direction (x, z): the camera is
	# yawed by +_input_yaw around Y, so rotate the input by -_input_yaw (Vector2.rotated).
	_fisherman.step(delta, dir.rotated(-_input_yaw), run)


func _physics_process(delta: float) -> void:
	if _machine == null:
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
	if _fishing_hud.card_open:
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
	if _machine.phase == FishingMachine.Phase.FIGHT:
		_fishing_hud.on_fight_step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _machine == null:
		return
	# Touches cast directly (one cast per touch); only a real mouse (DEVICE_ID_MOUSE, 4.7) casts
	# on click, so the mouse events Godot emulates from touches never cast a second time.
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_cast_at_screen(touch.position)
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.device == InputEvent.DEVICE_ID_MOUSE and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_cast_at_screen(click.position)
	elif event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and key.physical_keycode == KEY_Z:
			_toggle_rest()


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
	var reach: float = _data.rod_by_id(_state.rod).cast_range / WorldGrid.PIXELS_PER_BLOCK
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
	_fisherman.set_rod_color(Color.html(_data.rod_by_id(_state.rod).color))
	var result: FishingMachine.CastResult = _machine.cast_at(LakeWorldQuery.to_query_pos(Vector3(world_point.x, 0.0, world_point.z)))
	if result == FishingMachine.CastResult.CAST:
		_fisherman.face_toward(world_point)
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


## The machine measures distances in 2D pixels on the ground plane.
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
