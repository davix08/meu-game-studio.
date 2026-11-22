class_name RanchView
extends Node3D
## Draws the animals (Story 016): hens in the coop pen of Story 004, sheep and cows in the
## pasture lot. They wander, stop to graze or peck, and lie still at night. Products waiting to
## be collected show next to each home (eggs by the coop, milk cans and wool by the trough), and
## the trough shows hay while it has feed. Rebuilt on [signal GameState.town_changed].
##
## Usage:
## [codeblock]
## var ranch := RanchView.new()
## add_child(ranch)
## ranch.setup(look, town_data, state, terrain)
## ranch.set_night(true)
## [/codeblock]

## One walking animal.
class Critter:
	extends RefCounted
	var node: MeshInstance3D
	var home: String = ""
	var pos: Vector2 = Vector2.ZERO
	var target: Vector2 = Vector2.ZERO
	var heading: float = 0.0
	var resting: bool = true
	var timer: float = 0.0
	var phase: float = 0.0
	var lift: float = 0.0
	var speed: float = 0.4

var _look: WorldLook
var _town: TownData
var _state: GameState
var _terrain: LakeTerrain
var _material: StandardMaterial3D
var _meshes: Dictionary = {}
var _critters: Array[Critter] = []
var _areas: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _night: bool = false
var _signature: String = ""
var _products: MultiMeshInstance3D
var _product_mesh: Dictionary = {}


## Builds the meshes and the animals from the state.
func setup(look: WorldLook, town: TownData, state: GameState, terrain: LakeTerrain) -> void:
	_look = look
	_town = town
	_state = state
	_terrain = terrain
	_rng.seed = look.integer("estate", "hen_seed")
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_meshes["galinha"] = [EstateMeshes.hen(look, true), EstateMeshes.hen(look, false)]
	_meshes["ovelha"] = [_sheep()]
	_meshes["vaca"] = [_cow()]
	_meshes["bezerro"] = [_cow()]
	_meshes["porco"] = [_pig()]
	var products := MultiMesh.new()
	products.transform_format = MultiMesh.TRANSFORM_3D
	products.use_colors = true
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(0.0, 0.08, 0.0), Vector3(0.07, 0.09, 0.07), Color.WHITE, Color.WHITE, 6, 4, true)
	products.mesh = mb.build()
	_products = MultiMeshInstance3D.new()
	_products.multimesh = products
	_products.material_override = _material
	add_child(_products)
	refresh_areas()
	state.town_changed.connect(refresh)
	refresh()


## Recomputes where each home's animals walk (also after the player places a building).
func refresh_areas() -> void:
	var look: WorldLook = _look
	# Where each home's animals walk: the coop yard in front of the coop, the corral east of the
	# milking stall (lots of the farm map).
	if TownPlan.has_lot(look, "galinheiro"):
		var coop: Rect2i = TownPlan.lot_rect(look, "galinheiro")
		_areas["galinheiro"] = Rect2(float(coop.position.x) + 0.7, float(coop.position.y) + 3.0, float(coop.size.x) - 1.4, float(coop.size.y) - 3.6)
	for pen: String in ["chiqueiro", "ovelhas"]:
		if TownPlan.has_lot(look, pen):
			var pr: Rect2i = TownPlan.lot_rect(look, pen)
			_areas[pen] = Rect2(float(pr.position.x) + 0.8, float(pr.position.y) + 0.8, float(pr.size.x) - 4.0, float(pr.size.y) - 1.6) if pen == "ovelhas" else Rect2(float(pr.position.x) + 0.8, float(pr.position.y) + 0.8, float(pr.size.x) - 1.6, float(pr.size.y) - 3.4)
	if TownPlan.has_lot(look, "curral"):
		var corral: Rect2i = TownPlan.lot_rect(look, "curral")
		_areas["curral"] = Rect2(float(corral.position.x) + 1.0, float(corral.position.y) + 3.6, float(corral.size.x) - 2.0, float(corral.size.y) - 4.6)
	_signature = ""
	if _products != null:
		refresh()


## Where the player stands to feed and collect at [param home_id] (meters, x z).
func anchor(home_id: String) -> Vector2:
	return TownPlan.lot_door(_look, home_id)


## At night the animals lie down and stop walking.
func set_night(on: bool) -> void:
	_night = on


