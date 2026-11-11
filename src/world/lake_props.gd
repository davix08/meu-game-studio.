class_name LakeProps
extends Node3D
## Places everything that stands on the terrain: the house, pier, bridge, lantern and boat
## (one mesh each) and the repeated props (trees, pines, bushes, rocks, flowers, grass tufts,
## reeds, lily pads) as one MultiMeshInstance3D per kind, so each kind is a single draw call.
## Positions come from the [WorldGrid] placements, so the 3D map matches the 2D one.
##
## Story 002 (design/game-brief.md, MVP feature 9).

var _grid: WorldGrid
var _terrain: LakeTerrain
var _look: WorldLook
var _material: StandardMaterial3D


## Builds all props for [param grid], standing on [param terrain], styled by [param look].
func build(grid: WorldGrid, terrain: LakeTerrain, look: WorldLook) -> void:
	_grid = grid
	_terrain = terrain
	_look = look
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_add_static(PropMeshes.house(look))
	_add_static(PropMeshes.wood(look, grid))
	if look.integer("boat", "enabled") == 1:
		_add_static(PropMeshes.boat(look))
	_scatter(&"tree", PropMeshes.tree(look))
	_scatter(&"pine", PropMeshes.pine(look))
	_scatter(&"bush", PropMeshes.bush(look))
	_scatter(&"rock", PropMeshes.rock(look))
	_scatter(&"tuft", PropMeshes.tuft(look))
	_scatter(&"reed", PropMeshes.reed(look))
	_scatter(&"lily", PropMeshes.lily(look))
	_add_flowers()


func _add_static(mesh: ArrayMesh) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material
	add_child(node)


## Instances every placement of [param kind] with a hash-based yaw, size and tint.
func _scatter(kind: StringName, mesh: ArrayMesh) -> void:
	var group: String = String(kind)
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for p: WorldGrid.Placement in _grid.placements:
		if p.kind != kind:
			continue
		var y: float = _terrain.ground_height_at(p.pos.x, p.pos.y)
		if kind == &"lily":
			y = _look.num("terrain", "water_level") + _look.num("lily", "height_above_water")
		transforms.append(_instance_transform(group, p.cell, Vector3(p.pos.x, y, p.pos.y)))
		var tint: float = lerpf(_look.num("props", "tint_min"), _look.num("props", "tint_max"), WorldGrid.hash2(p.cell.x, p.cell.y, 14))
		colors.append(Color(tint, tint, tint, 1.0))
	_add_multimesh(mesh, transforms, colors, _look.integer(group, "shadow") == 1)


## Flowers: four per FLOWERS block (same hash rule as the 2D drawTile) plus one on each
## lily pad that has a flower.
func _add_flowers() -> void:
	var palette: Array[Color] = _look.color_list("flower", "palette")
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for cy in WorldGrid.HEIGHT:
		for cx in WorldGrid.WIDTH:
			if _grid.tile_at(cx, cy) != WorldGrid.Tile.FLOWERS:
				continue
			for k in 4:
				var h: float = WorldGrid.hash2(cx, cy, 20 + k)
				var px: float = 2.0 + float(int(h * 1000.0) % 12)
				var py: float = 2.0 + float(int(h * 7777.0) % 12)
				var x: float = float(cx) + px / WorldGrid.PIXELS_PER_BLOCK
				var z: float = float(cy) + py / WorldGrid.PIXELS_PER_BLOCK
				transforms.append(_instance_transform("flower", Vector2i(cx * 4 + k, cy), Vector3(x, _terrain.ground_height_at(x, z), z)))
				colors.append(palette[int(h * 13.0) % palette.size()])
	var lily_y: float = _look.num("terrain", "water_level") + _look.num("lily", "height_above_water")
	for p: WorldGrid.Placement in _grid.placements:
		if p.kind == &"lily" and p.flag:
			transforms.append(_instance_transform("flower", p.cell, Vector3(p.pos.x, lily_y, p.pos.y)))
			colors.append(_look.color("flower", "lily_flower_color"))
	_add_multimesh(PropMeshes.flower(_look), transforms, colors, false)


## A transform with a hash-based yaw and size from the [param group] ranges of the data file.
func _instance_transform(group: String, cell: Vector2i, origin: Vector3) -> Transform3D:
	var size: float = lerpf(_look.num(group, "scale_min"), _look.num(group, "scale_max"), WorldGrid.hash2(cell.x, cell.y, 13))
	var tall: float = lerpf(_look.num(group, "height_min"), _look.num(group, "height_max"), WorldGrid.hash2(cell.x, cell.y, 15))
	var yaw: float = WorldGrid.hash2(cell.x, cell.y, 12) * TAU
	var rot: Basis = Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(size, size * tall, size))
	return Transform3D(rot, origin)


func _add_multimesh(mesh: ArrayMesh, transforms: Array[Transform3D], colors: Array[Color], casts_shadow: bool) -> void:
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
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
