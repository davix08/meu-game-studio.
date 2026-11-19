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

## Fishing poses driven by FishingView; NONE is the plain walking animation.
enum Pose { NONE, CAST, WAIT, FIGHT, LAND }

const _POSE_KEYS: Array[String] = [
	"cast_back_degrees", "cast_forward_degrees", "cast_left_degrees", "cast_bend_degrees",
	"wait_arm_degrees", "wait_left_degrees", "wait_bend_degrees", "wait_sway_degrees", "wait_sway_freq",
	"fight_arm_degrees", "fight_left_degrees", "fight_lean_degrees", "fight_bend_degrees", "fight_shake_degrees", "fight_shake_freq",
	"land_arm_degrees", "land_left_degrees", "idle_bend_degrees", "pose_blend_speed",
]

## Current pose; the walking animation blends into it.
var pose: Pose = Pose.NONE
## Rod throw progress 0..1 used by [constant Pose.CAST].
var cast_progress: float = 0.0
## Color of the fish held up in [constant Pose.LAND].
var catch_color: Color = Color.WHITE:
	set(value):
		catch_color = value
		if _catch_material != null:
			_catch_material.albedo_color = value

var _pose_blend: float = 0.0
var _pose_time: float = 0.0
var _last_pose: Pose = Pose.WAIT
var _has_face_target: bool = false
var _face_yaw: float = 0.0
var _rod_material: StandardMaterial3D
var _catch_material: StandardMaterial3D
var _catch_mesh: MeshInstance3D
var _rod_tip_seg: Node3D
var _rod_tip: Node3D
var _pose_k: Dictionary[String, float] = {}
var _look_ref: WorldLook
## Color overrides of the clothes (Story 017): keys of the "colors" group, e.g. "hat", "vest".
var _outfit: Dictionary = {}
var _rod_color: Color = Color.WHITE
## Position of the right hand from the right shoulder pivot (where the rod is held).
var _hand_offset: Vector3 = Vector3.ZERO
## Clothing group -> its shader material, when the 3D model file is used.
var _model_materials: Dictionary = {}
## Clothing group -> brightness of the model's own color (keeps highlights when re-dressed).
var _model_luma: Dictionary = {}

## Model part name -> pivot ("head", "torso", "arm_l", "arm_r", "leg_l", "leg_r").
const _HEAD_PARTS: Array[String] = ["neck", "head", "left_ear", "right_ear", "hair_left", "hair_right", "L_eyebrow", "L_eye_white", "L_iris", "L_pupil", "R_eyebrow", "R_eye_white", "R_iris", "R_pupil", "full_beard", "beard_left_side", "beard_right_side", "nose", "mouth_hint"]
## "parts" (a model file made of named parts) or "split" (one textured mesh cut into parts).
var _model_kind: String = ""
## Split models already cut, by file path: shared by every fisherman (game and clothes viewer).
static var _split_cache: Dictionary = {}

## Clothing groups of the model that the clothes shop can recolor (Story 017), with the
## "colors" key of the outfit that dresses them.
const _OUTFIT_GROUPS: Dictionary = {
	"hat": ["hat_brim", "hat_brim_top", "hat_crown", "hat_front_highlight", "hat_brim_front_edge"],
	"hat_band": ["hat_crown_band"],
	"vest": ["red_shirt_torso", "shirt_front_detail", "left_sleeve", "right_sleeve", "left_sleeve_cuff", "right_sleeve_cuff"],
	"boots": ["L_boot", "L_boot_toe", "R_boot", "R_boot_toe"],
}


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
	_look_ref = look
	if not _build_from_split(look) and not _build_from_file(look):
		_build_model(look)
	_load_pose(look)
	_build_rod(look)
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
		_has_face_target = false
	elif _has_face_target:
		rotation.y = lerp_angle(rotation.y, _face_yaw, 1.0 - exp(-_turn_speed * delta))
	var moved: bool = ground_pos.distance_squared_to(before) > 0.0000001
	_animate(delta, moved, run)
	_apply_pose(delta)
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
## Builds only the model, for a display such as the clothes shop viewer (no grid, no walking).
func setup_display(look: WorldLook) -> void:
	_hip_height = look.num("player", "hip_height")
	_material = MeshBuilder.make_material(look.num("player", "roughness"))
	_look_ref = look
	if not _build_from_split(look) and not _build_from_file(look):
		_build_model(look)
	_load_pose(look)
	_build_rod(look)


