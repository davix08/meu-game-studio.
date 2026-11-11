class_name LakeTerrain
extends MeshInstance3D
## The ground of the lake world as ONE mesh with vertex colors, built from the [WorldGrid]:
## grass (with color variation), dirt paths, sand, the lake bed (darker where deeper) and the
## islands. Vertices sit every half block (center of a block = pure color, edge = blend of the
## two blocks, corner = blend of four), which gives soft margins between kinds. Land gets a
## light relief; the lake bed dips below the water level. A flat "skirt" quad around the map
## hides the void behind the border forest.
##
## Story 002 (design/game-brief.md, MVP feature 9). Draw calls: 2.
##
## Usage:
## [codeblock]
## var terrain := LakeTerrain.new()
## add_child(terrain)
## terrain.build(grid, look)
## var y: float = terrain.ground_height_at(10.5, 7.5)
## [/codeblock]

## Distance in meters between mesh vertices (two per block).
const STEP: float = 0.5

## Vertices per row (WIDTH * 2 + 1).
var cols: int = 0
## Vertices per column (HEIGHT * 2 + 1).
var rows: int = 0

var _grid: WorldGrid
var _heights: PackedFloat32Array = PackedFloat32Array()
var _deck_height: float = 0.0
var _grass_a: Color
var _grass_b: Color
var _grass_c: Color
var _dirt_a: Color
var _dirt_b: Color
var _sand: Color
var _shallow_bed: Color
var _deep_bed: Color
var _grass_variation: float = 0.5


## Builds the terrain mesh and the skirt from [param grid], colored and shaped by [param look].
func build(grid: WorldGrid, look: WorldLook) -> void:
	_grid = grid
	cols = WorldGrid.WIDTH * 2 + 1
	rows = WorldGrid.HEIGHT * 2 + 1
	_deck_height = look.num("wood", "deck_height")
	_grass_a = look.color("colors", "grass_a")
	_grass_b = look.color("colors", "grass_b")
	_grass_c = look.color("colors", "grass_c")
	_dirt_a = look.color("colors", "dirt_a")
	_dirt_b = look.color("colors", "dirt_b")
	_sand = look.color("colors", "sand")
	_shallow_bed = look.color("colors", "shallow_bed")
	_deep_bed = look.color("colors", "deep_bed")
	_grass_variation = look.num("terrain", "grass_variation")
	var land_h: float = look.num("terrain", "land_height")
	var shallow_h: float = look.num("terrain", "shallow_bed_height")
	var deep_h: float = look.num("terrain", "deep_bed_height")
	var relief: float = look.num("terrain", "relief_height")

	# Per-block color and base height.
	var cell_colors: PackedColorArray = PackedColorArray()
	var cell_heights: PackedFloat32Array = PackedFloat32Array()
	var cell_land: PackedByteArray = PackedByteArray()
	cell_colors.resize(WorldGrid.WIDTH * WorldGrid.HEIGHT)
	cell_heights.resize(WorldGrid.WIDTH * WorldGrid.HEIGHT)
	cell_land.resize(WorldGrid.WIDTH * WorldGrid.HEIGHT)
	for cy in WorldGrid.HEIGHT:
		for cx in WorldGrid.WIDTH:
			var tile: int = grid.tile_under(cx, cy)
			var i: int = cy * WorldGrid.WIDTH + cx
			cell_colors[i] = _cell_color(tile, cx, cy)
			if tile == WorldGrid.Tile.SHALLOW:
				cell_heights[i] = shallow_h
				cell_land[i] = 0
			elif tile == WorldGrid.Tile.DEEP:
				cell_heights[i] = deep_h
				cell_land[i] = 0
			else:
				cell_heights[i] = land_h
				cell_land[i] = 1

	# Vertex heights and colors: average of the (1, 2 or 4) blocks around each vertex.
	var vertices: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	vertices.resize(cols * rows)
	colors.resize(cols * rows)
	_heights.resize(cols * rows)
	for j in rows:
		for i in cols:
			var x_lo: int = ((i - 1) >> 1) if i % 2 == 1 else (i >> 1) - 1
			var x_hi: int = x_lo if i % 2 == 1 else x_lo + 1
			var y_lo: int = ((j - 1) >> 1) if j % 2 == 1 else (j >> 1) - 1
			var y_hi: int = y_lo if j % 2 == 1 else y_lo + 1
			var count: int = 0
			var land_count: int = 0
			var h_sum: float = 0.0
			var c_sum := Color(0.0, 0.0, 0.0, 1.0)
			for cy in range(y_lo, y_hi + 1):
				for cx in range(x_lo, x_hi + 1):
					if cx < 0 or cy < 0 or cx >= WorldGrid.WIDTH or cy >= WorldGrid.HEIGHT:
						continue
					var k: int = cy * WorldGrid.WIDTH + cx
					count += 1
					land_count += cell_land[k]
					h_sum += cell_heights[k]
					c_sum += cell_colors[k]
			var x: float = float(i) * STEP
			var z: float = float(j) * STEP
			var land_fraction: float = float(land_count) / float(count)
			var noise: float = 0.6 * sin(x * 0.31 + 1.7) * sin(z * 0.27 + 0.4) + 0.4 * sin(x * 0.83 - z * 0.61)
			var h: float = h_sum / float(count) + relief * noise * land_fraction
			var n: int = j * cols + i
			_heights[n] = h
			vertices[n] = Vector3(x, h, z)
			colors[n] = Color(c_sum.r / float(count), c_sum.g / float(count), c_sum.b / float(count), 1.0)

	# Normals from the height field, then triangles (two per half-block quad).
	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(cols * rows)
	for j in rows:
		for i in cols:
			var hl: float = _heights[j * cols + maxi(i - 1, 0)]
			var hr: float = _heights[j * cols + mini(i + 1, cols - 1)]
			var hu: float = _heights[maxi(j - 1, 0) * cols + i]
			var hd: float = _heights[mini(j + 1, rows - 1) * cols + i]
			normals[j * cols + i] = Vector3(hl - hr, 2.0 * STEP, hu - hd).normalized()
	var indices: PackedInt32Array = PackedInt32Array()
	for j in rows - 1:
		for i in cols - 1:
			var a: int = j * cols + i
			var b: int = a + 1
			var c: int = a + cols
			var d: int = c + 1
			indices.append(a)
			indices.append(b)
			indices.append(c)
			indices.append(b)
			indices.append(d)
			indices.append(c)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var ground := ArrayMesh.new()
	ground.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = ground
	var material: StandardMaterial3D = MeshBuilder.make_material(look.num("terrain", "roughness"))
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Skirt: four flat strips OUTSIDE the 48x34 grid (north, south, west, east) at the land
	# height, so nothing covers the interior (the lake bed stays visible under the water).
	var pad: float = look.num("terrain", "skirt_margin")
	var w: float = float(WorldGrid.WIDTH)
	var hgt: float = float(WorldGrid.HEIGHT)
	var skirt_color: Color = look.color("colors", "skirt")
	var skirt_builder := MeshBuilder.new()
	for strip: Rect2 in [Rect2(-pad, -pad, w + pad * 2.0, pad), Rect2(-pad, hgt, w + pad * 2.0, pad), Rect2(-pad, 0.0, pad, hgt), Rect2(w, 0.0, pad, hgt)]:
		var x0: float = strip.position.x
		var z0: float = strip.position.y
		var x1: float = strip.end.x
		var z1: float = strip.end.y
		skirt_builder.add_quad(Vector3(x0, land_h, z0), Vector3(x1, land_h, z0), Vector3(x1, land_h, z1), Vector3(x0, land_h, z1), skirt_color, Vector3.UP)
	var skirt := MeshInstance3D.new()
	skirt.mesh = skirt_builder.build()
	skirt.material_override = material
	skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skirt)


