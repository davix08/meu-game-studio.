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
	var bark: Color = look.color("colors", "bark")
	var bark_dark: Color = look.color("colors", "bark_dark")
	mb.add_cone(Vector3.ZERO, 0.2, 0.11, 1.05, bark_dark, bark, 7)
	# Roots and two branches into the crown.
	for k in 3:
		var a: float = float(k) * TAU / 3.0 + 0.4
		mb.add_cone(Vector3(cos(a) * 0.12, 0.0, sin(a) * 0.12), 0.08, 0.02, 0.22, bark_dark, bark, 4)
	mb.add_cone(Vector3(0.05, 0.85, 0.0), 0.06, 0.03, 0.45, bark, bark, 4)
	# Round crown of overlapping blobs: darker below, sunlit on top (the painted diorama trees).
	mb.add_ellipsoid(Vector3(0.0, 1.5, 0.0), Vector3(0.95, 0.75, 0.95), dark, mid, 9, 6, true)
	mb.add_ellipsoid(Vector3(0.55, 1.35, 0.3), Vector3(0.58, 0.5, 0.58), dark, mid, 8, 5, true)
	mb.add_ellipsoid(Vector3(-0.5, 1.4, -0.3), Vector3(0.6, 0.52, 0.6), dark, mid, 8, 5, true)
	mb.add_ellipsoid(Vector3(-0.2, 1.35, 0.55), Vector3(0.5, 0.45, 0.5), dark, mid, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.1, 2.0, 0.05), Vector3(0.62, 0.48, 0.62), mid, light, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.35, 1.8, -0.35), Vector3(0.42, 0.36, 0.42), mid, light, 7, 5, true)
	return mb.build()


## A pine of four drooping tiers, about 2.8 m tall.
static func pine(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "pine_dark")
	var light: Color = look.color("colors", "pine_light")
	mb.add_cone(Vector3.ZERO, 0.15, 0.1, 0.7, look.color("colors", "bark_dark"), look.color("colors", "bark"), 6)
	for k in 4:
		var y: float = 0.4 + float(k) * 0.52
		var r: float = 0.95 - float(k) * 0.2
		# Each tier: a skirt that flares out and down, then the cone up to the next tier.
		mb.add_cone(Vector3(0.0, y - 0.12, 0.0), r * 1.05, r * 0.75, 0.16, dark.darkened(0.15), dark, 9)
		mb.add_cone(Vector3(0.0, y + 0.04, 0.0), r * 0.78, 0.0, 0.95 - float(k) * 0.1, dark, light, 9)
	return mb.build()


## A round bush with red berries.
static func bush(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "bush_dark")
	var light: Color = look.color("colors", "bush_light")
	var berry: Color = look.color("colors", "berry")
	mb.add_ellipsoid(Vector3(0.0, 0.3, 0.0), Vector3(0.5, 0.38, 0.5), dark, light, 8, 5, true)
	mb.add_ellipsoid(Vector3(0.32, 0.25, 0.2), Vector3(0.34, 0.28, 0.32), dark, light, 7, 4, true)
	mb.add_ellipsoid(Vector3(-0.3, 0.22, -0.18), Vector3(0.32, 0.26, 0.3), dark, light, 7, 4, true)
	for spot: Vector3 in [Vector3(0.2, 0.6, 0.25), Vector3(-0.3, 0.55, 0.12), Vector3(0.05, 0.63, -0.25)]:
		mb.add_ellipsoid(spot, Vector3(0.07, 0.07, 0.07), berry, berry, 5, 3, true)
	return mb.build()


## A rounded gray rock (the painted shader adds moss on its top).
static func rock(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "rock_dark")
	var light: Color = look.color("colors", "rock_light")
	mb.add_ellipsoid(Vector3(0.0, 0.22, 0.0), Vector3(0.58, 0.4, 0.5), dark, light, 7, 4, false)
	mb.add_ellipsoid(Vector3(0.38, 0.14, 0.22), Vector3(0.32, 0.22, 0.3), dark, light, 6, 3, false)
	mb.add_ellipsoid(Vector3(-0.3, 0.1, 0.28), Vector3(0.22, 0.15, 0.2), dark, light, 6, 3, false)
	return mb.build()


