class_name DiveView
extends Node3D
## The underwater scene of a dive (design/gdd/diving.md), built in code far below the
## lake: sandy floor, rocks and seaweed, the diver, the fish and the harpoon shot, under
## a blue fog. Its own camera (same isometric angles as the lake's) follows the diver.
## Also places the dive buoy on the lake surface. Shows the [Dive] it is given; owns no rules.
##
## Usage:
## [codeblock]
## view.setup(look, data, terrain)
## view.begin(dive)   # switches to the underwater camera
## view.sync(delta)   # every frame while diving
## view.finish()      # back to the lake camera (call make_current on it)
## [/codeblock]

## Where the arena's (0, 0) sits in the world: far from the lake so neither sees the other.
const ORIGIN: Vector3 = Vector3(400.0, -60.0, 400.0)
const SHOT_SECONDS: float = 0.18

var _look: WorldLook
var _data: GameData
var _dive: Dive
var _camera: Camera3D
var _offset: Vector3 = Vector3.ZERO
var _diver: Node3D
var _fish_nodes: Dictionary = {} # Dive.DiveFish -> Node3D
var _material: StandardMaterial3D
var _shot: MeshInstance3D
var _shot_left: float = 0.0
var _shot_from: Vector3 = Vector3.ZERO
var _shot_to: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _bubbles: CPUParticles3D


## Builds the arena, the diver, the camera and the buoy at the dive spot on [param terrain]'s lake.
func setup(look: WorldLook, data: GameData, water_y: float) -> void:
	_look = look
	_data = data
	_material = MeshBuilder.make_material(0.85)
	var arena := Vector2(float(data.dive["arena"]["w"]), float(data.dive["arena"]["h"]))
	_build_floor(arena)
	_diver = _build_diver()
	add_child(_diver)
	_bubbles = CPUParticles3D.new()
	_bubbles.amount = 14
	_bubbles.lifetime = 1.6
	_bubbles.direction = Vector3.UP
	_bubbles.spread = 12.0
	_bubbles.gravity = Vector3(0.0, 1.2, 0.0)
	_bubbles.initial_velocity_min = 0.4
	_bubbles.initial_velocity_max = 0.9
	var bubble := SphereMesh.new()
	bubble.radius = 0.05
	bubble.height = 0.1
	_bubbles.mesh = bubble
	var bubble_mat := StandardMaterial3D.new()
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubble_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.8)
	bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bubbles.material_override = bubble_mat
	_bubbles.position = Vector3(0.0, 0.9, 0.0)
	_diver.add_child(_bubbles)
	_shot = MeshInstance3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.05, 0.05, 1.0)
	_shot.mesh = shaft
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.85, 0.88, 0.92)
	steel.metallic = 0.6
	_shot.material_override = steel
	_shot.visible = false
	add_child(_shot)
	_camera = Camera3D.new()
	_camera.rotation = Vector3(-deg_to_rad(look.num("camera", "pitch_degrees")), deg_to_rad(look.num("camera", "yaw_degrees")), 0.0)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = look.num("camera", "size") * 0.55
	_camera.near = look.num("camera", "near")
	_camera.far = look.num("camera", "far")
	_offset = _camera.basis * Vector3(0.0, 0.0, look.num("camera", "distance"))
	_camera.environment = _underwater_environment()
	add_child(_camera)
	_build_buoy(Vector2(float(data.dive["spot"]["buoy_x"]), float(data.dive["spot"]["buoy_y"])), water_y)
	visible = false
	set_process(false)


## Shows [param dive] and switches to the underwater camera.
func begin(dive: Dive) -> void:
	_dive = dive
	for n: Node3D in _fish_nodes.values():
		n.queue_free()
	_fish_nodes.clear()
	for f: Dive.DiveFish in dive.fish:
		var node: Node3D = _build_fish(f.fish)
		add_child(node)
		_fish_nodes[f] = node
	dive.speared.connect(_on_speared)
	dive.fired.connect(_on_fired)
	visible = true
	set_process(true)
	sync(0.0)
	_camera.position = _world(dive.diver) + _offset
	_camera.make_current()


