class_name CropFieldView
extends Node3D
## Draws the field plots of the real-time farm (2026-11-21; look redone 2026-11-22 twice: crop
## rows, then the owner's voxel farm picture). Each bought plot is a bed of blocky soil rows
## with clods between dark furrows, and a line of plants on every row, in the pixel material:
##   - growing: green blocks, sprout (small, bright) to half grown (taller, green-yellow),
##     tinted per instance;
##   - ripe: the crop's own blocky model (wheat ears, corn cobs, soy pods, carrot tops with the
##     orange root showing, sugar cane), one MultiMesh per crop.
## Data: town.crop_* in world_look.json, crop ids from farm_prod.json. Redrawn every second.
## Plot i sits at column i % cols, row i / cols of 2x2-block squares (town.field_plot_cols).
##
## Usage:
## [codeblock]
## var field := CropFieldView.new()
## add_child(field)
## field.setup(look, state, production)
## [/codeblock]

const PLOT_SIZE: float = 2.0

var _look: WorldLook
var _state: GameState
var _prod: Production
var _soil: MultiMeshInstance3D
var _young: MultiMeshInstance3D
## Crop id -> MultiMeshInstance3D of its ripe model.
var _ripe: Dictionary = {}
var _material: Material
var _timer: float = 0.0
var _ridges: int = 3
var _per_ridge: int = 5
# Reused every refresh (no allocation per second).
var _soil_t: Array[Transform3D] = []
var _soil_c: Array[Color] = []
var _young_t: Array[Transform3D] = []
var _young_c: Array[Color] = []
var _ripe_t: Dictionary = {}
var _ripe_c: Dictionary = {}


## Builds the soil bed, the growing plant and one ripe model per crop.
func setup(look: WorldLook, state: GameState, production: Production) -> void:
	_look = look
	_state = state
	_prod = production
	_ridges = maxi(1, look.integer("town", "crop_ridges"))
	_per_ridge = maxi(1, look.integer("town", "crop_stalks_per_ridge"))
	_material = HouseInterior.pixel_material(look)
	_soil = _layer(_bed_mesh())
	_young = _layer(_young_mesh())
	for id: String in ["trigo", "milho", "soja", "cenoura", "cana"]:
		_ripe[id] = _layer(_ripe_mesh(id))
		var t: Array[Transform3D] = []
		var c: Array[Color] = []
		_ripe_t[id] = t
		_ripe_c[id] = c
	state.town_changed.connect(refresh)
	refresh()


## One plot of soil: a dark furrow floor, [code]crop_ridges[/code] blocky rows and clods.
func _bed_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	var furrow: Color = _look.color("town", "crop_furrow_color")
	var ridge: Color = _look.color("town", "crop_ridge_color")
	var clod: Color = _look.color("town", "crop_clod_color")
	b.add_box(Vector3(0.0, 0.03, 0.0), Vector3(PLOT_SIZE * 0.96, 0.06, PLOT_SIZE * 0.96), furrow)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var step: float = PLOT_SIZE * 0.9 / float(_ridges)
	for r in _ridges:
		var z: float = -PLOT_SIZE * 0.45 + step * (float(r) + 0.5)
		b.add_box(Vector3(0.0, 0.1, z), Vector3(PLOT_SIZE * 0.9, 0.14, step * 0.8), ridge.darkened(0.1))
		b.add_box(Vector3(0.0, 0.2, z), Vector3(PLOT_SIZE * 0.86, 0.06, step * 0.5), ridge)
		for k in 6:
			var x: float = rng.randf_range(-0.8, 0.8)
			var s: float = 0.0625 if k % 2 == 0 else 0.125
			b.add_box(Vector3(x, 0.24, z + rng.randf_range(-0.12, 0.12)), Vector3(s, s * 0.8, s), clod)
	return b.build()


