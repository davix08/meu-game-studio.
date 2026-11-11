class_name LakeMain
extends Node3D
## Root script of scenes/main.tscn: builds everything in code (world, fisherman, camera, HUD,
## joystick) and feeds the fisherman from the joystick or the keyboard (WASD / arrows, Shift to
## run; read with Input.is_physical_key_pressed, so the InputMap is untouched).
##
## Story 002 (design/game-brief.md, MVP feature 9). Walk and run speeds come from config.json
## (px/s, through [GameData]) and are converted to m/s by the 16 px per block scale.

var _look: WorldLook
var _world: LakeWorld
var _fisherman: Fisherman
var _stick: VirtualStick
var _run_threshold: float = 0.95


func _ready() -> void:
	_look = WorldLook.load_file()
	var data: GameData = GameData.load_from_dir()
	if _look == null or data == null:
		return
	_apply_performance()
	_world = LakeWorld.new()
	add_child(_world)
	_world.build(_look)

	_fisherman = Fisherman.new()
	add_child(_fisherman)
	_fisherman.setup(_look, _world.grid, _world.terrain, data.tune("walk_speed") / WorldGrid.PIXELS_PER_BLOCK, data.tune("run_speed") / WorldGrid.PIXELS_PER_BLOCK)

	var camera := FollowCamera.new()
	add_child(camera)
	camera.setup(_look, _fisherman)

	var hud := Hud.new()
	add_child(hud)
	hud.setup(_look)
	_stick = VirtualStick.new()
	hud.add_child(_stick)
	_stick.setup(_look)
	_run_threshold = _look.num("joystick", "run_threshold")


func _process(delta: float) -> void:
	if _fisherman == null:
		return
	var dir: Vector2 = _stick.value
	var run: bool = dir.length() >= _run_threshold
	var keys: Vector2 = _keyboard_direction()
	if keys != Vector2.ZERO:
		dir = keys
		run = Input.is_physical_key_pressed(KEY_SHIFT)
	_fisherman.step(delta, dir, run)


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
