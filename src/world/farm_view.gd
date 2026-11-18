class_name FarmView
extends Node3D
## Draws the farm plots (Story 015): a soil strip per plot (darker when watered) and the crops
## along it in three visible stages: sprout, growing, ripe (with the produce in the crop color).
## The first plots are the old garden beds of Story 004; the fields lot adds more once built.
## One MultiMesh per layer, rebuilt on [signal GameState.town_changed]. Never changes state.
##
## Usage:
## [codeblock]
## var farm := FarmView.new()
## add_child(farm)
## farm.setup(look, town_data, state)
## var spot: Vector2 = farm.anchor(0)
## [/codeblock]

const STAGE_SCALE: Array[float] = [0.0, 0.45, 0.75, 1.0]

## Number of plot lines (garden plus fields).
var plot_count: int = 0

var _look: WorldLook
var _town: TownData
var _state: GameState
var _lines: Array[Vector3] = []
var _garden_count: int = 0
var _material: StandardMaterial3D
var _soil: MultiMeshInstance3D
var _plants: MultiMeshInstance3D
var _produce: MultiMeshInstance3D


## Builds the layers and draws the current plots.
func setup(look: WorldLook, town: TownData, state: GameState) -> void:
	_look = look
	_town = town
	_state = state
	_garden_count = EstateMeshes.garden_beds(look).size()
	_lines = TownPlan.plot_lines(look, true)
	plot_count = _lines.size()
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	var soil_mb := MeshBuilder.new()
	soil_mb.add_box(Vector3.ZERO, Vector3.ONE, Color.WHITE)
	_soil = _layer(soil_mb.build())
	_plants = _layer(EstateMeshes.plant(look))
	var produce_mb := MeshBuilder.new()
	produce_mb.add_ellipsoid(Vector3(0.0, 0.08, 0.0), Vector3(0.09, 0.09, 0.09), Color.WHITE, Color.WHITE, 6, 4, true)
	_produce = _layer(produce_mb.build())
	state.town_changed.connect(refresh)
	refresh()


## True when plot [param i] can be worked now (garden plots always; field plots once built).
func usable(i: int) -> bool:
	return i < _garden_count or _state.is_built("campos")


## Where the player stands to work plot [param i] (meters, x z).
func anchor(i: int) -> Vector2:
	return TownPlan.plot_anchor(_look, _lines[i], i < _garden_count)


## Redraws soil, plants and produce from the state.
func refresh() -> void:
	var soil_t: Array[Transform3D] = []
	var soil_c: Array[Color] = []
	var plant_t: Array[Transform3D] = []
	var plant_c: Array[Color] = []
	var prod_t: Array[Transform3D] = []
	var prod_c: Array[Color] = []
	var lift: float = _look.num("estate", "ground_lift")
	var spacing: float = _look.num("estate", "plant_spacing")
	var dry: Color = _look.color("town", "crop_soil_dry")
	var wet: Color = _look.color("town", "crop_soil_wet")
	for i in _lines.size():
		if not usable(i) or i >= _state.plots.size():
			continue
		var line: Vector3 = _lines[i]
		var garden: bool = i < _garden_count
		var top: float = 0.16 + lift if garden else 0.18
		var plot: Dictionary = _state.plots[i]
		var length: float = line.z - line.x
		var thick: float = 0.03 if garden else top
		soil_t.append(Transform3D(Basis.from_scale(Vector3(length, thick, 0.42)), Vector3((line.x + line.z) * 0.5, top - thick * 0.5 + 0.005, line.y)))
		soil_c.append(wet if bool(plot["watered"]) else dry)
		var crop_id: String = str(plot["crop"])
		if crop_id == "":
			continue
		var stage: int = _stage(plot)
		var color: Color = Color.html(str(_town.crop(crop_id)["color"]))
		var count: int = int(length / spacing)
		for k in count:
			var x: float = line.x + (float(k) + 0.5) * spacing
			var size: float = STAGE_SCALE[stage] * lerpf(0.85, 1.15, WorldGrid.hash2(roundi(x * 4.0), i, 71))
			plant_t.append(Transform3D(Basis(Vector3.UP, WorldGrid.hash2(roundi(x * 4.0), i, 72) * TAU) * Basis.from_scale(Vector3.ONE * size), Vector3(x, top, line.y)))
			plant_c.append(Color.WHITE if stage == 3 else Color(0.85, 1.0, 0.8, 1.0))
			if stage == 3:
				prod_t.append(Transform3D(Basis.IDENTITY, Vector3(x, top + 0.12, line.y)))
				prod_c.append(color)
	_fill(_soil, soil_t, soil_c)
	_fill(_plants, plant_t, plant_c)
	_fill(_produce, prod_t, prod_c)


func _stage(plot: Dictionary) -> int:
	var days: int = int(plot["days"])
	if days >= int(_town.crop(str(plot["crop"]))["grow_days"]):
		return 3
	return 1 if days == 0 else 2


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