## A growing plant: a few green blocks (white-ish, tinted per instance).
func _young_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	var base := Color(0.8, 0.8, 0.8)
	b.add_box(Vector3(0.0, 0.12, 0.0), Vector3(0.06, 0.24, 0.06), base)
	for p: Vector3 in [Vector3(0.07, 0.2, 0.0), Vector3(-0.07, 0.28, 0.03), Vector3(0.0, 0.36, -0.07), Vector3(0.0, 0.44, 0.05)]:
		b.add_box(p, Vector3(0.12, 0.06, 0.1), Color.WHITE)
	return b.build()


## The blocky ripe model of crop [param id] (colors from town.crop_* and the crop's color).
func _ripe_mesh(id: String) -> ArrayMesh:
	var b := MeshBuilder.new()
	var crop: Dictionary = _prod.crop(id)
	var main: Color = Color.html(str(crop.get("color", "#e8c860")))
	var stalk: Color = Color.html(str(crop.get("stalk", "#5a9a30")))
	var leaf: Color = _look.color("town", "crop_leaf")
	match id:
		"trigo":
			for p: Vector2 in [Vector2(-0.06, -0.05), Vector2(0.07, -0.02), Vector2(0.0, 0.07)]:
				b.add_box(Vector3(p.x, 0.22, p.y), Vector3(0.04, 0.44, 0.04), stalk)
				for k in 4:
					b.add_box(Vector3(p.x + (0.025 if k % 2 == 0 else -0.025), 0.48 + float(k) * 0.06, p.y), Vector3(0.06, 0.06, 0.07), main if k % 2 == 0 else main.darkened(0.12))
				b.add_box(Vector3(p.x, 0.73, p.y), Vector3(0.02, 0.08, 0.02), main.lightened(0.2))
		"milho":
			b.add_box(Vector3(0.0, 0.42, 0.0), Vector3(0.07, 0.84, 0.07), leaf)
			for k in 3:
				var side: float = 1.0 if k % 2 == 0 else -1.0
				b.add_box(Vector3(side * 0.1, 0.3 + float(k) * 0.2, 0.0), Vector3(0.18, 0.04, 0.06), leaf.lightened(0.1))
			b.add_box(Vector3(0.07, 0.48, 0.05), Vector3(0.09, 0.2, 0.09), main)
			b.add_box(Vector3(0.07, 0.6, 0.05), Vector3(0.06, 0.05, 0.06), leaf.lightened(0.2))
			b.add_box(Vector3(0.0, 0.9, 0.0), Vector3(0.04, 0.1, 0.04), stalk.lightened(0.3))
		"soja":
			for p: Vector3 in [Vector3(0.0, 0.18, 0.0), Vector3(0.08, 0.26, 0.04), Vector3(-0.07, 0.3, -0.04), Vector3(0.0, 0.36, 0.06)]:
				b.add_box(p, Vector3(0.16, 0.12, 0.14), leaf if p.y < 0.3 else leaf.lightened(0.12))
			for p: Vector3 in [Vector3(0.1, 0.2, -0.06), Vector3(-0.1, 0.24, 0.07), Vector3(0.05, 0.4, -0.05)]:
				b.add_box(p, Vector3(0.04, 0.09, 0.04), main)
		"cenoura":
			b.add_box(Vector3(0.0, 0.2, 0.0), Vector3(0.12, 0.08, 0.12), main)
			b.add_box(Vector3(0.0, 0.25, 0.0), Vector3(0.09, 0.04, 0.09), main.lightened(0.1))
			for p: Vector2 in [Vector2(-0.04, 0.0), Vector2(0.04, 0.03), Vector2(0.0, -0.04)]:
				b.add_box(Vector3(p.x, 0.38, p.y), Vector3(0.04, 0.24, 0.04), stalk)
				b.add_box(Vector3(p.x * 1.8, 0.5, p.y * 1.8), Vector3(0.08, 0.06, 0.08), stalk.lightened(0.15))
		_:
			for p: Vector2 in [Vector2(-0.05, -0.04), Vector2(0.06, 0.0), Vector2(0.0, 0.06)]:
				for k in 4:
					b.add_box(Vector3(p.x, 0.13 + float(k) * 0.24, p.y), Vector3(0.06, 0.22, 0.06), stalk if k % 2 == 0 else stalk.darkened(0.15))
				b.add_box(Vector3(p.x + 0.06, 1.0, p.y), Vector3(0.14, 0.04, 0.05), leaf)
	return b.build()


