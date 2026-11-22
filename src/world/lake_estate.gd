class_name LakeEstate
extends Node3D
## The house, farm and village of Lago Esmeralda (Story 004, design/game-brief.md, MVP
## feature 11): the improved fishing house, shed with firewood and tractor, fenced vegetable
## garden with a scarecrow, chicken coop with four animated hens, water tower, windmill with
## turning blades, fish shop with striped awning, notice board, bench, lamp posts and fences.
##
## [method plan] runs first (before the terrain is built) and clears the trees and rocks under
## the footprints and marks them solid in the [WorldGrid]. [method build] then creates one
## static mesh, one glow-able glass mesh, a few MultiMeshes (fences, plants, crates, barrels,
## logs, wheels) and the only animated nodes: the hens and the windmill rotor.
## The garden and the coop are scenery only. Windows and lamps start dark; the day/night
## story calls [method set_lights].
##
## Usage:
## [codeblock]
## LakeEstate.plan(grid, look)          # before terrain.build
## var estate := LakeEstate.new()
## add_child(estate)
## estate.build(terrain, look)
## estate.set_lights(true)              # at dusk (Story 008)
## [/codeblock]

## Data prefixes of the rectangles that block the fisherman (lamps and path fences are added
## by count in [method plan]).
const SOLID_PREFIXES: Array[String] = ["shed", "tractor", "garden", "pen", "tower", "mill", "shop", "board", "bench"]

var _look: WorldLook
var _terrain: LakeTerrain
var _material: Material
var _glass_material: StandardMaterial3D
var _glow_energy: float = 0.0
var _hens: Array[Hen] = []
var _hen_min: Vector2 = Vector2.ZERO
var _hen_max: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _rotor: Node3D
var _mill_speed: float = 0.0


## State of one hen.
class Hen:
	extends RefCounted
	var node: MeshInstance3D
	var pos: Vector2 = Vector2.ZERO
	var target: Vector2 = Vector2.ZERO
	var heading: float = 0.0
	var pecking: bool = true
	var timer: float = 0.0
	var phase: float = 0.0


## Clears the props under every estate footprint (plus the margin) and marks the footprints
## solid in [param grid]; paths, spawn, pier and lake access are not touched. Call it right
## after creating the grid, before the terrain is built.
static func plan(grid: WorldGrid, look: WorldLook) -> void:
	var rects: Array[Rect2i] = []
	var parts: Array = EstateMeshes.parts_of(look)
	for prefix: String in SOLID_PREFIXES:
		if parts.has(prefix):
			rects.append(EstateMeshes.cell_rect(look, prefix))
	for i in (look.integer(EstateMeshes.GROUP, "lamp_count") if parts.has("lamps") else 0):
		rects.append(EstateMeshes.cell_rect(look, "lamp_%d" % (i + 1)))
	for i in look.integer(EstateMeshes.GROUP, "pathfence_count"):
		rects.append(EstateMeshes.cell_rect(look, "pathfence_%d" % (i + 1)))
	var margin: int = look.integer(EstateMeshes.GROUP, "clear_margin")
	var plaza: Rect2i = EstateMeshes.cell_rect(look, "plaza")
	grid.clear_area(plaza)
	for rect: Rect2i in rects:
		grid.clear_area(rect.grow(margin))
	grid.paint_dirt(plaza)
	for rect: Rect2i in rects:
		grid.block_area(rect)


## Builds all the models on [param terrain], styled by [param look].
func build(terrain: LakeTerrain, look: WorldLook) -> void:
	_terrain = terrain
	_look = look
	_material = HouseInterior.pixel_material(look)
	var glass := MeshBuilder.new()
	_add_mesh(EstateMeshes.build_static(look, glass), _material)
	_glass_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_glass_material.emission_enabled = true
	_glass_material.emission = look.color(EstateMeshes.GROUP, "glow_color")
	_glass_material.emission_energy_multiplier = 0.0
	_glow_energy = look.num(EstateMeshes.GROUP, "glow_energy")
	_add_mesh(glass.build(), _glass_material)
	set_lights(look.integer(EstateMeshes.GROUP, "lights_on") == 1)
	var parts: Array = EstateMeshes.parts_of(look)
	_build_fences()
	if parts.has("garden"):
		_build_garden_plants()
	if parts.has("shop"):
		_build_shop_props()
	if parts.has("shed") or parts.has("tractor"):
		_build_shed_props()
	if parts.has("pen"):
		_build_hens()
	if parts.has("mill"):
		_build_windmill()


## Turns the glow of the windows and lamp glass on or off.
func set_lights(on: bool) -> void:
	_glass_material.emission_energy_multiplier = _glow_energy if on else 0.0