## Terrain height (meters) at a world position. Docks and bridges return the deck height.
func ground_height_at(x: float, z: float) -> float:
	var tile: int = _grid.tile_at(floori(x), floori(z))
	if tile == WorldGrid.Tile.DOCK or tile == WorldGrid.Tile.BRIDGE:
		return _deck_height
	var gx: float = clampf(x / STEP, 0.0, float(cols - 1) - 0.001)
	var gz: float = clampf(z / STEP, 0.0, float(rows - 1) - 0.001)
	var i: int = int(gx)
	var j: int = int(gz)
	var fx: float = gx - float(i)
	var fz: float = gz - float(j)
	var h00: float = _heights[j * cols + i]
	var h10: float = _heights[j * cols + i + 1]
	var h01: float = _heights[(j + 1) * cols + i]
	var h11: float = _heights[(j + 1) * cols + i + 1]
	return lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz)


## Height of the terrain mesh at vertex ([param i], [param j]); used by the water mesh.
func vertex_height(i: int, j: int) -> float:
	return _heights[j * cols + i]


func _cell_color(tile: int, cx: int, cy: int) -> Color:
	var noise: float = WorldGrid.hash2(cx, cy, 10)
	match tile:
		WorldGrid.Tile.DIRT:
			return _dirt_a.lerp(_dirt_b, noise)
		WorldGrid.Tile.SAND:
			return _sand.darkened(noise * 0.06)
		WorldGrid.Tile.SHALLOW:
			return _shallow_bed.darkened(noise * 0.08)
		WorldGrid.Tile.DEEP:
			return _deep_bed.darkened(noise * 0.08)
	# Grass and flower blocks: a slow patchwork plus per-block noise, dark -> main -> light.
	var patch: float = 0.5 + 0.35 * sin(float(cx) * 0.45 + sin(float(cy) * 0.37) * 1.7)
	var k: float = clampf(patch + (noise - 0.5) * _grass_variation, 0.0, 1.0)
	var low: Color = _grass_b.lerp(_grass_a, clampf(k * 2.0, 0.0, 1.0))
	return low.lerp(_grass_c, clampf(k * 2.0 - 1.0, 0.0, 1.0))
