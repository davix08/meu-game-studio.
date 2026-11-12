class_name Fisherman
extends Node3D
## The 3D fisherman: a character built from simple colored shapes (chunky body, big head with
## grey beard, straw hat, vest, backpack, arms, legs) with procedural animation (idle breathing, walk and run swing, head sway). It
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
var _head: Node3D
var _head_sway: float = 0.0
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
	_head_sway = deg_to_rad(look.num("player", "head_sway_degrees"))
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
	var lean: float = _run_lean * _run_blend
	_torso.rotation.x = lean
	# The head keeps half of the lean level and rocks side to side with the steps (hat included).
	_head.rotation.x = -lean * 0.5
	_head.rotation.z = sin(_phase) * _head_sway * _move_blend * lerpf(0.5, 1.0, _run_blend)


## Builds the whole model from simple shapes (chunky, big-headed, like the 2D design sheets in
## references/). Every measure and color comes from world_look.json ("player" and "colors").
## Parts: torso (pelvis, cream shirt, red open vest, belt, backpack), head pivot (face, grey beard,
## curly hair, straw hat), two arms (shoulder pivots) and two legs (hip pivots).
func _build_model(look: WorldLook) -> void:
	var skin: Color = look.color("colors", "skin")
	var shirt: Color = look.color("colors", "shirt")
	var vest: Color = look.color("colors", "vest")
	var vest_edge: Color = look.color("colors", "vest_edge")
	var belt: Color = look.color("colors", "belt")
	var buckle: Color = look.color("colors", "buckle")
	var hat: Color = look.color("colors", "hat")
	var hat_dark: Color = look.color("colors", "hat_dark")
	var band: Color = look.color("colors", "hat_band")
	var pack: Color = look.color("colors", "pack")
	var pack_dark: Color = look.color("colors", "pack_dark")
	var pants: Color = look.color("colors", "pants")
	var boots: Color = look.color("colors", "boots")
	var eye: Color = look.color("colors", "eye")
	var hair: Color = look.color("colors", "hair")
	var beard: Color = look.color("colors", "beard")
	var beard_dark: Color = look.color("colors", "beard_dark")
	var tw: float = look.num("player", "torso_width")
	var th: float = look.num("player", "torso_height")
	var td: float = look.num("player", "torso_depth")
	var vest_y: float = 0.06 + th * 0.5

	# Torso (pivot at the hip): pelvis, shirt, vest, belt and backpack.
	_torso = Node3D.new()
	_torso.position = Vector3(0.0, _hip_height, 0.0)
	add_child(_torso)
	var body := MeshBuilder.new()
	body.add_box(Vector3(0.0, 0.0, 0.0), Vector3(tw * 0.86, 0.12, td * 0.86), pants)
	body.add_box(Vector3(0.0, vest_y, 0.0), Vector3(tw, th, td), shirt)
	for side: float in [-1.0, 1.0]:
		# Open vest: one panel on each side of the chest, with a darker border on the inner edge.
		body.add_box(Vector3(side * tw * 0.32, vest_y, td * 0.5 + 0.005), Vector3(tw * 0.38, th + 0.01, 0.045), vest)
		body.add_box(Vector3(side * tw * 0.14, vest_y, td * 0.5 + 0.008), Vector3(0.03, th + 0.012, 0.05), vest_edge)
	body.add_box(Vector3(0.0, vest_y, -(td * 0.5 + 0.005)), Vector3(tw + 0.02, th + 0.01, 0.045), vest)
	body.add_box(Vector3(0.0, 0.07, 0.0), Vector3(tw + 0.02, 0.06, td + 0.09), belt)
	body.add_box(Vector3(0.0, 0.07, td * 0.5 + 0.048), Vector3(0.07, 0.055, 0.02), buckle)
	var pack_w: float = tw * 0.7
	var pack_h: float = th * 0.85
	var pack_z: float = -(td * 0.5 + 0.0275 + 0.05)
	body.add_box(Vector3(0.0, vest_y - 0.01, pack_z), Vector3(pack_w, pack_h, 0.12), pack)
	body.add_box(Vector3(0.0, vest_y - 0.01 + pack_h * 0.5 - 0.02, pack_z - 0.01), Vector3(pack_w + 0.02, 0.09, 0.14), pack_dark)
	_add_part(_torso, body.build(), Vector3.ZERO)

	# Head (pivot at the neck, child of the torso so it sways and follows the lean).
	_head = Node3D.new()
	_head.position = Vector3(0.0, look.num("player", "head_offset"), 0.0)
	_torso.add_child(_head)
	var r := Vector3(look.num("player", "head_radius_x"), look.num("player", "head_radius_y"), look.num("player", "head_radius_z"))
	var c := Vector3(0.0, r.y * 0.9, 0.0)
	var hb := MeshBuilder.new()
	hb.add_ellipsoid(c, r, skin, skin, 10, 7, true)
	hb.add_ellipsoid(_on_head(c, r, 0.0, -0.14, 0.98), r * 0.17, skin, skin, 6, 4, true)
	for side: float in [-1.0, 1.0]:
		hb.add_ellipsoid(_on_head(c, r, 0.34 * side, 0.1, 0.93), Vector3(r.x * 0.12, r.y * 0.16, r.z * 0.09), eye, eye, 6, 4, true)
		hb.add_box(_on_head(c, r, 0.36 * side, 0.36, 0.88), Vector3(r.x * 0.34, r.y * 0.11, r.z * 0.14), hair)
		# Curly hair seen under the hat: sides and back.
		for u: Vector3 in [Vector3(0.96, -0.45, -0.2), Vector3(0.8, -0.5, -0.75), Vector3(0.4, -0.55, -0.95)]:
			hb.add_ellipsoid(_on_head(c, r, u.x * side, u.y, u.z), Vector3.ONE * r.x * 0.28, hair, hair, 6, 4, true)
	hb.add_ellipsoid(_on_head(c, r, 0.0, -0.4, -1.05), Vector3.ONE * r.x * 0.28, hair, hair, 6, 4, true)
	hb.add_ellipsoid(_on_head(c, r, 0.0, 0.18, -0.18), Vector3(r.x * 1.08, r.y * 0.95, r.z * 1.05), hair, hair, 8, 5, true)
	# Full grey beard (chin and cheeks) with a moustache.
	hb.add_ellipsoid(_on_head(c, r, 0.0, -0.5, 0.23), Vector3(r.x * 1.04, r.y * 0.68, r.z * 0.9), beard_dark, beard, 10, 6, true)
	hb.add_ellipsoid(_on_head(c, r, 0.0, -0.32, 1.06), Vector3(r.x * 0.4, r.y * 0.14, r.z * 0.18), beard, beard, 8, 4, true)
	# Straw hat: wide brim, low rounded crown, red band.
	var brim_r: float = look.num("player", "hat_brim_radius")
	var brim_t: float = look.num("player", "hat_brim_thickness")
	var crown_h: float = look.num("player", "hat_crown_height")
	var band_h: float = look.num("player", "hat_band_height")
	var brim_y: float = c.y + r.y * 0.5
	hb.add_cone(Vector3(0.0, brim_y, 0.0), brim_r, brim_r * 0.92, brim_t, hat_dark, hat, 16, true, true)
	hb.add_ellipsoid(Vector3(0.0, brim_y + 0.03, 0.0), Vector3(r.x, crown_h, r.x), hat_dark, hat, 14, 6, true)
	hb.add_cone(Vector3(0.0, brim_y + brim_t - 0.002, 0.0), r.x + 0.014, r.x + 0.006, band_h, band, band, 14)
	_add_part(_head, hb.build(), Vector3.ZERO)

	# Arms (pivot at the shoulder) and legs (pivot at the hip).
	var shoulder_x: float = tw * 0.5 + look.num("player", "arm_width") * 0.5 + 0.005
	_arm_left = _make_arm(look, Vector3(-shoulder_x, th + 0.04, 0.0), shirt, skin)
	_arm_right = _make_arm(look, Vector3(shoulder_x, th + 0.04, 0.0), shirt, skin)
	var leg_x: float = look.num("player", "leg_spacing")
	_leg_left = _make_leg(look, Vector3(-leg_x, _hip_height, 0.0), pants, boots)
	_leg_right = _make_leg(look, Vector3(leg_x, _hip_height, 0.0), pants, boots)