## Center (x, z) of plot [param i].
func plot_center(i: int) -> Vector2:
	var r: Rect2i = TownPlan.lot_rect(_look, "plantacao")
	var cols: int = _look.integer("town", "field_plot_cols")
	return Vector2(float(r.position.x) + 2.0 + float(i % cols) * 2.0, float(r.position.y) + 2.0 + float(i / cols) * 2.0)


## The plot under ground point [param point] (meters, x z), or -1.
func plot_at(point: Vector2) -> int:
	for i in _state.crop_plots.size():
		var c: Vector2 = plot_center(i)
		if absf(point.x - c.x) <= 1.0 and absf(point.y - c.y) <= 1.0:
			return i
	return -1


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 1.0
		refresh()


## Redraws the beds and the crops.
func refresh() -> void:
	_soil_t.clear()
	_soil_c.clear()
	_young_t.clear()
	_young_c.clear()
	for id: Variant in _ripe_t:
		(_ripe_t[id] as Array).clear()
		(_ripe_c[id] as Array).clear()
	var sprout: Color = _look.color("town", "crop_sprout")
	var growing: Color = _look.color("town", "crop_growing")
	var step: float = PLOT_SIZE * 0.9 / float(_ridges)
	for i in _state.crop_plots.size():
		var c: Vector2 = plot_center(i)
		_soil_t.append(Transform3D(Basis.IDENTITY, Vector3(c.x, 0.0, c.y)))
		_soil_c.append(Color.WHITE)
		var stage: int = _prod.plot_stage(i)
		if stage == 0:
			continue
		var id: String = str(_state.crop_plots[i]["crop"])
		var growth: float = _prod.plot_growth(i)
		var ripe: bool = stage == 2 and _ripe_t.has(id)
		var color: Color = sprout if growth < 0.5 else sprout.lerp(growing, (growth - 0.5) * 2.0)
		var size: float = lerpf(0.35, 0.6, growth * 2.0) if growth < 0.5 else lerpf(0.65, 0.95, (growth - 0.5) * 2.0)
		for r in _ridges:
			var z: float = c.y - PLOT_SIZE * 0.45 + step * (float(r) + 0.5)
			for k in _per_ridge:
				# Fixed jitter per spot (no random: the field must not flicker every second).
				var h: int = (i * 131 + r * 31 + k * 17) % 97
				var jx: float = (float(h % 7) - 3.0) * 0.012
				var jz: float = (float(h % 5) - 2.0) * 0.015
				var x: float = c.x - PLOT_SIZE * 0.4 + PLOT_SIZE * 0.8 * (float(k) + 0.5) / float(_per_ridge)
				var at := Vector3(x + jx, 0.12, z + jz)
				var yaw := Basis(Vector3.UP, float(h % 4) * PI * 0.5)
				if ripe:
					var s: float = 0.9 + float(h % 3) * 0.08
					(_ripe_t[id] as Array).append(Transform3D(yaw * Basis.from_scale(Vector3(s, s, s)), at))
					(_ripe_c[id] as Array).append(Color.WHITE)
				else:
					var s2: float = size * (0.85 + float(h % 4) * 0.06)
					_young_t.append(Transform3D(yaw * Basis.from_scale(Vector3(s2, s2, s2)), at))
					_young_c.append(color)
	_fill(_soil, _soil_t, _soil_c)
	_fill(_young, _young_t, _young_c)
	for id: Variant in _ripe:
		_fill(_ripe[id], _ripe_t[id], _ripe_c[id])


func _layer(mesh: ArrayMesh) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = _material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node


func _fill(node: MultiMeshInstance3D, transforms: Array, colors: Array) -> void:
	var multi: MultiMesh = node.multimesh
	if multi.instance_count != transforms.size():
		multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
