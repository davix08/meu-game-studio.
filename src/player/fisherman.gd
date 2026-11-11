class_name Fisherman
extends Node3D
## The 3D fisherman: a character built from simple colored shapes (body, head, straw hat,
## backpack, arms, legs) with procedural animation (idle breathing, walk and run swing). It
## moves by the [WorldGrid] only (axis by axis, feet box, like moveBody of the 2D prototype),
## with no engine physics, and turns toward the movement direction. +Z is the character's front.
##
## Story 002 (design/game-brief.md, MVP feature 9). Speeds are given in meters per second
## (the config.json pixel speeds divided by [constant WorldGrid.PIXELS_PER_BLOCK]).
##
## Usage:
## [codeblock]
## fisherman.setup(look, grid, terrain, 52.0 / 16.0, 88.0 / 16.0)
## fisherman.step(delta, Vector2(1.0, 0.0), false)  # walk east
## [/codeblock]

## Position on the ground in blocks (x, z).
var ground_pos: Vector2 = WorldGrid.SPAWN

var _grid: WorldGrid
var _terrain: LakeTerrain
var _walk_speed: float = 0.0
var _run_speed: float = 0.0
var _half_width: float = 0.0
var _half_depth: float = 0.0
var _turn_speed: float = 0.0
var _height_follow: float = 0.0
var _max_step: float = 0.0
var _hip_height: float = 0.0
var _blend_speed: float = 0.0
var _walk_freq: float = 0.0
var _run_freq: float = 0.0
var _walk_leg: float = 0.0
var _run_leg: float = 0.0
var _walk_arm: float = 0.0
var _run_arm: float = 0.0
var _run_lean: float = 0.0
var _bob: float = 0.0
var _breath_freq: float = 0.0
var _breath_amount: float = 0.0
var _idle_sway: float = 0.0
var _phase: float = 0.0
var _idle_time: float = 0.0
var _move_blend: float = 0.0
var _run_blend: float = 0.0
var _torso: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _leg_left: Node3D
var _leg_right: Node3D
var _material: StandardMaterial3D


## Reads the tuning from [param look], builds the model and places it at the spawn point.
func setup(look: WorldLook, grid: WorldGrid, terrain: LakeTerrain, walk_speed: float, run_speed: float) -> void:
	_grid = grid
	_terrain = terrain
	_walk_speed = walk_speed
	_run_speed = run_speed
	_half_width = look.num("player", "feet_half_width")
	_half_depth = look.num("player", "feet_half_depth")
	_turn_speed = look.num("player", "turn_speed")
	_height_follow = look.num("player", "height_follow")
	_max_step = look.num("player", "max_step_seconds")
	_hip_height = look.num("player", "hip_height")
	_blend_speed = look.num("player", "blend_speed")
	_walk_freq = look.num("player", "walk_freq")
	_run_freq = look.num("player", "run_freq")
	_walk_leg = deg_to_rad(look.num("player", "walk_leg_degrees"))
	_run_leg = deg_to_rad(look.num("player", "run_leg_degrees"))
	_walk_arm = deg_to_rad(look.num("player", "walk_arm_degrees"))
	_run_arm = deg_to_rad(look.num("player", "run_arm_degrees"))
	_run_lean = deg_to_rad(look.num("player", "run_lean_degrees"))
	_bob = look.num("player", "bob_height")
	_breath_freq = look.num("player", "breath_freq")
	_breath_amount = look.num("player", "breath_amount")
	_idle_sway = look.num("player", "idle_arm_sway")
	scale = Vector3.ONE * look.num("player", "model_scale")
	_material = MeshBuilder.make_material(look.num("player", "roughness"))
	_build_model(look)
	ground_pos = WorldGrid.SPAWN
	position = Vector3(ground_pos.x, terrain.ground_height_at(ground_pos.x, ground_pos.y), ground_pos.y)


## Advances one frame. [param dir] is the wanted direction on the ground (x east, y south; any
## length above 0 means "move"); [param run] picks the run speed.
func step(delta: float, dir: Vector2, run: bool) -> void:
	var dt: float = minf(delta, _max_step)
	var before: Vector2 = ground_pos
	var wants_move: bool = dir.length_squared() > 0.0001
	if wants_move:
		var move: Vector2 = dir.normalized() * (_run_speed if run else _walk_speed) * dt
		if move.x != 0.0 and _grid.box_free(ground_pos.x + move.x, ground_pos.y, _half_width, _half_depth):
			ground_pos.x += move.x
		if move.y != 0.0 and _grid.box_free(ground_pos.x, ground_pos.y + move.y, _half_width, _half_depth):
			ground_pos.y += move.y
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.y), 1.0 - exp(-_turn_speed * delta))
	var moved: bool = ground_pos.distance_squared_to(before) > 0.0000001
	_animate(delta, moved, run)
	var ground: float = _terrain.ground_height_at(ground_pos.x, ground_pos.y)
	var y: float = lerpf(position.y, ground, 1.0 - exp(-_height_follow * delta))
	position = Vector3(ground_pos.x, y, ground_pos.y)