## A point on the head ellipsoid: [param unit] is in units of the radii from the center.
func _on_head(center: Vector3, radii: Vector3, ux: float, uy: float, uz: float) -> Vector3:
	return center + Vector3(ux * radii.x, uy * radii.y, uz * radii.z)


## A swinging arm: a pivot at [param pivot_pos] with a rolled sleeve, a bare forearm and a big hand.
func _make_arm(look: WorldLook, pivot_pos: Vector3, sleeve_color: Color, skin_color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	_torso.add_child(pivot)
	var w: float = look.num("player", "arm_width")
	var sleeve: float = look.num("player", "sleeve_length")
	var fore: float = look.num("player", "forearm_length")
	var hand_r: float = look.num("player", "hand_radius")
	var builder := MeshBuilder.new()
	builder.add_box(Vector3(0.0, -sleeve * 0.5, 0.0), Vector3(w, sleeve, w + 0.01), sleeve_color)
	builder.add_box(Vector3(0.0, -sleeve - fore * 0.5 + 0.01, 0.0), Vector3(w * 0.85, fore, w * 0.85), skin_color)
	builder.add_ellipsoid(Vector3(0.0, -sleeve - fore - hand_r * 0.5, 0.0), Vector3.ONE * hand_r, skin_color, skin_color, 8, 5, true)
	_add_part(pivot, builder.build(), Vector3.ZERO)
	return pivot


## A swinging leg: a pivot at [param pivot_pos] with short thick jeans and a big boot.
func _make_leg(look: WorldLook, pivot_pos: Vector3, pants_color: Color, boot_color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	add_child(pivot)
	var w: float = look.num("player", "leg_width")
	var d: float = look.num("player", "leg_depth")
	var boot_h: float = look.num("player", "boot_height")
	var boot_len: float = look.num("player", "boot_length")
	var pants_h: float = _hip_height - boot_h + 0.01
	var builder := MeshBuilder.new()
	builder.add_box(Vector3(0.0, -pants_h * 0.5, 0.0), Vector3(w, pants_h, d), pants_color)
	builder.add_box(Vector3(0.0, -_hip_height + boot_h * 0.5, 0.03), Vector3(w + 0.02, boot_h, boot_len), boot_color)
	_add_part(pivot, builder.build(), Vector3.ZERO)
	return pivot


func _add_part(parent: Node3D, part_mesh: ArrayMesh, pos: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = part_mesh
	node.material_override = _material
	node.position = pos
	parent.add_child(node)