## Recreates the animals when the herd changed and redraws the products.
func refresh() -> void:
	var signature: String = ""
	for a: Dictionary in _state.animals:
		signature += str(a["kind"]) + ","
	for home: Variant in _areas:
		signature += "|" + str(_state.is_built(str(home)))
	if signature != _signature:
		_signature = signature
		for c: Critter in _critters:
			c.node.queue_free()
		_critters.clear()
		for i in _state.animals.size():
			var kind: String = str(_state.animals[i]["kind"])
			var home: String = str(_town.animal(kind).get("home", ""))
			if not _areas.has(home) or not _state.is_built(home):
				continue
			_add_critter(kind, home, i)
	_draw_products()


func _process(delta: float) -> void:
	for c: Critter in _critters:
		_update(c, delta)


func _add_critter(kind: String, home: String, index: int) -> void:
	var c := Critter.new()
	var options: Array = _meshes[kind]
	c.node = MeshInstance3D.new()
	c.node.mesh = options[index % options.size()]
	c.node.material_override = _material
	add_child(c.node)
	c.home = home
	c.pos = _random_point(home)
	c.target = c.pos
	c.heading = _rng.randf() * TAU
	c.phase = _rng.randf() * TAU
	c.lift = 0.25 if kind == "galinha" else 0.0
	if kind == "bezerro":
		c.node.scale = Vector3.ONE * 0.6
	c.speed = 0.45 if kind == "galinha" else 0.35
	c.timer = _rng.randf_range(0.5, 2.5)
	_critters.append(c)
	_place(c, 0.0, 0.0)


func _random_point(home: String) -> Vector2:
	var area: Rect2 = _areas[home]
	return Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))


func _update(c: Critter, delta: float) -> void:
	c.phase += delta
	if _night:
		_place(c, 0.0, -0.08)
		return
	c.timer -= delta
	var tilt: float = 0.0
	var bob: float = 0.0
	if c.resting:
		tilt = -0.35 * maxf(0.0, sin(c.phase * 3.0))
		if c.timer <= 0.0:
			c.resting = false
			c.target = _random_point(c.home)
			c.timer = _rng.randf_range(1.0, 3.0)
	else:
		var to_target: Vector2 = c.target - c.pos
		var dist: float = to_target.length()
		if dist < 0.05 or c.timer <= 0.0:
			c.resting = true
			c.timer = _rng.randf_range(1.5, 4.0)
		else:
			c.heading = lerp_angle(c.heading, atan2(-to_target.y, to_target.x), minf(1.0, 5.0 * delta))
			c.pos += to_target / dist * minf(c.speed * delta, dist)
			bob = absf(sin(c.phase * 10.0)) * 0.03
	_place(c, tilt, bob)


func _place(c: Critter, tilt: float, bob: float) -> void:
	c.node.position = Vector3(c.pos.x, _terrain.ground_height_at(c.pos.x, c.pos.y) + c.lift + bob, c.pos.y)
	c.node.rotation = Vector3(0.0, c.heading, tilt)


func _draw_products() -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for home: String in ["galinheiro", "curral"]:
		if not _areas.has(home):
			continue
		var products: Dictionary = _state.pending.get(home, {})
		var spot: Vector2 = anchor(home) + Vector2(-1.0, 0.6)
		if home == "galinheiro":
			var basket: Vector3 = TownMeshes.egg_basket(_look)
			spot = Vector2(basket.x - 0.2, basket.z - 0.1)
		var n: int = 0
		for id: Variant in products:
			var color: Color = Color.html(str(_town.good(str(id)).get("color", "#ffffff")))
			var big: bool = str(id) != "ovo"
			for k in mini(int(products[id]), 8):
				var offset := Vector2(float(n % 4) * 0.22, float(n / 4) * 0.22)
				transforms.append(Transform3D(Basis.from_scale(Vector3.ONE * (2.2 if big else 1.0)), Vector3(spot.x + offset.x, 0.3 if home == "galinheiro" else 0.05, spot.y + offset.y)))
				colors.append(color)
				n += 1
	var multi: MultiMesh = _products.multimesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])