func _animate(delta: float, moving: bool, running: bool) -> void:
	_move_blend = move_toward(_move_blend, 1.0 if moving else 0.0, delta * _blend_speed)
	_run_blend = move_toward(_run_blend, 1.0 if (moving and running) else 0.0, delta * _blend_speed)
	_phase += delta * lerpf(_walk_freq, _run_freq, _run_blend) * _move_blend
	_idle_time += delta
	var leg_amp: float = lerpf(_walk_leg, _run_leg, _run_blend) * _move_blend
	var arm_amp: float = lerpf(_walk_arm, _run_arm, _run_blend) * _move_blend
	var swing: float = sin(_phase)
	var idle: float = 1.0 - _move_blend
	var sway: float = sin(_idle_time * _breath_freq) * _idle_sway * idle
	_leg_left.rotation.x = swing * leg_amp
	_leg_right.rotation.x = -swing * leg_amp
	_arm_left.rotation.x = -swing * arm_amp + sway
	_arm_right.rotation.x = swing * arm_amp + sway
	_torso.scale = Vector3(1.0, 1.0 + sin(_idle_time * _breath_freq) * _breath_amount * idle, 1.0)
	_torso.position.y = _hip_height + absf(cos(_phase)) * _bob * _move_blend
	_torso.rotation.x = _run_lean * _run_blend


func _build_model(look: WorldLook) -> void:
	var skin: Color = look.color("colors", "skin")
	var shirt: Color = look.color("colors", "shirt")
	var hat: Color = look.color("colors", "hat")
	var band: Color = look.color("colors", "hat_band")
	var pack: Color = look.color("colors", "pack")
	var pack_dark: Color = look.color("colors", "pack_dark")
	var pants: Color = look.color("colors", "pants")
	var boots: Color = look.color("colors", "boots")
	var eye: Color = look.color("colors", "eye")

	# Torso (pivot at the hip): body, backpack, head, eyes and hat.
	_torso = Node3D.new()
	_torso.position = Vector3(0.0, _hip_height, 0.0)
	add_child(_torso)
	var body := MeshBuilder.new()
	body.add_box(Vector3(0.0, 0.22, 0.0), Vector3(0.4, 0.44, 0.26), shirt)
	body.add_box(Vector3(0.0, 0.22, -0.2), Vector3(0.3, 0.34, 0.14), pack)
	body.add_box(Vector3(0.0, 0.42, -0.2), Vector3(0.32, 0.1, 0.16), pack_dark)
	body.add_ellipsoid(Vector3(0.0, 0.63, 0.0), Vector3(0.17, 0.18, 0.16), skin, skin, 8, 6, true)
	body.add_ellipsoid(Vector3(-0.06, 0.64, 0.14), Vector3(0.025, 0.025, 0.02), eye, eye, 5, 3, true)
	body.add_ellipsoid(Vector3(0.06, 0.64, 0.14), Vector3(0.025, 0.025, 0.02), eye, eye, 5, 3, true)
	body.add_cone(Vector3(0.0, 0.72, 0.0), 0.3, 0.3, 0.035, hat, hat, 12, true, true)
	body.add_cone(Vector3(0.0, 0.745, 0.0), 0.17, 0.13, 0.13, hat, hat, 10, true)
	body.add_cone(Vector3(0.0, 0.745, 0.0), 0.175, 0.175, 0.04, band, band, 10)
	_add_part(_torso, body.build(), Vector3.ZERO)

	# Arms (pivot at the shoulder): sleeve and hand.
	_arm_left = _make_limb(_torso, Vector3(-0.26, 0.38, 0.0), shirt, skin, true)
	_arm_right = _make_limb(_torso, Vector3(0.26, 0.38, 0.0), shirt, skin, true)
	# Legs (pivot at the hip): trousers and boot.
	_leg_left = _make_limb(self, Vector3(-0.1, _hip_height, 0.0), pants, boots, false)
	_leg_right = _make_limb(self, Vector3(0.1, _hip_height, 0.0), pants, boots, false)


## A swinging limb: a pivot at [param pivot_pos] with a long part and an end part.
func _make_limb(parent: Node3D, pivot_pos: Vector3, main_color: Color, end_color: Color, is_arm: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	parent.add_child(pivot)
	var builder := MeshBuilder.new()
	if is_arm:
		builder.add_box(Vector3(0.0, -0.13, 0.0), Vector3(0.11, 0.26, 0.13), main_color)
		builder.add_ellipsoid(Vector3(0.0, -0.3, 0.0), Vector3(0.06, 0.06, 0.06), end_color, end_color, 6, 4, true)
	else:
		builder.add_box(Vector3(0.0, -0.17, 0.0), Vector3(0.15, 0.34, 0.17), main_color)
		builder.add_box(Vector3(0.0, -0.395, 0.02), Vector3(0.16, 0.11, 0.22), end_color)
	_add_part(pivot, builder.build(), Vector3.ZERO)
	return pivot


func _add_part(parent: Node3D, part_mesh: ArrayMesh, pos: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = part_mesh
	node.material_override = _material
	node.position = pos
	parent.add_child(node)