## Dresses the fisherman (Story 017): [param colors] maps "colors" keys ("hat", "hat_dark",
## "hat_band", "vest", "vest_edge", "shirt", "boots") to new colors; the model is rebuilt.
func set_outfit(colors: Dictionary) -> void:
	_outfit = colors
	if _look_ref == null or _torso == null:
		return
	if not _model_materials.is_empty():
		if _model_kind == "split":
			_dress_split()
		else:
			_dress_model()
		return
	for node: Node3D in [_torso, _leg_left, _leg_right]:
		node.free()
	_catch_mesh.free()
	_build_model(_look_ref)
	_build_rod(_look_ref)
	_rod_material.albedo_color = _rod_color


## Builds the fisherman from the 3D model file (assets/characters/, path in world_look.json):
## every named part goes under the pivot that animates it (head, torso, arms, legs), turned from
## the file's Z-up axes to Godot's and scaled to the game height, with the pixel texture shader.
## Returns false (and the code-built model is used) when the file is missing or not imported.
func _build_from_file(look: WorldLook) -> bool:
	var path: String = look.text("player", "model_path")
	if look.text("player", "model_kind") != "parts" or path == "" or not ResourceLoader.exists(path):
		return false
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return false
	var source: Node = scene.instantiate()
	var meshes: Dictionary = {}
	for node: Node in source.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node
		if mi.mesh != null:
			meshes[String(mi.name)] = mi.mesh
	source.free()
	if meshes.is_empty():
		return false
	var s: float = look.num("player", "model_height") / look.num("player", "model_units_tall")
	# File axes: x right, y back (the face looks to -y), z up. Godot: x right, y up, z forward.
	var to_game := Basis.from_scale(Vector3.ONE * s) * Basis(Vector3.RIGHT, -PI * 0.5)
	var hip := Vector3(0.0, look.num("player", "model_hip_z"), 0.0) * s
	var shoulder_x: float = look.num("player", "model_shoulder_x") * s
	var shoulder_y: float = look.num("player", "model_shoulder_z") * s
	var neck := Vector3(0.0, look.num("player", "model_neck_z"), 0.0) * s
	var leg_x: float = look.num("player", "model_hip_x") * s
	_hip_height = hip.y
	_hand_offset = Vector3(look.num("player", "model_hand_x") * s - shoulder_x, look.num("player", "model_hand_z") * s - shoulder_y, -look.num("player", "model_hand_y") * s)
	_torso = Node3D.new()
	_torso.position = hip
	add_child(_torso)
	_head = Node3D.new()
	_head.position = neck - hip
	_torso.add_child(_head)
	_arm_left = Node3D.new()
	_arm_left.position = Vector3(-shoulder_x, shoulder_y, 0.0) - hip
	_torso.add_child(_arm_left)
	_arm_right = Node3D.new()
	_arm_right.position = Vector3(shoulder_x, shoulder_y, 0.0) - hip
	_torso.add_child(_arm_right)
	_leg_left = Node3D.new()
	_leg_left.position = Vector3(-leg_x, hip.y, 0.0)
	add_child(_leg_left)
	_leg_right = Node3D.new()
	_leg_right.position = Vector3(leg_x, hip.y, 0.0)
	add_child(_leg_right)
	_model_materials.clear()
	var plain: ShaderMaterial = _model_material(look, "")
	for part_name: String in meshes:
		var pivot: Node3D = _torso
		var origin: Vector3 = hip
		if _HEAD_PARTS.has(part_name) or part_name.begins_with("hat_"):
			pivot = _head
			origin = neck
		elif part_name.begins_with("left_") and part_name != "left_overall_strap" and part_name != "left_gold_buckle":
			pivot = _arm_left
			origin = Vector3(-shoulder_x, shoulder_y, 0.0)
		elif part_name.begins_with("right_") and part_name != "right_overall_strap" and part_name != "right_gold_buckle":
			pivot = _arm_right
			origin = Vector3(shoulder_x, shoulder_y, 0.0)
		elif part_name.begins_with("L_"):
			pivot = _leg_left
			origin = _leg_left.position
		elif part_name.begins_with("R_"):
			pivot = _leg_right
			origin = _leg_right.position
		var node := MeshInstance3D.new()
		node.mesh = meshes[part_name]
		node.transform = Transform3D(to_game, -origin)
		node.material_override = plain
		for group: String in _OUTFIT_GROUPS:
			if (_OUTFIT_GROUPS[group] as Array).has(part_name):
				if not _model_materials.has(group):
					_model_materials[group] = _model_material(look, group)
					_model_luma[group] = _mesh_luma(node.mesh)
				node.material_override = _model_materials[group]
		pivot.add_child(node)
	_model_kind = "parts"
	_dress_model()
	return true