## A fallen log lying along x, with light cut ends and a broken branch (decoration).
static func fallen_log(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var bark: Color = look.color("colors", "bark")
	var bark_dark: Color = look.color("colors", "bark_dark")
	var end: Color = look.color("colors", "wood_end")
	var ring: Color = look.color("colors", "wood_ring")
	var basis := Basis(Vector3.BACK, -PI * 0.5)
	var at := Vector3(-0.8, 0.2, 0.0)
	var mb_log := MeshBuilder.new()
	mb_log.add_cone(Vector3.ZERO, 0.2, 0.18, 1.6, bark_dark, bark, 8)
	mb_log.add_cone(Vector3(0.0, 1.6, 0.0), 0.18, 0.18, 0.002, end, end, 8, true)
	mb_log.add_cone(Vector3(0.0, -0.002, 0.0), 0.2, 0.2, 0.002, end, end, 8, false, true)
	mb_log.add_cone(Vector3(0.0, -0.006, 0.0), 0.1, 0.1, 0.004, ring, ring, 8, false, true)
	mb.append_transformed(mb_log, Transform3D(basis, at))
	mb.add_cone(Vector3(0.2, 0.3, 0.05), 0.05, 0.02, 0.35, bark_dark, bark, 4)
	return mb.build()


## A cut tree stump with a light top and roots (decoration).
static func stump(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var bark: Color = look.color("colors", "bark")
	var bark_dark: Color = look.color("colors", "bark_dark")
	mb.add_cone(Vector3.ZERO, 0.28, 0.22, 0.38, bark_dark, bark, 8)
	mb.add_cone(Vector3(0.0, 0.38, 0.0), 0.22, 0.22, 0.002, look.color("colors", "wood_end"), look.color("colors", "wood_end"), 8, true)
	mb.add_cone(Vector3(0.0, 0.382, 0.0), 0.1, 0.1, 0.004, look.color("colors", "wood_ring"), look.color("colors", "wood_ring"), 8, true)
	for k in 4:
		var a: float = float(k) * TAU / 4.0 + 0.3
		mb.add_cone(Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2), 0.1, 0.02, 0.16, bark_dark, bark, 4)
	return mb.build()


## A clump of tall shore grass (about 1 m): long leaning blades in three greens, a few with a
## brown seed head on top, like the reeds around a pond (2026-11-22, lakeside picture).
static func tall_grass(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var greens: Array[Color] = [look.color("colors", "shore_grass_a"), look.color("colors", "shore_grass_b"), look.color("colors", "shore_grass_c")]
	var head: Color = look.color("colors", "reed_top")
	for k in 22:
		var a: float = float(k) * 2.39996
		var r: float = 0.04 + 0.26 * fmod(float(k) * 0.618, 1.0)
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var out := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-out.z, 0.0, out.x)
		var h: float = 0.55 + 0.45 * fmod(float(k) * 0.37, 1.0)
		var tip: Vector3 = base + out * (0.12 + 0.18 * fmod(float(k) * 0.29, 1.0)) + Vector3(0.0, h, 0.0)
		var mid: Vector3 = base.lerp(tip, 0.5) + Vector3(0.0, 0.04, 0.0)
		var c: Color = greens[k % 3]
		mb.add_triangle(base - side * 0.035, base + side * 0.035, mid, c.darkened(0.15))
		mb.add_triangle(mid - side * 0.025, mid + side * 0.025, tip, c)
		mb.add_triangle(base - side * 0.035, mid + side * 0.025, mid - side * 0.025, c.darkened(0.1))
		if k % 4 == 0:
			mb.add_cone(tip - Vector3(0.0, 0.02, 0.0), 0.006, 0.006, 0.22, c, c, 3)
			mb.add_ellipsoid(tip + Vector3(0.0, 0.26, 0.0), Vector3(0.03, 0.08, 0.03), head.darkened(0.2), head, 5, 3, true)
	return mb.build()


## A few small pebbles lying together on the shore.
static func pebbles(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var dark: Color = look.color("colors", "pebble_dark")
	var light: Color = look.color("colors", "pebble_light")
	for p: Vector3 in [Vector3(0.0, 0.0, 0.0), Vector3(0.22, 0.0, 0.1), Vector3(-0.15, 0.0, 0.18), Vector3(0.05, 0.0, -0.2)]:
		var size: float = 0.07 + 0.05 * fmod(absf(p.x * 7.0 + p.z * 13.0), 1.0)
		mb.add_ellipsoid(p + Vector3(0.0, size * 0.4, 0.0), Vector3(size * 1.3, size * 0.7, size), dark, light, 6, 3, false)
	return mb.build()


## A tiny white bloom (tinted per instance).
static func flower(_look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(0.0, 0.13, 0.0), Vector3(0.1, 0.06, 0.1), Color.WHITE, Color.WHITE, 6, 4, true)
	return mb.build()


## A grass tuft of seven blades in three greens.
static func tuft(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var names: Array[String] = ["tuft_c", "tuft_a", "tuft_b"]
	for k in 7:
		var angle: float = float(k) * TAU / 7.0 + 0.4
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-dir.z, 0.0, dir.x)
		var base: Vector3 = dir * 0.05
		var tip: Vector3 = base + dir * (0.08 + 0.03 * float(k % 3)) + Vector3(0.0, 0.26 + 0.05 * float(k % 3), 0.0)
		var color: Color = look.color("colors", names[k % 3])
		mb.add_triangle(base - side * 0.045, base + side * 0.045, tip, color)
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
static func chimney_top(_look: WorldLook) -> Vector3:
	return VoxelModels.farmhouse_chimney(WorldGrid.HOUSE)



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
