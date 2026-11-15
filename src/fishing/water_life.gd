class_name WaterLife
extends Node3D
## Fish shadows swimming under the lake surface and bubbling fish schools (2D world.js
## spawnWaterLife / updateWaterLife / scareShadows).
##
## Logic positions are in 2D pixel units (16 px = 1 block = 1 m), like [WorldQuery]. The schools
## answer [method in_school] for [LakeWorldQuery]. Randomness comes only from the injected
## [RandomSource]. [method step] runs on the fixed step; drawing runs in _process.
##
## Story 003 (design/game-brief.md, MVP feature 10). Counts, radius and move time come from
## config.json (fish_shadows, school_count, school_move_seconds, spot_radius); looks and ambient
## swim numbers come from the "fishing" group of world_look.json.
##
## Usage:
## [codeblock]
## var life := WaterLife.new()
## add_child(life)
## life.setup(look, data, grid, rng, -0.1)
## life.step(1.0 / 60.0)  # every fixed step
## [/codeblock]

const _KEYS: Array[String] = [
	"shadow_length", "shadow_width", "shadow_depth", "shadow_speed_min", "shadow_speed_span", "shadow_flee_speed",
	"shadow_turn_min", "shadow_turn_span", "shadow_turn_angle", "shadow_ahead", "shadow_size_min", "shadow_size_span",
	"shadow_scare_radius", "shadow_flee_time", "school_ring_width", "school_ring_height", "school_ring_flatten",
	"school_pulse_freq", "school_pulse_amount", "school_bubble_amount", "school_bubble_rise", "school_bubble_size",
	"school_bubble_life", "school_bubble_area",
]


## One swimming fish shadow (position in 2D pixels).
class Shadow:
	extends RefCounted
	var pos: Vector2 = Vector2.ZERO
	var angle: float = 0.0
	var speed: float = 0.0
	var turn: float = 0.0
	var size: float = 1.0
	var flee: float = 0.0


## One bubbling school (position in 2D pixels).
class School:
	extends RefCounted
	var pos: Vector2 = Vector2.ZERO
	var life: float = 0.0


var _data: GameData
var _grid: WorldGrid
var _rng: RandomSource
var _water_y: float = 0.0
var _k: Dictionary[String, float] = {}
var _water_cells: Array[Vector2i] = []
var _deep_cells: Array[Vector2i] = []
var _shadows: Array[Shadow] = []
var _schools: Array[School] = []
var _multi: MultiMesh
var _rings: Array[MeshInstance3D] = []
var _ring_materials: Array[StandardMaterial3D] = []
var _bubbles: Array[CPUParticles3D] = []
var _ring_color: Color = Color.WHITE
var _radius_px: float = 0.0
var _time: float = 0.0


## Reads the tuning, collects the water cells, spawns shadows and schools and builds the visuals.
## [param water_y] is the water surface height in meters.
func setup(look: WorldLook, data: GameData, grid: WorldGrid, rng: RandomSource, water_y: float) -> void:
	_data = data
	_grid = grid
	_rng = rng
	_water_y = water_y
	_radius_px = data.tune("spot_radius")
	for key: String in _KEYS:
		_k[key] = look.num("fishing", key)
	for cy: int in range(WorldGrid.HEIGHT):
		for cx: int in range(WorldGrid.WIDTH):
			if grid.is_water(cx, cy):
				_water_cells.append(Vector2i(cx, cy))
				if grid.is_deep(cx, cy):
					_deep_cells.append(Vector2i(cx, cy))
	for i: int in range(int(data.tune("fish_shadows"))):
		var shadow := Shadow.new()
		shadow.pos = _cell_center(_pick(_water_cells))
		shadow.angle = rng.next_float() * TAU
		shadow.speed = _k["shadow_speed_min"] + rng.next_float() * _k["shadow_speed_span"]
		shadow.turn = rng.next_float() * _k["shadow_turn_span"]
		shadow.size = _k["shadow_size_min"] + rng.next_float() * _k["shadow_size_span"]
		_shadows.append(shadow)
	for i: int in range(int(data.tune("school_count"))):
		_schools.append(_new_school())
	_build_shadow_visual(look)
	_build_school_visual(look)


## True when [param pos] (2D pixel units, x and z) is inside a school's spot radius.
func in_school(pos: Vector3) -> bool:
	var flat := Vector2(pos.x, pos.z)
	for school: School in _schools:
		if flat.distance_to(school.pos) < _radius_px:
			return true
	return false


## Makes the shadows near [param pos] (2D pixel units) flee from it for a short while.
func scare(pos: Vector3) -> void:
	var flat := Vector2(pos.x, pos.z)
	for shadow: Shadow in _shadows:
		if shadow.pos.distance_to(flat) < _k["shadow_scare_radius"]:
			shadow.flee = _k["shadow_flee_time"]
			shadow.angle = (shadow.pos - flat).angle()


## One fixed step: shadows swim (turn at the shore) and schools move to a new deep spot when their time ends.
func step(dt: float) -> void:
	for shadow: Shadow in _shadows:
		shadow.turn -= dt
		if shadow.turn <= 0.0:
			shadow.angle += (_rng.next_float() - 0.5) * _k["shadow_turn_angle"]
			shadow.turn = _k["shadow_turn_min"] + _rng.next_float() * _k["shadow_turn_span"]
			shadow.speed = _k["shadow_speed_min"] + _rng.next_float() * _k["shadow_speed_span"]
		if shadow.flee > 0.0:
			shadow.flee -= dt
		var speed: float = _k["shadow_flee_speed"] if shadow.flee > 0.0 else shadow.speed
		var heading: Vector2 = Vector2.from_angle(shadow.angle)
		var next: Vector2 = shadow.pos + heading * speed * dt
		if _is_water_px(next + heading * _k["shadow_ahead"]):
			shadow.pos = next
		else:
			shadow.angle += PI * (0.6 + _rng.next_float() * 0.8)
	for i: int in range(_schools.size()):
		_schools[i].life -= dt
		if _schools[i].life <= 0.0:
			_schools[i] = _new_school()