## Hides the scene; the caller makes the lake camera current again.
func finish() -> void:
	if _dive != null:
		_dive.speared.disconnect(_on_speared)
		_dive.fired.disconnect(_on_fired)
	_dive = null
	visible = false
	set_process(false)


## Places the diver and the fish from the dive's state.
func sync(delta: float) -> void:
	if _dive == null:
		return
	_time += delta
	_diver.position = _world(_dive.diver) + Vector3(0.0, 0.9 + sin(_time * 2.0) * 0.06, 0.0)
	_diver.rotation.y = atan2(_dive.facing.x, _dive.facing.y)
	for f: Dive.DiveFish in _fish_nodes:
		var node: Node3D = _fish_nodes[f]
		node.position = _world(f.pos) + Vector3(0.0, 0.8 + sin(_time * 1.7 + f.pos.x) * 0.15, 0.0)
		node.rotation.y = atan2(f.vel.x, f.vel.y)
	var focus: Vector3 = _world(_dive.diver)
	_camera.position = _camera.position.lerp(focus + _offset, 1.0 - exp(-6.0 * delta)) if delta > 0.0 else focus + _offset


func _process(delta: float) -> void:
	if _shot_left > 0.0:
		_shot_left -= delta
		var t: float = 1.0 - _shot_left / SHOT_SECONDS
		var tip: Vector3 = _shot_from.lerp(_shot_to, t)
		_shot.look_at_from_position((_shot_from + tip) * 0.5, tip + (tip - _shot_from) * 0.01 + Vector3(0.0001, 0.0, 0.0))
		_shot.scale = Vector3(1.0, 1.0, maxf(0.05, _shot_from.distance_to(tip)))
		_shot.visible = _shot_left > 0.0


func _on_fired(from: Vector2, dir: Vector2, _hit: bool) -> void:
	_shot_from = _world(from) + Vector3(0.0, 0.9, 0.0)
	_shot_to = _world(from + dir * float(_data.dive["harpoon_range"])) + Vector3(0.0, 0.9, 0.0)
	_shot_left = SHOT_SECONDS
	_shot.visible = true


func _on_speared(f: Dive.DiveFish) -> void:
	if _fish_nodes.has(f):
		var node: Node3D = _fish_nodes[f]
		_fish_nodes.erase(f)
		var tween: Tween = create_tween()
		tween.tween_property(node, "scale", Vector3.ONE * 0.01, 0.25)
		tween.tween_callback(node.queue_free)


func _world(p: Vector2) -> Vector3:
	return ORIGIN + Vector3(p.x, 0.0, p.y)


func _underwater_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.22, 0.32)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.7, 0.8)
	env.ambient_light_energy = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.38, 0.5)
	env.fog_density = 0.035
	return env


func _build_floor(arena: Vector2) -> void:
	var mb := MeshBuilder.new()
	var center := Vector3(arena.x * 0.5, -0.1, arena.y * 0.5)
	mb.add_box(center, Vector3(arena.x + 60.0, 0.2, arena.y + 60.0), Color(0.78, 0.7, 0.5))
	# Rocks on the rim and seaweed tufts inside, placed by a fixed hash (decoration only).
	for i: int in 26:
		var a: float = TAU * float(i) / 26.0
		var r := Vector3(center.x + cos(a) * (arena.x * 0.5 + 1.2), 0.0, center.z + sin(a) * (arena.y * 0.5 + 1.2))
		var s: float = 0.6 + WorldGrid.hash2(i, 3) * 0.9
		mb.add_ellipsoid(r + Vector3(0.0, s * 0.4, 0.0), Vector3(s, s * 0.7, s * 0.8), Color(0.38, 0.4, 0.42), Color(0.52, 0.55, 0.56), 7, 4, false)
	for i: int in 34:
		var p := Vector3(WorldGrid.hash2(i, 11) * arena.x, 0.0, WorldGrid.hash2(i, 17) * arena.y)
		var h: float = 0.8 + WorldGrid.hash2(i, 23) * 1.4
		var green := Color(0.2, 0.55 + WorldGrid.hash2(i, 29) * 0.25, 0.32)
		for k: int in 3:
			mb.add_cone(p + Vector3(float(k) * 0.12 - 0.12, 0.0, 0.0), 0.08, 0.0, h - float(k) * 0.2, green.darkened(0.3), green.lightened(0.2), 4)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = mb.build()
	floor_node.material_override = _material
	floor_node.position = ORIGIN
	add_child(floor_node)


