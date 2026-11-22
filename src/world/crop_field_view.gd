class_name CropFieldView
extends Node3D
## Draws the field plots of the real-time farm (2026-11-21, look redone 2026-11-22 after the
## user's crop-rows picture): each bought plot is a bed of mounded soil rows (running east-west, across the view) with clods between
## dark furrows, and a dense line of stalks on every row. The stalks grow in three looks:
## sprout (small, bright green), growing (taller, green-yellow) and ripe (full size, the crop's
## stalk color with an ear of the crop color on top). Data: town.crop_* in world_look.json and
## the crop's "stalk"/"color" in farm_prod.json. Redrawn every second.
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
var _stalks: MultiMeshInstance3D
var _ears: MultiMeshInstance3D
var _material: StandardMaterial3D
var _timer: float = 0.0
var _ridges: int = 3
var _per_ridge: int = 6
# Reused every refresh (no allocation per second).
var _soil_t: Array[Transform3D] = []
var _soil_c: Array[Color] = []
var _stalk_t: Array[Transform3D] = []
var _stalk_c: Array[Color] = []
var _ear_t: Array[Transform3D] = []
var _ear_c: Array[Color] = []


## Builds the soil bed mesh, the stalk clump and the ear.
func setup(look: WorldLook, state: GameState, production: Production) -> void:
	_look = look
	_state = state
	_prod = production
	_ridges = maxi(1, look.integer("town", "crop_ridges"))
	_per_ridge = maxi(1, look.integer("town", "crop_stalks_per_ridge"))
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_soil = _layer(_bed_mesh())
	_stalks = _layer(_stalk_mesh())
	_ears = _layer(_ear_mesh())
	state.town_changed.connect(refresh)
	refresh()


## One plot of soil: a dark furrow floor, [code]crop_ridges[/code] rounded rows and clods.
## Vertex colors are final (the instance color stays white).
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
		b.add_ellipsoid(Vector3(0.0, 0.06, z), Vector3(PLOT_SIZE * 0.46, 0.17, step * 0.45), ridge.darkened(0.15), ridge, 8, 4, true)
		for k in 7:
			var x: float = rng.randf_range(-0.8, 0.8)
			var side: float = rng.randf_range(-0.6, 0.6) * step * 0.4
			var s: float = rng.randf_range(0.05, 0.09)
			b.add_box(Vector3(x, 0.19 + rng.randf_range(-0.03, 0.02), z + side), Vector3(s, s * 0.8, s), clod)
	return b.build()


## A clump of thin leaves, white so the instance color tints it (brighter at the tips).
func _stalk_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	var base := Color(0.78, 0.78, 0.78)
	for k in 7:
		var a: float = float(k) * TAU / 7.0
		var lean := Vector3(cos(a), 0.0, sin(a)) * 0.09
		b.add_cone(lean * 0.3, 0.04, 0.006, 0.5 + 0.08 * float(k % 3), base, Color.WHITE, 4)
		b.add_cone(lean, 0.03, 0.004, 0.32, base, Color.WHITE, 4)
	return b.build()


## The ripe ear on top of a stalk.
func _ear_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_ellipsoid(Vector3.ZERO, Vector3(0.06, 0.14, 0.06), Color(0.85, 0.85, 0.85), Color.WHITE, 6, 4, true)
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
	_stalk_t.clear()
	_stalk_c.clear()
	_ear_t.clear()
	_ear_c.clear()
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
		var crop: Dictionary = _prod.crop(str(_state.crop_plots[i]["crop"]))
		var growth: float = _prod.plot_growth(i)
		var color: Color
		var size: float
		if stage == 2:
			color = Color.html(str(crop.get("stalk", crop["color"])))
			size = 1.0
		elif growth < 0.5:
			color = sprout
			size = lerpf(0.3, 0.55, growth * 2.0)
		else:
			color = sprout.lerp(growing, (growth - 0.5) * 2.0)
			size = lerpf(0.6, 0.9, (growth - 0.5) * 2.0)
		var ear: Color = Color.html(str(crop["color"]))
		for r in _ridges:
			var z: float = c.y - PLOT_SIZE * 0.45 + step * (float(r) + 0.5)
			for k in _per_ridge:
				# Fixed jitter per spot (no random: the field must not flicker every second).
				var h: int = (i * 131 + r * 31 + k * 17) % 97
				var jx: float = (float(h % 7) - 3.0) * 0.012
				var jz: float = (float(h % 5) - 2.0) * 0.02
				var x: float = c.x - PLOT_SIZE * 0.4 + PLOT_SIZE * 0.8 * (float(k) + 0.5) / float(_per_ridge)
				var s: float = size * (0.85 + float(h % 4) * 0.06)
				var at := Vector3(x + jx, 0.19, z + jz)
				_stalk_t.append(Transform3D(Basis(Vector3.UP, float(h)) * Basis.from_scale(Vector3(s, s, s)), at))
				_stalk_c.append(color)
				if stage == 2:
					_ear_t.append(Transform3D(Basis(Vector3.RIGHT, (float(h % 3) - 1.0) * 0.15), at + Vector3(0.0, 0.56 * s, 0.0)))
					_ear_c.append(ear)
	_fill(_soil, _soil_t, _soil_c)
	_fill(_stalks, _stalk_t, _stalk_c)
	_fill(_ears, _ear_t, _ear_c)


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


func _fill(node: MultiMeshInstance3D, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var multi: MultiMesh = node.multimesh
	if multi.instance_count != transforms.size():
		multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
