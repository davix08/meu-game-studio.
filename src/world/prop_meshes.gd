class_name PropMeshes
extends RefCounted
## Builds the simple stylized models of the lake world from basic shapes, colored from
## world_look.json. Repeated props (tree, pine, bush, rock, flower, tuft, reed, lily) are built
## at natural size around the origin and placed with MultiMesh; the house, the pier and bridge
## and the boat are built directly in world coordinates (blocks = meters).
##
## Story 002 (design/game-brief.md, MVP feature 9). Sub-shape proportions are structural
## literals; colors, roof, wall and deck sizes come from the data file.


## A round deciduous tree, about 2.5 m tall.
static func tree(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "leaf_dark")
	var mid: Color = look.color("colors", "leaf_mid")
	var light: Color = look.color("colors", "leaf_light")
	mb.add_cone(Vector3.ZERO, 0.17, 0.11, 1.0, look.color("colors", "trunk_dark"), look.color("colors", "trunk"), 6)
	mb.add_ellipsoid(Vector3(0.0, 1.55, 0.0), Vector3(0.95, 0.8, 0.95), dark, mid, 8, 6, true)
	mb.add_ellipsoid(Vector3(0.5, 1.3, 0.25), Vector3(0.6, 0.5, 0.6), dark, mid, 7, 5, true)
	mb.add_ellipsoid(Vector3(-0.45, 1.4, -0.3), Vector3(0.6, 0.5, 0.6), dark, mid, 7, 5, true)
	mb.add_ellipsoid(Vector3(0.0, 2.05, 0.0), Vector3(0.55, 0.4, 0.55), mid, light, 7, 5, true)
	return mb.build()


## A three-tier pine, about 2.6 m tall.
static func pine(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "pine_dark")
	var light: Color = look.color("colors", "pine_light")
	mb.add_cone(Vector3.ZERO, 0.14, 0.1, 0.7, look.color("colors", "trunk_dark"), look.color("colors", "trunk"), 6)
	for k in 3:
		mb.add_cone(Vector3(0.0, 0.45 + float(k) * 0.62, 0.0), 0.9 - float(k) * 0.2, 0.0, 1.15 - float(k) * 0.1, dark, light, 8)
	return mb.build()


## A round bush with red berries.
static func bush(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "bush_dark")
	var light: Color = look.color("colors", "bush_light")
	var berry: Color = look.color("colors", "berry")
	mb.add_ellipsoid(Vector3(0.0, 0.3, 0.0), Vector3(0.5, 0.38, 0.5), dark, light, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.3, 0.25, 0.2), Vector3(0.32, 0.28, 0.32), dark, light, 7, 4, true)
	for spot: Vector3 in [Vector3(0.2, 0.6, 0.25), Vector3(-0.3, 0.6, 0.12), Vector3(0.05, 0.63, -0.25)]:
		mb.add_ellipsoid(spot, Vector3(0.07, 0.07, 0.07), berry, berry, 5, 3, true)
	return mb.build()


## A faceted gray rock.
static func rock(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "rock_dark")
	var light: Color = look.color("colors", "rock_light")
	mb.add_ellipsoid(Vector3(0.0, 0.25, 0.0), Vector3(0.55, 0.38, 0.5), dark, light, 6, 4, false)
	mb.add_ellipsoid(Vector3(0.35, 0.15, 0.2), Vector3(0.3, 0.2, 0.28), dark, light, 6, 3, false)
	return mb.build()


## A tiny white bloom (tinted per instance).
static func flower(_look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(0.0, 0.13, 0.0), Vector3(0.1, 0.06, 0.1), Color.WHITE, Color.WHITE, 6, 4, true)
	return mb.build()


## A grass tuft made of four crossed blades.
static func tuft(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	for k in 4:
		var angle: float = float(k) * PI * 0.5 + 0.4
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-dir.z, 0.0, dir.x)
		var base: Vector3 = dir * 0.04
		var tip: Vector3 = base + dir * 0.07 + Vector3(0.0, 0.3 + 0.05 * float(k), 0.0)
		var color: Color = look.color("colors", "tuft_a" if k % 2 == 0 else "tuft_b")
		mb.add_triangle(base - side * 0.05, base + side * 0.05, tip, color)
	return mb.build()


