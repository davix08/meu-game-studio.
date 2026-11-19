class_name LakeProps
extends Node3D
## Places everything that stands on the terrain: the house, pier, bridge, lantern and boat
## (one mesh each) and the repeated props (trees, pines, bushes, rocks, flowers, grass tufts,
## reeds, lily pads) as one MultiMeshInstance3D per kind, so each kind is a single draw call.
## Positions come from the [WorldGrid] placements, so the 3D map matches the 2D one.
##
## Story 002 (design/game-brief.md, MVP feature 9). Story 009: on the bigger map every kind is
## split into square chunks (town.chunk_size blocks) so the camera culls what is off screen, and the
## small decorations (tufts, flowers, reeds, lilies) stop drawing beyond town.small_prop_range.
## Story 005: big boulders along the river, and one tree in five gets a warm autumn tint.

var _grid: WorldGrid
var _terrain: LakeTerrain
var _look: WorldLook
var _material: StandardMaterial3D
## Placement index -> [MultiMesh, instance index, Transform3D], for trees and rocks that can be
## cut (2026-11-19 farm map).
var _where: Dictionary = {}
var _ids: Array[int] = []


## Builds all props for [param grid], standing on [param terrain], styled by [param look].
func build(grid: WorldGrid, terrain: LakeTerrain, look: WorldLook) -> void:
	_grid = grid
	_terrain = terrain
	_look = look
	_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_add_static(PropMeshes.wood(look, grid))
	if look.integer("boat", "enabled") == 1:
		_add_static(PropMeshes.boat(look))
	_scatter(&"tree", PropMeshes.tree(look))
	_scatter(&"pine", PropMeshes.pine(look))
	_scatter(&"bush", PropMeshes.bush(look))
	_scatter(&"rock", PropMeshes.rock(look))
	_scatter(&"boulder", PropMeshes.rock(look))
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
	_ids.clear()
	for index in _grid.placements.size():
		var p: WorldGrid.Placement = _grid.placements[index]
		if p.kind != kind:
			continue
		_ids.append(index if p.choppable else -1)
		var y: float = _terrain.ground_height_at(p.pos.x, p.pos.y)
		if kind == &"lily":
			y = _look.num("terrain", "water_level") + _look.num("lily", "height_above_water")
		transforms.append(_instance_transform(group, p.cell, Vector3(p.pos.x, y, p.pos.y)))
		var tint: float = lerpf(_look.num("props", "tint_min"), _look.num("props", "tint_max"), WorldGrid.hash2(p.cell.x, p.cell.y, 14))
		var color := Color(tint, tint, tint, 1.0)
		if kind == &"tree" and WorldGrid.hash2(p.cell.x, p.cell.y, 16) > 0.8:
			color = Color(tint * 1.12, tint * 0.86, tint * 0.5, 1.0)
		colors.append(color)
	_add_multimesh(mesh, transforms, colors, _look.integer(group, "shadow") == 1)
	_ids.clear()


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
	var chunk: float = _look.num("town", "chunk_size")
	var groups: Dictionary = {}
	for i in transforms.size():
		var key := Vector2i(floori(transforms[i].origin.x / chunk), floori(transforms[i].origin.z / chunk))
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(i)
	var small: bool = not casts_shadow
	for key: Variant in groups:
		var part_t: Array[Transform3D] = []
		var part_c: Array[Color] = []
		var part_ids: Array[int] = []
		for i: Variant in groups[key]:
			part_t.append(transforms[int(i)])
			part_c.append(colors[int(i)])
			part_ids.append(_ids[int(i)] if int(i) < _ids.size() else -1)
		var multi: MultiMesh = _add_chunk(mesh, part_t, part_c, casts_shadow, small)
		for k in part_ids.size():
			if part_ids[k] >= 0:
				_where[part_ids[k]] = [multi, k, part_t[k]]


func _add_chunk(mesh: ArrayMesh, transforms: Array[Transform3D], colors: Array[Color], casts_shadow: bool, small: bool) -> MultiMesh:
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
	if small:
		node.visibility_range_end = _look.num("town", "small_prop_range")
	add_child(node)
	return multi


## Hides (cut) or shows again (grown back) the tree or rock of placement [param index].
func set_cut(index: int, cut: bool) -> void:
	if not _where.has(index):
		return
	var entry: Array = _where[index]
	var multi: MultiMesh = entry[0]
	var base: Transform3D = entry[2]
	multi.set_instance_transform(int(entry[1]), Transform3D(base.basis.scaled(Vector3.ONE * 0.001), base.origin) if cut else base)


## Indices of the placements that can be cut or broken.
func cuttable() -> Array[int]:
	var out: Array[int] = []
	for index: Variant in _where:
		out.append(int(index))
	return out