func _process(delta: float) -> void:
	if _rotor != null:
		_rotor.rotation.z -= _mill_speed * delta
	for hen: Hen in _hens:
		_update_hen(hen, delta)


func _add_mesh(mesh: ArrayMesh, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	add_child(node)


func _add_multimesh(mesh: ArrayMesh, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = _material
	add_child(node)


## Fence modules around the garden and the pen, and along the path fence rectangles.
func _build_fences() -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var inset: float = _look.num(EstateMeshes.GROUP, "fence_inset")
	for prefix: String in ["garden", "pen"]:
		if not EstateMeshes.parts_of(_look).has(prefix):
			continue
		var r: Rect2i = EstateMeshes.cell_rect(_look, prefix)
		var lo := Vector2(float(r.position.x) + inset, float(r.position.y) + inset)
		var hi := Vector2(float(r.end.x) - inset, float(r.end.y) - inset)
		_fence_line(lo, Vector2(hi.x, lo.y), transforms, colors)
		_fence_line(Vector2(lo.x, hi.y), hi, transforms, colors)
		_fence_line(lo, Vector2(lo.x, hi.y), transforms, colors)
		_fence_line(Vector2(hi.x, lo.y), hi, transforms, colors)
	for i in _look.integer(EstateMeshes.GROUP, "pathfence_count"):
		var r: Rect2i = EstateMeshes.cell_rect(_look, "pathfence_%d" % (i + 1))
		var mid: Vector2 = Vector2(float(r.position.x), float(r.position.y)) + Vector2(float(r.size.x), float(r.size.y)) * 0.5
		if r.size.x >= r.size.y:
			_fence_line(Vector2(float(r.position.x), mid.y), Vector2(float(r.end.x), mid.y), transforms, colors)
		else:
			_fence_line(Vector2(mid.x, float(r.position.y)), Vector2(mid.x, float(r.end.y)), transforms, colors)
	_add_multimesh(EstateMeshes.fence_module(_look), transforms, colors)


func _fence_line(a: Vector2, b: Vector2, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var count: int = maxi(1, roundi(a.distance_to(b)))
	var step: Vector2 = (b - a) / float(count)
	var yaw: float = atan2(-step.y, step.x)
	var module_basis: Basis = Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(step.length(), 1.0, 1.0))
	for k in count:
		var p: Vector2 = a + step * (float(k) + 0.5)
		transforms.append(Transform3D(module_basis,Vector3(p.x, _terrain.ground_height_at(p.x, p.y), p.y)))
		var tint: float = lerpf(_look.num("props", "tint_min"), _look.num("props", "tint_max"), WorldGrid.hash2(roundi(p.x * 4.0), roundi(p.y * 4.0), 31))
		colors.append(Color(tint, tint, tint, 1.0))


## Crop plants along every bed, plus the harvest crate in the free strip of the garden.
func _build_garden_plants() -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var tints: Array[Color] = _look.color_list(EstateMeshes.GROUP, "plant_tints")
	var spacing: float = _look.num(EstateMeshes.GROUP, "plant_spacing")
	var beds: Array[Vector3] = EstateMeshes.garden_beds(_look)
	# Story 015: with garden_plants 0 the beds are farm plots and [FarmView] draws the crops.
	if _look.integer(EstateMeshes.GROUP, "garden_plants") == 0:
		beds.clear()
	for row in beds.size():
		var bed: Vector3 = beds[row]
		var count: int = int((bed.z - bed.x) / spacing)
		for k in count:
			var x: float = bed.x + (float(k) + 0.5) * spacing
			var cell := Vector2i(roundi(x * 4.0), row)
			var size: float = lerpf(0.85, 1.2, WorldGrid.hash2(cell.x, cell.y, 41))
			var plant_basis: Basis = Basis(Vector3.UP, WorldGrid.hash2(cell.x, cell.y, 42) * TAU) * Basis.from_scale(Vector3.ONE * size)
			transforms.append(Transform3D(plant_basis, Vector3(x, 0.16 + _look.num(EstateMeshes.GROUP, "ground_lift"), bed.y)))
			colors.append(tints[row % tints.size()])
	if not transforms.is_empty():
		_add_multimesh(EstateMeshes.plant(_look), transforms, colors)
	var strip: Vector2 = EstateMeshes.garden_strip_center(_look)
	var crate_t: Array[Transform3D] = [Transform3D(Basis(Vector3.UP, 0.3), Vector3(strip.x, 0.0, strip.y + 1.0))]
	var crate_c: Array[Color] = [Color.WHITE]
	_add_multimesh(EstateMeshes.crate(_look, "veg_orange"), crate_t, crate_c)


## Fish crates and barrels in front of the shop (on the plaza side of the door).
func _build_shop_props() -> void:
	var r: Rect2i = EstateMeshes.cell_rect(_look, "shop")
	var gap: float = _look.num(EstateMeshes.GROUP, "prop_gap")
	var front: float = float(r.end.x) + 0.4
	var crate_t: Array[Transform3D] = []
	var crate_c: Array[Color] = []
	var first_z: float = float(r.end.y) - 0.8
	for i in _look.integer(EstateMeshes.GROUP, "crates_count"):
		var stacked: bool = i >= 2
		var z: float = first_z + (gap * 0.5 if stacked else float(i) * gap * 0.9)
		crate_t.append(Transform3D(Basis(Vector3.UP, 0.15 * float(i)), Vector3(front, 0.4 if stacked else 0.0, z)))
		crate_c.append(Color.WHITE)
	_add_multimesh(EstateMeshes.crate(_look, "fish_silver"), crate_t, crate_c)
	var barrel_t: Array[Transform3D] = []
	var barrel_c: Array[Color] = []
	for i in _look.integer(EstateMeshes.GROUP, "barrels_count"):
		barrel_t.append(Transform3D(Basis(Vector3.UP, float(i)), Vector3(front, 0.0, float(r.position.y) + 0.4 + float(i) * gap)))
		barrel_c.append(Color.WHITE)
	_add_multimesh(EstateMeshes.barrel(_look), barrel_t, barrel_c)


## The firewood pile inside the shed and the tractor wheels.
func _build_shed_props() -> void:
	var shed: Rect2i = EstateMeshes.cell_rect(_look, "shed")
	var log_t: Array[Transform3D] = []
	var log_c: Array[Color] = []
	var radius: float = 0.1
	var log_basis: Basis = Basis(Vector3.BACK, -PI * 0.5)
	for layer in _look.integer(EstateMeshes.GROUP, "pile_layers"):
		for i in _look.integer(EstateMeshes.GROUP, "pile_base") - layer:
			var x: float = float(shed.position.x) + 0.25
			var z: float = float(shed.position.y) + 0.35 + float(layer) * radius + float(i) * radius * 2.0
			var length: float = lerpf(0.9, 1.15, WorldGrid.hash2(i, layer, 51))
			log_t.append(Transform3D(log_basis * Basis.from_scale(Vector3(1.0, length, 1.0)), Vector3(x, radius + float(layer) * radius * 1.75, z)))
			var tint: float = lerpf(0.85, 1.1, WorldGrid.hash2(i, layer, 52))
			log_c.append(Color(tint, tint, tint, 1.0))
	_add_multimesh(EstateMeshes.log_piece(_look), log_t, log_c)

	var tractor_rect: Rect2i = EstateMeshes.cell_rect(_look, "tractor")
	var cx: float = float(tractor_rect.position.x) + float(tractor_rect.size.x) * 0.5
	var cz: float = float(tractor_rect.position.y) + float(tractor_rect.size.y) * 0.5
	var big_r: float = _look.num(EstateMeshes.GROUP, "wheel_big_radius")
	var big_w: float = _look.num(EstateMeshes.GROUP, "wheel_big_width")
	var small_r: float = _look.num(EstateMeshes.GROUP, "wheel_small_radius")
	var small_w: float = _look.num(EstateMeshes.GROUP, "wheel_small_width")
	var flip: Basis = Basis(Vector3.RIGHT, PI * 0.5)
	var wheel_t: Array[Transform3D] = []
	var wheel_c: Array[Color] = []
	for side: float in [-1.0, 1.0]:
		wheel_t.append(Transform3D(flip * Basis.from_scale(Vector3(big_r, big_w, big_r)), Vector3(cx - 0.6, big_r, cz + side * 0.62)))
		wheel_t.append(Transform3D(flip * Basis.from_scale(Vector3(small_r, small_w, small_r)), Vector3(cx + 0.75, small_r, cz + side * 0.45)))
		wheel_c.append(Color.WHITE)
		wheel_c.append(Color.WHITE)
	_add_multimesh(EstateMeshes.wheel(_look), wheel_t, wheel_c)


func _build_hens() -> void:
	var pen: Rect2i = EstateMeshes.cell_rect(_look, "pen")
	var margin: float = _look.num(EstateMeshes.GROUP, "hen_margin")
	var coop_end: float = float(pen.position.y) + 0.3 + _look.num(EstateMeshes.GROUP, "coop_depth") + 0.35
	_hen_min = Vector2(float(pen.position.x) + margin, coop_end)
	_hen_max = Vector2(float(pen.end.x) - margin, float(pen.end.y) - margin)
	_rng.seed = _look.integer(EstateMeshes.GROUP, "hen_seed")
	var white_mesh: ArrayMesh = EstateMeshes.hen(_look, true)
	var brown_mesh: ArrayMesh = EstateMeshes.hen(_look, false)
	var white_count: int = _look.integer(EstateMeshes.GROUP, "hen_white_count")
	for i in _look.integer(EstateMeshes.GROUP, "hen_count"):
		var hen := Hen.new()
		hen.node = MeshInstance3D.new()
		hen.node.mesh = white_mesh if i < white_count else brown_mesh
		hen.node.material_override = _material
		add_child(hen.node)
		hen.pos = _random_hen_point()
		hen.target = hen.pos
		hen.heading = _rng.randf() * TAU
		hen.timer = _rng.randf_range(_look.num(EstateMeshes.GROUP, "hen_peck_min"), _look.num(EstateMeshes.GROUP, "hen_peck_max"))
		hen.phase = _rng.randf() * TAU
		_hens.append(hen)
		_place_hen(hen, 0.0, 0.0)


func _random_hen_point() -> Vector2:
	return Vector2(_rng.randf_range(_hen_min.x, _hen_max.x), _rng.randf_range(_hen_min.y, _hen_max.y))


## Walks in short bobbing steps toward a random spot, then stops and pecks the ground.
func _update_hen(hen: Hen, delta: float) -> void:
	hen.timer -= delta
	hen.phase += delta
	var tilt: float = 0.0
	var bob: float = 0.0
	if hen.pecking:
		var wave: float = maxf(0.0, sin(hen.phase * _look.num(EstateMeshes.GROUP, "hen_peck_freq")))
		tilt = -_look.num(EstateMeshes.GROUP, "hen_peck_angle") * wave * wave
		if hen.timer <= 0.0:
			hen.pecking = false
			hen.target = _random_hen_point()
			hen.timer = _rng.randf_range(_look.num(EstateMeshes.GROUP, "hen_walk_min"), _look.num(EstateMeshes.GROUP, "hen_walk_max"))
	else:
		var to_target: Vector2 = hen.target - hen.pos
		var dist: float = to_target.length()
		if dist < 0.05 or hen.timer <= 0.0:
			hen.pecking = true
			hen.timer = _rng.randf_range(_look.num(EstateMeshes.GROUP, "hen_peck_min"), _look.num(EstateMeshes.GROUP, "hen_peck_max"))
		else:
			hen.heading = lerp_angle(hen.heading, atan2(-to_target.y, to_target.x), minf(1.0, _look.num(EstateMeshes.GROUP, "hen_turn_speed") * delta))
			hen.pos += to_target / dist * minf(_look.num(EstateMeshes.GROUP, "hen_speed") * delta, dist)
			bob = absf(sin(hen.phase * _look.num(EstateMeshes.GROUP, "hen_step_freq"))) * _look.num(EstateMeshes.GROUP, "hen_step_bob")
	_place_hen(hen, tilt, bob)


func _place_hen(hen: Hen, tilt: float, bob: float) -> void:
	hen.node.position = Vector3(hen.pos.x, _terrain.ground_height_at(hen.pos.x, hen.pos.y) + 0.25 + bob, hen.pos.y)
	hen.node.rotation = Vector3(0.0, hen.heading, tilt)


## The windmill rotor on the front of the tower, turning slowly.
func _build_windmill() -> void:
	var r: Rect2i = EstateMeshes.cell_rect(_look, "mill")
	var yaw: float = deg_to_rad(_look.num(EstateMeshes.GROUP, "mill_yaw_degrees"))
	var forward: float = _look.num(EstateMeshes.GROUP, "mill_hub_forward")
	var pivot := Node3D.new()
	pivot.position = Vector3(float(r.position.x) + float(r.size.x) * 0.5 + sin(yaw) * forward, _look.num(EstateMeshes.GROUP, "mill_hub_height"), float(r.position.y) + float(r.size.y) * 0.5 + cos(yaw) * forward)
	pivot.rotation.y = yaw
	add_child(pivot)
	_rotor = Node3D.new()
	pivot.add_child(_rotor)
	var blades := MeshInstance3D.new()
	blades.mesh = EstateMeshes.rotor(_look)
	blades.material_override = _material
	_rotor.add_child(blades)
	_mill_speed = _look.num(EstateMeshes.GROUP, "mill_speed")