## Three reeds, two with brown cattail tops.
static func reed(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var stalk: Color = look.color("colors", "reed")
	var top: Color = look.color("colors", "reed_top")
	var spots: Array[Vector3] = [Vector3(0.0, 1.0, 0.0), Vector3(0.12, 0.85, 0.05), Vector3(-0.1, 0.9, 0.08)]
	for k in spots.size():
		var spot: Vector3 = spots[k]
		mb.add_cone(Vector3(spot.x, 0.0, spot.z), 0.03, 0.015, spot.y, stalk, stalk, 4)
		if k < 2:
			mb.add_ellipsoid(Vector3(spot.x, spot.y, spot.z), Vector3(0.045, 0.11, 0.045), top, top, 5, 4, true)
	return mb.build()


## A flat lily pad.
static func lily(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var pad: Color = look.color("colors", "lily")
	mb.add_cone(Vector3.ZERO, 0.3, 0.3, 0.02, pad, pad, 10, true)
	return mb.build()


## Where the chimney smoke starts, in world coordinates.
static func chimney_top(look: WorldLook) -> Vector3:
	var x1: float = float(WorldGrid.HOUSE.end.x)
	var zc: float = float(WorldGrid.HOUSE.position.y) + float(WorldGrid.HOUSE.size.y) * 0.5
	var ridge_y: float = look.num("house", "wall_height") + look.num("house", "roof_rise")
	return Vector3(x1 - 1.0, ridge_y + 0.78, zc)



## The pier planks and posts, the bridge planks and rails, and the lantern at the end of the
## pier, built from the DOCK and BRIDGE blocks of the grid, in world coordinates.
static func wood(look: WorldLook, grid: WorldGrid) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var deck: float = look.num("wood", "deck_height")
	var bottom: float = look.num("wood", "post_bottom")
	var rail_h: float = look.num("wood", "rail_height")
	var plank_a: Color = look.color("colors", "wood_a")
	var plank_b: Color = look.color("colors", "wood_b")
	var post_color: Color = look.color("colors", "wood_dark")
	for cy in WorldGrid.HEIGHT:
		for cx in WorldGrid.WIDTH:
			var tile: int = grid.tile_at(cx, cy)
			if tile != WorldGrid.Tile.DOCK and tile != WorldGrid.Tile.BRIDGE:
				continue
			var is_dock: bool = tile == WorldGrid.Tile.DOCK
			for k in 3:
				var color: Color = plank_a if (cx + cy * 3 + k) % 2 == 0 else plank_b
				var along: float = (float(k) + 0.5) / 3.0
				if is_dock:
					mb.add_box(Vector3(cx + 0.5, deck - 0.035, cy + along), Vector3(1.0, 0.07, 0.31), color)
				else:
					mb.add_box(Vector3(cx + along, deck - 0.035, cy + 0.5), Vector3(0.31, 0.07, 1.0), color)
			if is_dock:
				for side: int in [-1, 1]:
					if _is_wood(grid, cx + side, cy):
						continue
					var post_x: float = cx + 0.5 + float(side) * 0.42
					if cy % 2 == 0:
						_add_post(mb, post_x, cy + 0.12, deck + 0.42, bottom, post_color)
					if not _is_wood(grid, cx, cy + 1):
						_add_post(mb, post_x, cy + 0.88, deck + 0.42, bottom, post_color)
			else:
				for side: int in [-1, 1]:
					if _is_wood(grid, cx, cy + side):
						continue
					var rail_z: float = cy + 0.5 + float(side) * 0.45
					_add_post(mb, cx + 0.5, rail_z, deck + rail_h + 0.1, bottom, post_color)
					mb.add_box(Vector3(cx + 0.5, deck + rail_h, rail_z), Vector3(1.0, 0.07, 0.07), post_color)

	# Lantern post at the end of the pier.
	var lamp: Vector2 = WorldGrid.LANTERN
	mb.add_box(Vector3(lamp.x, deck + 0.05, lamp.y), Vector3(0.16, 0.1, 0.16), post_color)
	mb.add_box(Vector3(lamp.x, deck + 0.85, lamp.y), Vector3(0.09, 1.7, 0.09), post_color)
	mb.add_box(Vector3(lamp.x, deck + 1.84, lamp.y), Vector3(0.22, 0.28, 0.22), look.color("colors", "lantern_glass"))
	mb.add_cone(Vector3(lamp.x, deck + 1.98, lamp.y), 0.2, 0.0, 0.16, post_color, post_color, 4)
	return mb.build()


## A small rowboat moored beside the pier (optional decoration), in world coordinates.
static func boat(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var cx: float = look.num("boat", "x")
	var cz: float = look.num("boat", "z")
	var y: float = look.num("terrain", "water_level") + 0.05
	var hull: Color = look.color("colors", "boat_hull")
	var inner: Color = look.color("colors", "boat_inner")
	mb.add_ellipsoid(Vector3(cx, y, cz), Vector3(0.42, 0.22, 0.95), hull, hull, 10, 5, true)
	mb.add_ellipsoid(Vector3(cx, y, cz), Vector3(0.34, 0.24, 0.85), inner, inner, 10, 5, true)
	for dz: float in [-0.3, 0.3]:
		mb.add_box(Vector3(cx, y + 0.2, cz + dz), Vector3(0.7, 0.04, 0.16), hull)
	return mb.build()


static func _is_wood(grid: WorldGrid, cx: int, cy: int) -> bool:
	var tile: int = grid.tile_at(cx, cy)
	return tile == WorldGrid.Tile.DOCK or tile == WorldGrid.Tile.BRIDGE


static func _add_post(mb: MeshBuilder, x: float, z: float, top_y: float, bottom_y: float, color: Color) -> void:
	mb.add_box(Vector3(x, (top_y + bottom_y) * 0.5, z), Vector3(0.16, top_y - bottom_y, 0.16), color)