func _process(delta: float) -> void:
	_time += delta
	var scale_px: float = 1.0 / WorldGrid.PIXELS_PER_BLOCK
	for i: int in range(_shadows.size()):
		var shadow: Shadow = _shadows[i]
		var orient: Basis = Basis(Vector3.UP, -shadow.angle) * Basis.from_scale(Vector3(_k["shadow_length"] * shadow.size, 1.0, _k["shadow_width"] * shadow.size))
		_multi.set_instance_transform(i, Transform3D(orient, Vector3(shadow.pos.x * scale_px, _water_y - _k["shadow_depth"], shadow.pos.y * scale_px)))
	for i: int in range(_schools.size()):
		var school: School = _schools[i]
		var pulse: float = 1.0 + sin(_time * _k["school_pulse_freq"] + float(i)) * _k["school_pulse_amount"]
		_rings[i].position = Vector3(school.pos.x * scale_px, _water_y + _k["school_ring_height"], school.pos.y * scale_px)
		_rings[i].scale = Vector3(pulse, _k["school_ring_flatten"], pulse)
		_ring_materials[i].albedo_color = Color(_ring_color, _ring_color.a * (0.75 + 0.25 * sin(_time * _k["school_pulse_freq"] * 2.0 + float(i))))
		_bubbles[i].position = Vector3(school.pos.x * scale_px, _water_y - _k["school_bubble_rise"] * _k["school_bubble_life"] * 0.9, school.pos.y * scale_px)


func _pick(cells: Array[Vector2i]) -> Vector2i:
	return cells[int(_rng.next_float() * float(cells.size()))]


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * WorldGrid.PIXELS_PER_BLOCK


func _is_water_px(pos: Vector2) -> bool:
	return _grid.is_water(floori(pos.x / WorldGrid.PIXELS_PER_BLOCK), floori(pos.y / WorldGrid.PIXELS_PER_BLOCK))


func _new_school() -> School:
	var school := School.new()
	school.pos = _cell_center(_pick(_deep_cells))
	school.life = _data.tune("school_move_seconds") * (0.7 + _rng.next_float() * 0.6)
	return school


## A flat fish silhouette (body ellipse + tail), 1 unit long along +X, drawn as one MultiMesh.
func _build_shadow_visual(look: WorldLook) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	var segments: int = 12
	var center := Vector3(0.1, 0.0, 0.0)
	for i: int in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		tool.add_vertex(center)
		tool.add_vertex(center + Vector3(cos(a0) * 0.4, 0.0, sin(a0) * 0.5))
		tool.add_vertex(center + Vector3(cos(a1) * 0.4, 0.0, sin(a1) * 0.5))
	tool.add_vertex(Vector3(-0.25, 0.0, 0.0))
	tool.add_vertex(Vector3(-0.5, 0.0, 0.45))
	tool.add_vertex(Vector3(-0.5, 0.0, -0.45))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = look.color("fishing", "shadow_color")
	_multi = MultiMesh.new()
	_multi.transform_format = MultiMesh.TRANSFORM_3D
	_multi.mesh = tool.commit()
	_multi.instance_count = _shadows.size()
	var node := MultiMeshInstance3D.new()
	node.multimesh = _multi
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


## A pulsing ring (spot radius) plus rising bubbles for each school.
func _build_school_visual(look: WorldLook) -> void:
	_ring_color = look.color("fishing", "school_ring_color")
	var radius: float = _radius_px / WorldGrid.PIXELS_PER_BLOCK
	var torus := TorusMesh.new()
	torus.outer_radius = radius
	torus.inner_radius = radius - _k["school_ring_width"]
	var bubble_mesh := SphereMesh.new()
	bubble_mesh.radius = _k["school_bubble_size"]
	bubble_mesh.height = _k["school_bubble_size"] * 2.0
	bubble_mesh.radial_segments = 6
	bubble_mesh.rings = 3
	var bubble_material := StandardMaterial3D.new()
	bubble_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_material.albedo_color = look.color("fishing", "school_bubble_color")
	bubble_mesh.material = bubble_material
	for i: int in range(_schools.size()):
		var ring_material := StandardMaterial3D.new()
		ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.albedo_color = _ring_color
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.material_override = ring_material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
		_ring_materials.append(ring_material)
		var bubbles := CPUParticles3D.new()
		bubbles.mesh = bubble_mesh
		bubbles.amount = int(_k["school_bubble_amount"])
		bubbles.lifetime = _k["school_bubble_life"]
		bubbles.direction = Vector3.UP
		bubbles.spread = 5.0
		bubbles.gravity = Vector3.ZERO
		bubbles.initial_velocity_min = _k["school_bubble_rise"]
		bubbles.initial_velocity_max = _k["school_bubble_rise"]
		bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		bubbles.emission_sphere_radius = radius * _k["school_bubble_area"]
		bubbles.emitting = true
		add_child(bubbles)
		_bubbles.append(bubbles)