## Builds the fisherman from ONE textured mesh (assets/characters/fazendeiro.glb, Y-up, facing
## +z): the mesh is cut once into hat, head, torso, arms, legs and boots by the heights and widths
## in world_look.json ("split_*"), each piece goes under the pivot that animates it, and every
## piece keeps the model's own texture. Returns false when the file is missing or unreadable.
func _build_from_split(look: WorldLook) -> bool:
	if look.text("player", "model_kind") != "split":
		return false
	var path: String = look.text("player", "split_model_path")
	if not ResourceLoader.exists(path):
		return false
	if not _split_cache.has(path):
		_split_cache[path] = _cut_model(look, path)
	var cut: Dictionary = _split_cache[path]
	if cut.is_empty():
		return false
	var parts: Dictionary = cut["parts"]
	var texture: Texture2D = cut["texture"]
	var s: float = look.num("player", "model_height") / look.num("player", "split_units_tall")
	var floor_y: float = look.num("player", "split_floor")
	var hip := Vector3(0.0, look.num("player", "split_hip") - floor_y, 0.0) * s
	var neck := Vector3(0.0, look.num("player", "split_neck") - floor_y, 0.0) * s
	var shoulder := Vector3(look.num("player", "split_shoulder_x"), look.num("player", "split_shoulder_y") - floor_y, 0.0) * s
	var leg_x: float = look.num("player", "split_leg_x") * s
	var hand := Vector3(look.num("player", "split_hand_x"), look.num("player", "split_hand_y") - floor_y, look.num("player", "split_hand_z")) * s
	_hip_height = hip.y
	_hand_offset = hand - shoulder
	_torso = Node3D.new()
	_torso.position = hip
	add_child(_torso)
	_head = Node3D.new()
	_head.position = neck - hip
	_torso.add_child(_head)
	_arm_left = Node3D.new()
	_arm_left.position = Vector3(-shoulder.x, shoulder.y, 0.0) - hip
	_torso.add_child(_arm_left)
	_arm_right = Node3D.new()
	_arm_right.position = shoulder - hip
	_torso.add_child(_arm_right)
	_leg_left = Node3D.new()
	_leg_left.position = Vector3(-leg_x, hip.y, 0.0)
	add_child(_leg_left)
	_leg_right = Node3D.new()
	_leg_right.position = Vector3(leg_x, hip.y, 0.0)
	add_child(_leg_right)
	_model_materials.clear()
	for group: String in ["plain", "hat", "vest", "boots"]:
		_model_materials[group] = _textured_material(look, texture)
	var pivots: Dictionary = {
		"hat": [_head, neck, "hat"], "head": [_head, neck, "plain"], "torso": [_torso, hip, "vest"],
		"arm_l": [_arm_left, Vector3(-shoulder.x, shoulder.y, 0.0), "vest"], "arm_r": [_arm_right, shoulder, "vest"],
		"leg_l": [_leg_left, _leg_left.position, "plain"], "leg_r": [_leg_right, _leg_right.position, "plain"],
		"boot_l": [_leg_left, _leg_left.position, "boots"], "boot_r": [_leg_right, _leg_right.position, "boots"],
	}
	var to_game := Basis.from_scale(Vector3.ONE * s)
	var lift := Vector3(0.0, -floor_y * s, 0.0)
	for part_name: String in parts:
		var where: Array = pivots[part_name]
		var node := MeshInstance3D.new()
		node.mesh = parts[part_name]
		node.transform = Transform3D(to_game, lift - (where[1] as Vector3))
		node.material_override = _model_materials[str(where[2])]
		(where[0] as Node3D).add_child(node)
	_model_kind = "split"
	_dress_split()
	return true