func _sheep() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var wool: Color = Color.html(str(_town.good("la").get("color", "#ffffff")))
	var dark := Color(0.2, 0.18, 0.18)
	mb.add_ellipsoid(Vector3(0.0, 0.5, 0.0), Vector3(0.45, 0.32, 0.3), wool.darkened(0.1), wool, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.45, 0.62, 0.0), Vector3(0.15, 0.14, 0.13), dark, dark, 6, 4, true)
	for p: Vector2 in [Vector2(-0.25, -0.15), Vector2(-0.25, 0.15), Vector2(0.25, -0.15), Vector2(0.25, 0.15)]:
		mb.add_box(Vector3(p.x, 0.15, p.y), Vector3(0.08, 0.3, 0.08), dark)
	return mb.build()


func _pig() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var pink := Color(0.96, 0.72, 0.74)
	mb.add_ellipsoid(Vector3(0.0, 0.42, 0.0), Vector3(0.48, 0.3, 0.3), pink.darkened(0.1), pink, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.45, 0.5, 0.0), Vector3(0.18, 0.18, 0.18), pink, pink, 6, 4, true)
	mb.add_box(Vector3(0.62, 0.48, 0.0), Vector3(0.08, 0.12, 0.16), pink.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(0.45, 0.68, side * 0.1), Vector3(0.06, 0.1, 0.08), pink.darkened(0.15))
	for p: Vector2 in [Vector2(-0.25, -0.15), Vector2(-0.25, 0.15), Vector2(0.25, -0.15), Vector2(0.25, 0.15)]:
		mb.add_box(Vector3(p.x, 0.12, p.y), Vector3(0.1, 0.24, 0.1), pink.darkened(0.2))
	return mb.build()


## A blocky Holstein cow in the pixel style of the user's picture (2026-11-22): white body
## with black patches, black head with a white blaze, pink snout and udder, small horns, black
## hooves and a tail. It faces +x.
func _cow() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var white := Color(0.95, 0.94, 0.92)
	var black := Color(0.1, 0.09, 0.1)
	var pink := Color(0.95, 0.62, 0.6)
	var horn := Color(0.92, 0.88, 0.75)
	mb.add_box(Vector3(0.0, 0.78, 0.0), Vector3(1.15, 0.55, 0.6), white)
	for patch: Array in [[Vector3(-0.25, 0.92, 0.301), Vector3(0.4, 0.3, 0.01)], [Vector3(0.2, 0.7, 0.301), Vector3(0.25, 0.25, 0.01)], [Vector3(-0.1, 0.85, -0.301), Vector3(0.45, 0.35, 0.01)], [Vector3(0.3, 1.056, 0.05), Vector3(0.3, 0.01, 0.35)], [Vector3(-0.35, 1.056, -0.1), Vector3(0.3, 0.01, 0.3)], [Vector3(-0.576, 0.8, 0.0), Vector3(0.01, 0.3, 0.3)]]:
		mb.add_box(patch[0], patch[1], black)
	mb.add_box(Vector3(0.0, 0.5, 0.0), Vector3(0.3, 0.06, 0.3), pink)
	mb.add_box(Vector3(0.72, 0.95, 0.0), Vector3(0.34, 0.36, 0.38), black)
	mb.add_box(Vector3(0.82, 0.98, 0.0), Vector3(0.16, 0.22, 0.1), white)
	mb.add_box(Vector3(0.92, 0.84, 0.0), Vector3(0.1, 0.16, 0.3), pink)
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(0.66, 1.16, side * 0.15), Vector3(0.06, 0.12, 0.06), horn)
		mb.add_box(Vector3(0.62, 1.02, side * 0.24), Vector3(0.06, 0.08, 0.12), black)
	for p: Vector2 in [Vector2(-0.42, -0.2), Vector2(-0.42, 0.2), Vector2(0.38, -0.2), Vector2(0.38, 0.2)]:
		mb.add_box(Vector3(p.x, 0.3, p.y), Vector3(0.15, 0.46, 0.15), white)
		mb.add_box(Vector3(p.x, 0.05, p.y), Vector3(0.16, 0.1, 0.16), black)
	mb.add_box(Vector3(-0.6, 0.7, 0.0), Vector3(0.05, 0.4, 0.05), white)
	mb.add_box(Vector3(-0.6, 0.48, 0.0), Vector3(0.08, 0.1, 0.08), black)
	return mb.build()
