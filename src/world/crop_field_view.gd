class_name CropFieldView
extends Node3D
## Draws the field plots of the real-time farm (2026-11-21): a soil square per bought plot
## inside the field lot, and the crop on it growing in three steps (sprout, half, ripe with its
## color on top), from [member GameState.crop_plots] and [Production]. Redrawn every second.
## Plot i sits at column i % cols, row i / cols of 2x2-block squares (town.field_plot_cols).
##
## Usage:
## [codeblock]
## var field := CropFieldView.new()
## add_child(field)
## field.setup(look, state, production)
## [/codeblock]

var _look: WorldLook
var _state: GameState
var _prod: Production
var _soil: MultiMeshInstance3D
var _leaves: MultiMeshInstance3D
var _tops: MultiMeshInstance3D
var _material: StandardMaterial3D
var _timer: float = 0.0


## Builds the three layers.
func setup(look: WorldLook, state: GameState, production: Production) -> void:
	_look = look
	_state = state
	_prod = production
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	var soil := MeshBuilder.new()
	soil.add_box(Vector3(0.0, 0.08, 0.0), Vector3(1.8, 0.16, 1.8), Color.WHITE)
	_soil = _layer(soil.build())
	var leaf := MeshBuilder.new()
	leaf.add_cone(Vector3.ZERO, 0.08, 0.02, 0.45, Color(0.85, 0.95, 0.8), Color.WHITE, 5, true)
	leaf.add_ellipsoid(Vector3(0.0, 0.3, 0.0), Vector3(0.16, 0.12, 0.16), Color(0.85, 0.95, 0.8), Color.WHITE, 6, 4, true)
	_leaves = _layer(leaf.build())
	var top := MeshBuilder.new()
	top.add_ellipsoid(Vector3.ZERO, Vector3(0.1, 0.13, 0.1), Color.WHITE, Color.WHITE, 6, 4, true)
	_tops = _layer(top.build())
	state.town_changed.connect(refresh)
	refresh()


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


## Redraws the soil and the crops.
func refresh() -> void:
	var soil_t: Array[Transform3D] = []
	var soil_c: Array[Color] = []
	var leaf_t: Array[Transform3D] = []
	var leaf_c: Array[Color] = []
	var top_t: Array[Transform3D] = []
	var top_c: Array[Color] = []
	var leaf_color: Color = _look.color("town", "crop_leaf")
	for i in _state.crop_plots.size():
		var c: Vector2 = plot_center(i)
		soil_t.append(Transform3D(Basis.IDENTITY, Vector3(c.x, 0.0, c.y)))
		soil_c.append(_look.color("town", "crop_soil_wet"))
		var stage: int = _prod.plot_stage(i)
		if stage == 0:
			continue
		var crop: Dictionary = _prod.crop(str(_state.crop_plots[i]["crop"]))
		var growth: float = _prod.plot_growth(i)
		var size: float = lerpf(0.35, 1.0, growth)
		for k in 4:
			var off := Vector2(-0.45 + float(k % 2) * 0.9, -0.45 + float(k / 2) * 0.9)
			var at := Vector3(c.x + off.x, 0.16, c.y + off.y)
			leaf_t.append(Transform3D(Basis(Vector3.UP, float(k) * 1.3) * Basis.from_scale(Vector3.ONE * size), at))
			leaf_c.append(leaf_color)
			if stage == 2:
				top_t.append(Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.42, 0.0)))
				top_c.append(Color.html(str(crop["color"])))
	_fill(_soil, soil_t, soil_c)
	_fill(_leaves, leaf_t, leaf_c)
	_fill(_tops, top_t, top_c)


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
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