## Cuts the mesh of [param path] into the parts named in [method _build_from_split]; each
## triangle goes to the part of its center. Returns {"parts": {name: ArrayMesh}, "texture"}.
func _cut_model(look: WorldLook, path: String) -> Dictionary:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return {}
	var source: Node = scene.instantiate()
	var found: Array[Node] = source.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		source.free()
		return {}
	var mesh_instance: MeshInstance3D = found[0]
	var mesh: Mesh = mesh_instance.mesh
	var texture: Texture2D = null
	var material: Material = mesh_instance.get_active_material(0)
	if material is BaseMaterial3D:
		texture = (material as BaseMaterial3D).albedo_texture
	var arrays: Array = mesh.surface_get_arrays(0)
	source.free()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		indices.resize(verts.size())
		for i in verts.size():
			indices[i] = i
	var hat_y: float = look.num("player", "split_hat")
	var neck_y: float = look.num("player", "split_neck")
	var hip_y: float = look.num("player", "split_hip")
	var boots_y: float = look.num("player", "split_boots")
	var arm_x: float = look.num("player", "split_arm_x")
	var names: Array[String] = ["hat", "head", "torso", "arm_l", "arm_r", "leg_l", "leg_r", "boot_l", "boot_r"]
	var tris: Dictionary = {}
	for part_name: String in names:
		tris[part_name] = PackedInt32Array()
	for t in range(0, indices.size() - 2, 3):
		var c: Vector3 = (verts[indices[t]] + verts[indices[t + 1]] + verts[indices[t + 2]]) / 3.0
		var part_name: String = "torso"
		if c.y > hat_y:
			part_name = "hat"
		elif c.y > neck_y:
			part_name = "head"
		elif c.y < boots_y:
			part_name = "boot_l" if c.x < 0.0 else "boot_r"
		elif c.y < hip_y:
			part_name = "leg_l" if c.x < 0.0 else "leg_r"
		elif absf(c.x) > arm_x:
			part_name = "arm_l" if c.x < 0.0 else "arm_r"
		var list: PackedInt32Array = tris[part_name]
		list.append(t)
		tris[part_name] = list
	var parts: Dictionary = {}
	var remap := PackedInt32Array()
	remap.resize(verts.size())
	for part_name: String in names:
		var list: PackedInt32Array = tris[part_name]
		if list.is_empty():
			continue
		remap.fill(-1)
		var pv := PackedVector3Array()
		var pn := PackedVector3Array()
		var pu := PackedVector2Array()
		var pi := PackedInt32Array()
		for t: int in list:
			for k in 3:
				var v: int = indices[t + k]
				if remap[v] < 0:
					remap[v] = pv.size()
					pv.append(verts[v])
					if not normals.is_empty():
						pn.append(normals[v])
					if not uvs.is_empty():
						pu.append(uvs[v])
				pi.append(remap[v])
		var out: Array = []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = pv
		if not pn.is_empty():
			out[Mesh.ARRAY_NORMAL] = pn
		if not pu.is_empty():
			out[Mesh.ARRAY_TEX_UV] = pu
		out[Mesh.ARRAY_INDEX] = pi
		var part_mesh := ArrayMesh.new()
		part_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
		parts[part_name] = part_mesh
	return {"parts": parts, "texture": texture}