func _build_diver() -> Node3D:
	var mb := MeshBuilder.new()
	var suit := Color(0.12, 0.2, 0.32)
	mb.add_ellipsoid(Vector3(0.0, 0.0, 0.0), Vector3(0.26, 0.22, 0.62), suit, suit.lightened(0.2), 10, 6, true)
	mb.add_ellipsoid(Vector3(0.0, 0.05, 0.62), Vector3(0.2, 0.2, 0.2), Color(0.93, 0.76, 0.6), Color(0.98, 0.84, 0.7), 8, 5, true)
	mb.add_box(Vector3(0.0, 0.08, 0.78), Vector3(0.26, 0.12, 0.06), Color(0.55, 0.85, 1.0))
	mb.add_cone(Vector3(0.0, 0.22, -0.3), 0.11, 0.11, 0.6, Color(0.95, 0.75, 0.15), Color(1.0, 0.85, 0.3), 8, true, true)
	mb.add_box(Vector3(-0.12, -0.02, -0.8), Vector3(0.14, 0.04, 0.34), Color(0.95, 0.5, 0.15))
	mb.add_box(Vector3(0.12, -0.02, -0.8), Vector3(0.14, 0.04, 0.34), Color(0.95, 0.5, 0.15))
	mb.add_box(Vector3(0.22, 0.0, 0.7), Vector3(0.04, 0.04, 0.9), Color(0.6, 0.62, 0.66))
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = _material
	var root := Node3D.new()
	node.scale = Vector3.ONE * 1.8
	root.add_child(node)
	return root


func _build_fish(c: GameState.Catch) -> Node3D:
	var color: Color = FishIcon.body_color(c.id)
	var length: float = clampf(c.length / 40.0, 0.7, 2.4)
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3.ZERO, Vector3(length * 0.16, length * 0.22, length * 0.5), color.darkened(0.2), color.lightened(0.15), 8, 5, true)
	mb.add_triangle(Vector3(0.0, 0.0, -length * 0.42), Vector3(0.0, length * 0.2, -length * 0.75), Vector3(0.0, -length * 0.2, -length * 0.75), color.darkened(0.3))
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = _material
	var root := Node3D.new()
	root.add_child(node)
	return root


func _build_buoy(at: Vector2, water_y: float) -> void:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(0.0, 0.12, 0.0), Vector3(0.28, 0.24, 0.28), Color(0.85, 0.15, 0.12), Color(0.95, 0.3, 0.25), 10, 6, true)
	mb.add_cone(Vector3(0.0, 0.25, 0.0), 0.05, 0.05, 0.5, Color.WHITE, Color.WHITE, 6, true)
	mb.add_box(Vector3(0.12, 0.65, 0.0), Vector3(0.22, 0.14, 0.02), Color(0.95, 0.2, 0.15))
	var buoy := MeshInstance3D.new()
	buoy.mesh = mb.build()
	buoy.material_override = _material
	buoy.position = Vector3(at.x, water_y, at.y)
	get_parent().add_child.call_deferred(buoy)