func _textured_material(look: WorldLook, texture: Texture2D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(look.text("player", "split_shader")) as Shader
	material.set_shader_parameter("albedo_tex", texture)
	material.set_shader_parameter("roughness", look.num("player", "roughness"))
	material.set_shader_parameter("main_ref", look.num("player", "split_main_ref"))
	material.set_shader_parameter("red_ref", look.num("player", "split_red_ref"))
	return material


## Clothes on the textured model: the hat takes the hat color (band = trim), the shirt's red
## pixels take the shirt color, the boots take the boots color. Default pieces keep the texture.
func _dress_split() -> void:
	var hat: ShaderMaterial = _model_materials["hat"]
	var custom_hat: bool = _outfit.get("_custom_hat", false)
	hat.set_shader_parameter("use_main", 1.0 if custom_hat else 0.0)
	hat.set_shader_parameter("use_red", 1.0 if custom_hat else 0.0)
	if custom_hat:
		hat.set_shader_parameter("main_color", _outfit["hat"])
		hat.set_shader_parameter("red_color", _outfit["hat_band"])
	var vest: ShaderMaterial = _model_materials["vest"]
	var custom_vest: bool = _outfit.get("_custom_vest", false)
	vest.set_shader_parameter("use_red", 1.0 if custom_vest else 0.0)
	if custom_vest:
		vest.set_shader_parameter("red_color", _outfit["vest"])
	var boots: ShaderMaterial = _model_materials["boots"]
	var custom_boots: bool = _outfit.get("_custom_boots", false)
	boots.set_shader_parameter("use_main", 1.0 if custom_boots else 0.0)
	if custom_boots:
		boots.set_shader_parameter("main_color", _outfit["boots"])


func _model_material(look: WorldLook, _group: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(look.text("player", "model_shader")) as Shader
	material.set_shader_parameter("pixel_tex", load(look.text("player", "model_texture")) as Texture2D)
	material.set_shader_parameter("texel_scale", look.num("player", "model_texel_scale"))
	material.set_shader_parameter("detail", look.num("player", "model_texture_detail"))
	material.set_shader_parameter("colors_srgb", look.num("player", "model_colors_srgb"))
	return material


## Average brightness of a part's vertex colors.
func _mesh_luma(mesh: Mesh) -> float:
	var arrays: Array = mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if colors.is_empty():
		return 0.5
	var total: float = 0.0
	for c: Color in colors:
		total += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	return total / float(colors.size())


## Applies the outfit to the model's clothing groups: a piece that is not the default one
## replaces the group color; the default outfit keeps the model's own colors.
func _dress_model() -> void:
	for group: String in _model_materials:
		var material: ShaderMaterial = _model_materials[group]
		var dressed: bool = _outfit.has(group) and _outfit.get("_custom_" + group, false)
		material.set_shader_parameter("use_override", 1.0 if dressed else 0.0)
		if dressed:
			material.set_shader_parameter("override_color", _outfit[group])
			material.set_shader_parameter("luma_ref", _model_luma[group])


func _oc(look: WorldLook, key: String) -> Color:
	return _outfit[key] if _outfit.has(key) else look.color("colors", key)


func _build_model(look: WorldLook) -> void:
	var skin: Color = look.color("colors", "skin")
	var shirt: Color = _oc(look, "shirt")
	var vest: Color = _oc(look, "vest")
	var vest_edge: Color = _oc(look, "vest_edge")
	var belt: Color = look.color("colors", "belt")
	var buckle: Color = look.color("colors", "buckle")
	var hat: Color = _oc(look, "hat")
	var hat_dark: Color = _oc(look, "hat_dark")
	var band: Color = _oc(look, "hat_band")
	var pack: Color = look.color("colors", "pack")
	var pack_dark: Color = look.color("colors", "pack_dark")
	var pants: Color = look.color("colors", "pants")
	var boots: Color = _oc(look, "boots")
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


## Position of the rod tip in world space (where the fishing line starts).
func get_rod_tip() -> Vector3:
	return _rod_tip.global_position


## Colors the held rod (the equipped rod's color).
func set_rod_color(color: Color) -> void:
	_rod_color = color
	_rod_material.albedo_color = color


## Moves the fisherman to [param pos] (blocks x, z) at once (new day, loading a save).
func teleport(pos: Vector2) -> void:
	ground_pos = pos
	position = Vector3(pos.x, _terrain.ground_height_at(pos.x, pos.y), pos.y)


## Turns the fisherman toward [param world_pos] while standing still (walking overrides it).
func face_toward(world_pos: Vector3) -> void:
	_face_yaw = atan2(world_pos.x - position.x, world_pos.z - position.z)
	_has_face_target = true


func _load_pose(look: WorldLook) -> void:
	for key: String in _POSE_KEYS:
		var value: float = look.num("fishing", key)
		_pose_k[key] = deg_to_rad(value) if key.ends_with("_degrees") else value


## The rod in the right hand (two segments so the tip can bend) and the hidden fish prop.
func _build_rod(look: WorldLook) -> void:
	var length: float = look.num("fishing", "rod_length")
	var base_len: float = length * look.num("fishing", "rod_base_fraction")
	var tip_len: float = length - base_len
	var thick: float = look.num("fishing", "rod_thickness")
	_rod_material = StandardMaterial3D.new()
	_rod_material.roughness = look.num("player", "roughness")
	var holder := Node3D.new()
	holder.position = _hand_offset if _hand_offset != Vector3.ZERO else Vector3(0.0, -(look.num("player", "sleeve_length") + look.num("player", "forearm_length")), 0.0)
	holder.rotation.x = PI * 0.5
	_arm_right.add_child(holder)
	_add_box(holder, Vector3(thick, base_len, thick), Vector3(0.0, base_len * 0.5, 0.0))
	_rod_tip_seg = Node3D.new()
	_rod_tip_seg.position = Vector3(0.0, base_len, 0.0)
	holder.add_child(_rod_tip_seg)
	_add_box(_rod_tip_seg, Vector3(thick * 0.6, tip_len, thick * 0.6), Vector3(0.0, tip_len * 0.5, 0.0))
	_rod_tip = Node3D.new()
	_rod_tip.position = Vector3(0.0, tip_len, 0.0)
	_rod_tip_seg.add_child(_rod_tip)
	_catch_material = StandardMaterial3D.new()
	_catch_material.albedo_color = catch_color
	_catch_mesh = MeshInstance3D.new()
	_catch_mesh.mesh = SphereMesh.new()
	_catch_mesh.material_override = _catch_material
	_catch_mesh.scale = Vector3(look.num("fishing", "catch_length"), look.num("fishing", "catch_thickness"), look.num("fishing", "catch_thickness") * 0.6)
	_catch_mesh.position = Vector3(0.0, look.num("fishing", "catch_height"), look.num("fishing", "catch_forward"))
	_catch_mesh.visible = false
	add_child(_catch_mesh)


func _add_box(parent: Node3D, box_size: Vector3, pos: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = box_size
	var node := MeshInstance3D.new()
	node.mesh = box
	node.material_override = _rod_material
	node.position = pos
	parent.add_child(node)


## Blends the arms, torso lean and rod bend toward the active fishing pose (after the walk animation).
func _apply_pose(delta: float) -> void:
	_pose_time += delta
	_pose_blend = move_toward(_pose_blend, 0.0 if pose == Pose.NONE else 1.0, delta * _pose_k["pose_blend_speed"])
	if pose != Pose.NONE:
		_last_pose = pose
	var arm_r: float = 0.0
	var arm_l: float = 0.0
	var lean: float = 0.0
	var roll: float = 0.0
	var bend: float = _pose_k["idle_bend_degrees"]
	match _last_pose:
		Pose.CAST:
			var k: float = smoothstep(0.0, 1.0, cast_progress)
			arm_r = lerpf(_pose_k["cast_back_degrees"], _pose_k["cast_forward_degrees"], k)
			arm_l = _pose_k["cast_left_degrees"]
			bend = lerpf(-_pose_k["cast_bend_degrees"], _pose_k["cast_bend_degrees"], k)
		Pose.WAIT:
			arm_r = _pose_k["wait_arm_degrees"] + sin(_pose_time * _pose_k["wait_sway_freq"]) * _pose_k["wait_sway_degrees"]
			arm_l = _pose_k["wait_left_degrees"]
			bend = _pose_k["wait_bend_degrees"]
		Pose.FIGHT:
			var shake: float = sin(_pose_time * _pose_k["fight_shake_freq"]) * _pose_k["fight_shake_degrees"]
			arm_r = _pose_k["fight_arm_degrees"] + shake
			arm_l = _pose_k["fight_left_degrees"] - shake
			lean = _pose_k["fight_lean_degrees"]
			roll = shake
			bend = _pose_k["fight_bend_degrees"] + shake
		Pose.LAND:
			arm_r = _pose_k["land_arm_degrees"]
			arm_l = _pose_k["land_left_degrees"]
	_arm_right.rotation.x = lerpf(_arm_right.rotation.x, arm_r, _pose_blend)
	_arm_left.rotation.x = lerpf(_arm_left.rotation.x, arm_l, _pose_blend)
	_torso.rotation.x = lerpf(_torso.rotation.x, lean, _pose_blend)
	_torso.rotation.z = lerpf(0.0, roll, _pose_blend)
	_rod_tip_seg.rotation.x = lerpf(_pose_k["idle_bend_degrees"], bend, _pose_blend)
	_catch_mesh.visible = pose == Pose.LAND
