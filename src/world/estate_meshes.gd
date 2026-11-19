class_name EstateMeshes
extends RefCounted
## Builds the models of the fishing house, the farm and the village (Story 004,
## design/game-brief.md, MVP feature 11) from boxes, cones, ellipsoids and quads, in world
## coordinates (1 block = 1 m, x east, z south, y up). The camera sees the south and east faces,
## so every front looks that way. Positions (grid cells), counts and colors come from the
## "estate" group of world_look.json; the internal proportions of each model are literals.
##
## Everything static goes into one mesh ([method build_static]); the windows and lamp glass go
## into a second builder so they can glow; repeated pieces are small meshes built at the origin
## for MultiMesh.

const GROUP: String = "estate"


## The cell rectangle stored as [param prefix]_x, _y, _w and _h in the estate data group.
static func cell_rect(look: WorldLook, prefix: String) -> Rect2i:
	return Rect2i(look.integer(GROUP, prefix + "_x"), look.integer(GROUP, prefix + "_y"), look.integer(GROUP, prefix + "_w"), look.integer(GROUP, prefix + "_h"))


## The garden bed lines as (x_start, z, x_end).
static func garden_beds(look: WorldLook) -> Array[Vector3]:
	var g: Rect2i = cell_rect(look, "garden")
	var rows: int = look.integer(GROUP, "garden_rows")
	var span: float = float(g.size.y) - 1.0
	var out: Array[Vector3] = []
	for i in rows:
		var z: float = float(g.position.y) + 0.5 + (float(i) + 0.5) * span / float(rows)
		out.append(Vector3(float(g.position.x) + 0.5, z, float(g.end.x) - look.num(GROUP, "garden_strip")))
	return out


## The center (x, z) of the free strip of the garden, where the scarecrow and the crate stand.
static func garden_strip_center(look: WorldLook) -> Vector2:
	var g: Rect2i = cell_rect(look, "garden")
	return Vector2(float(g.end.x) - look.num(GROUP, "garden_strip") * 0.5, float(g.position.y) + float(g.size.y) * 0.5)


## Builds the static estate (house, shed, tractor body, garden soil and scarecrow, coop, water
## tower, windmill tower, fish shop, notice board, bench, lamp posts). The glass of windows and
## lamps is added to [param glass].
static func build_static(look: WorldLook, glass: MeshBuilder) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var parts: Array = parts_of(look)
	if parts.has("house"):
		_house(mb, look, glass)
	if parts.has("shed"):
		_shed(mb, look)
	if parts.has("tractor"):
		_tractor(mb, look)
	if parts.has("garden"):
		_garden(mb, look)
	if parts.has("pen"):
		_coop(mb, look)
	if parts.has("tower"):
		_tower(mb, look)
	if parts.has("mill"):
		_mill_tower(mb, look)
	if parts.has("shop"):
		_shop(mb, look, glass)
	if parts.has("bench") or parts.has("board"):
		_board_and_bench(mb, look)
	if parts.has("lamps"):
		_lamps(mb, look, glass)
	return mb.build()


## The estate pieces this map shows (estate.parts in world_look.json; all of them when absent).
## Names: house, shed, tractor, garden, pen, tower, mill, shop, board, bench, lamps.
static func parts_of(look: WorldLook) -> Array:
	if look.has(GROUP, "parts"):
		return look.raw(GROUP, "parts")
	return ["house", "shed", "tractor", "garden", "pen", "tower", "mill", "shop", "board", "bench", "lamps"]


## One fence module along x, 1 m long, centered on the origin (a post at each end).
static func fence_module(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var pickets: Color = look.color("colors", "wood_b")
	var rails: Color = look.color("colors", "wood_a")
	var posts: Color = look.color("colors", "wall_trim")
	for k in 4:
		_box(mb, -0.44 + float(k) * 0.25, 0.0, 0.01, -0.32 + float(k) * 0.25, 0.7, 0.05, pickets)
	for ry: float in [0.22, 0.5]:
		_box(mb, -0.5, ry, -0.03, 0.5, ry + 0.08, 0.01, rails)
	for px: float in [-0.5, 0.5]:
		_box(mb, px - 0.06, 0.0, -0.06, px + 0.06, 0.88, 0.06, posts)
		_box(mb, px - 0.08, 0.88, -0.08, px + 0.08, 0.92, 0.08, rails)
	return mb.build()


## A leafy crop plant (about 0.35 m tall) for the garden beds.
static func plant(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var a: Color = look.color(GROUP, "plant_a")
	var b: Color = look.color(GROUP, "plant_b")
	mb.add_ellipsoid(Vector3(0.0, 0.14, 0.0), Vector3(0.14, 0.13, 0.14), a, b, 6, 4, true)
	mb.add_ellipsoid(Vector3(0.09, 0.1, 0.05), Vector3(0.1, 0.09, 0.1), a, b, 5, 3, true)
	mb.add_ellipsoid(Vector3(-0.08, 0.1, -0.06), Vector3(0.1, 0.09, 0.1), a, b, 5, 3, true)
	mb.add_ellipsoid(Vector3(0.0, 0.3, 0.0), Vector3(0.07, 0.07, 0.07), b, b, 5, 3, true)
	return mb.build()


## An open wooden crate (0.45 m) with [param content_key] colored goods on top.
static func crate(look: WorldLook, content_key: String) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var wood: Color = look.color("colors", "wood_a")
	var dark: Color = look.color("colors", "wood_dark")
	var content: Color = look.color(GROUP, content_key)
	_box(mb, -0.22, 0.0, -0.22, 0.22, 0.34, 0.22, wood)
	_box(mb, -0.2, 0.34, -0.2, 0.2, 0.36, 0.2, dark)
	for cx: float in [-0.22, 0.22]:
		for cz: float in [-0.22, 0.22]:
			_box(mb, cx - 0.03, 0.0, cz - 0.03, cx + 0.03, 0.4, cz + 0.03, dark)
	for k in 3:
		mb.add_ellipsoid(Vector3(-0.1 + float(k) * 0.1, 0.4, -0.06 + float(k % 2) * 0.12), Vector3(0.09, 0.07, 0.07), content, content.lightened(0.2), 6, 3, true)
	return mb.build()


## A wooden barrel with iron bands (0.6 m tall).
static func barrel(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var wood: Color = look.color(GROUP, "barrel")
	var band: Color = look.color(GROUP, "barrel_band")
	mb.add_cone(Vector3.ZERO, 0.22, 0.28, 0.3, wood.darkened(0.15), wood, 10)
	mb.add_cone(Vector3(0.0, 0.3, 0.0), 0.28, 0.22, 0.3, wood, wood.darkened(0.1), 10, true)
	for by: float in [0.04, 0.3, 0.56]:
		var r: float = 0.285 if by == 0.3 else 0.235
		mb.add_cone(Vector3(0.0, by - 0.02, 0.0), r, r, 0.05, band, band, 10)
	return mb.build()


## A firewood log lying along +x (after the instance rotation), 1 m long, 0.1 m radius.
static func log_piece(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cone(Vector3.ZERO, 0.1, 0.1, 1.0, look.color("colors", "trunk_dark"), look.color("colors", "trunk"), 7)
	var end_color: Color = look.color("colors", "wood_b").lightened(0.25)
	mb.add_cone(Vector3(0.0, 0.99, 0.0), 0.085, 0.085, 0.02, end_color, end_color, 7, true)
	return mb.build()


## A unit tractor wheel (radius 1, width 1, axis along y); the instance rotates and scales it.
static func wheel(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var tire: Color = look.color(GROUP, "tire")
	var hub: Color = look.color(GROUP, "hub")
	mb.add_cone(Vector3(0.0, -0.5, 0.0), 1.0, 1.0, 1.0, tire, tire.lightened(0.1), 14, true, true)
	mb.add_cone(Vector3(0.0, -0.53, 0.0), 0.5, 0.5, 1.06, hub, hub, 10, true, true)
	return mb.build()


## A hen centered on its body, facing +x (legs reach down to y = -0.25).
static func hen(look: WorldLook, white: bool) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var body: Color = look.color(GROUP, "hen_white" if white else "hen_brown")
	var wing: Color = body.darkened(0.15)
	var red: Color = look.color(GROUP, "comb")
	var leg: Color = look.color(GROUP, "hen_leg")
	mb.add_ellipsoid(Vector3.ZERO, Vector3(0.2, 0.15, 0.14), body.darkened(0.1), body, 8, 5, true)
	mb.add_ellipsoid(Vector3(-0.2, 0.1, 0.0), Vector3(0.1, 0.13, 0.04), wing, body, 6, 4, true)
	mb.add_ellipsoid(Vector3(0.17, 0.17, 0.0), Vector3(0.07, 0.07, 0.065), body, body, 6, 4, true)
	mb.add_ellipsoid(Vector3(0.17, 0.25, 0.0), Vector3(0.03, 0.04, 0.015), red, red, 5, 3, true)
	mb.add_ellipsoid(Vector3(0.2, 0.1, 0.0), Vector3(0.02, 0.035, 0.02), red, red, 5, 3, true)
	mb.add_triangle(Vector3(0.23, 0.18, 0.03), Vector3(0.23, 0.18, -0.03), Vector3(0.3, 0.16, 0.0), look.color(GROUP, "beak"))
	for side: float in [-1.0, 1.0]:
		mb.add_ellipsoid(Vector3(-0.02, 0.02, side * 0.13), Vector3(0.13, 0.08, 0.025), wing, body, 6, 3, true)
		_box(mb, -0.01, -0.25, side * 0.05 - 0.01, 0.01, -0.12, side * 0.05 + 0.01, leg)
		_box(mb, -0.01, -0.25, side * 0.05 - 0.02, 0.07, -0.23, side * 0.05 + 0.02, leg)
	return mb.build()


## The windmill rotor in local coordinates (facing +z, turning around the z axis): hub and
## blades with wooden spars, ribs and cloth.
static func rotor(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var blades: int = look.integer(GROUP, "mill_blades")
	var length: float = look.num(GROUP, "mill_blade_length")
	var wood: Color = look.color("colors", "wood_dark")
	var cloth: Color = look.color(GROUP, "cloth")
	mb.add_ellipsoid(Vector3(0.0, 0.0, 0.05), Vector3(0.2, 0.2, 0.25), wood, look.color("colors", "wood_a"), 8, 5, true)
	mb.add_ellipsoid(Vector3(0.0, 0.0, 0.28), Vector3(0.1, 0.1, 0.1), look.color("colors", "roof_a"), look.color("colors", "roof_a"), 6, 4, true)
	for i in blades:
		var a: float = TAU * float(i) / float(blades)
		var d := Vector3(cos(a), sin(a), 0.0)
		var p := Vector3(-sin(a), cos(a), 0.0)
		_beam(mb, d * 0.15, d * length, 0.07, wood)
		mb.add_quad(d * 0.5 + p * 0.06, d * length + p * 0.06, d * length + p * 0.44, d * 0.5 + p * 0.44, cloth, Vector3.BACK)
		for k in 5:
			var r: float = 0.5 + float(k) * (length - 0.5) / 4.0
			_beam(mb, d * r + p * 0.06, d * r + p * 0.46, 0.04, wood)
	return mb.build()


# ---------------------------------------------------------------------------------------------
# Building blocks
# ---------------------------------------------------------------------------------------------

static func _box(mb: MeshBuilder, x0: float, y0: float, z0: float, x1: float, y1: float, z1: float, color: Color) -> void:
	mb.add_box(Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, y1 - y0, z1 - z0), color)


## A square-section beam from [param a] to [param b].
static func _beam(mb: MeshBuilder, a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var dir: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var u: Vector3 = dir.cross(ref).normalized() * thick * 0.5
	var v: Vector3 = dir.cross(u).normalized() * thick * 0.5
	var p: Array[Vector3] = [a - u - v, a + u - v, a + u + v, a - u + v, b - u - v, b + u - v, b + u + v, b - u + v]
	mb.add_quad(p[0], p[1], p[2], p[3], color, -dir)
	mb.add_quad(p[4], p[5], p[6], p[7], color, dir)
	mb.add_quad(p[0], p[1], p[5], p[4], color, -v)
	mb.add_quad(p[1], p[2], p[6], p[5], color, u)
	mb.add_quad(p[2], p[3], p[7], p[6], color, v)
	mb.add_quad(p[3], p[0], p[4], p[7], color, -u)


## A wall made of horizontal boards of two alternating tones.
static func _planks(mb: MeshBuilder, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float, count: int, color_a: Color, color_b: Color) -> void:
	var h: float = (y1 - y0) / float(count)
	for k in count:
		_box(mb, x0, y0 + float(k) * h, z0, x1, y0 + float(k + 1) * h, z1, color_a if k % 2 == 0 else color_b)


## A gable roof with its ridge along x: tile bands of two tones, eave fascia, ridge cap, and the
## triangular gable ends (wall color) with timber edges.
static func _gable(mb: MeshBuilder, x0: float, x1: float, z0: float, z1: float, wall_y: float, rise: float, over: float, bands: int, color_a: Color, color_b: Color, ridge: Color, gable_color: Color, trim: Color) -> void:
	var zc: float = (z0 + z1) * 0.5
	var xm: float = (x0 + x1) * 0.5
	var slope: float = rise / (zc - z0)
	var eave_y: float = wall_y - over * slope
	var ridge_y: float = wall_y + rise
	var xa: float = x0 - over
	var xb: float = x1 + over
	for side: float in [1.0, -1.0]:
		var z_eave: float = zc + side * ((z1 - z0) * 0.5 + over)
		for k in bands:
			var t0: float = float(k) / float(bands)
			var t1: float = float(k + 1) / float(bands)
			var color: Color = color_a if k % 2 == 0 else color_b
			mb.add_quad(Vector3(xa, lerpf(eave_y, ridge_y, t0), lerpf(z_eave, zc, t0)), Vector3(xb, lerpf(eave_y, ridge_y, t0), lerpf(z_eave, zc, t0)), Vector3(xb, lerpf(eave_y, ridge_y, t1), lerpf(z_eave, zc, t1)), Vector3(xa, lerpf(eave_y, ridge_y, t1), lerpf(z_eave, zc, t1)), color, Vector3(0.0, 1.0, side * slope))
		mb.add_box(Vector3(xm, eave_y - 0.03, z_eave), Vector3(xb - xa, 0.07, 0.08), trim)
	mb.add_box(Vector3(xm, ridge_y + 0.02, zc), Vector3(xb - xa + 0.1, 0.12, 0.2), ridge)
	for end_x: float in [x0, x1]:
		var out: Vector3 = Vector3.RIGHT if end_x == x1 else Vector3.LEFT
		mb.add_triangle(Vector3(end_x, wall_y, z0), Vector3(end_x, wall_y, z1), Vector3(end_x, ridge_y, zc), gable_color, out)
		var s: float = out.x * 0.03
		_beam(mb, Vector3(end_x + s, wall_y, z0), Vector3(end_x + s, ridge_y, zc), 0.09, trim)
		_beam(mb, Vector3(end_x + s, wall_y, z1), Vector3(end_x + s, ridge_y, zc), 0.09, trim)


## Maps a wall-local offset (across, up, out) to world axes: south walls use it as is, east
## walls swap x and z.
static func _o(east: bool, v: Vector3) -> Vector3:
	return Vector3(v.z, v.y, v.x) if east else v


## A window on a wall: frame, glow-able glass, cross bars, sill and an optional flower box.
## [param c] is the point on the wall surface at the window center.
static func _window(frame: MeshBuilder, glass: MeshBuilder, c: Vector3, east: bool, w: float, h: float, trim: Color, glass_color: Color, flowers: Array[Color], leaf: Color) -> void:
	frame.add_box(c + _o(east, Vector3(0.0, 0.0, 0.04)), _o(east, Vector3(w + 0.16, h + 0.16, 0.08)), trim)
	glass.add_box(c + _o(east, Vector3(0.0, 0.0, 0.06)), _o(east, Vector3(w, h, 0.1)), glass_color)
	frame.add_box(c + _o(east, Vector3(0.0, 0.0, 0.11)), _o(east, Vector3(0.05, h + 0.02, 0.05)), trim)
	frame.add_box(c + _o(east, Vector3(0.0, 0.0, 0.11)), _o(east, Vector3(w + 0.02, 0.05, 0.05)), trim)
	frame.add_box(c + _o(east, Vector3(0.0, -h * 0.5 - 0.12, 0.1)), _o(east, Vector3(w + 0.25, 0.07, 0.2)), trim)
	if flowers.is_empty():
		return
	frame.add_box(c + _o(east, Vector3(0.0, -h * 0.5 - 0.25, 0.2)), _o(east, Vector3(w + 0.1, 0.2, 0.26)), trim.darkened(0.2))
	frame.add_ellipsoid(c + _o(east, Vector3(0.0, -h * 0.5 - 0.13, 0.2)), _o(east, Vector3(w * 0.5, 0.07, 0.11)), leaf.darkened(0.2), leaf, 8, 3, true)
	for k in 5:
		var u: float = -w * 0.4 + float(k) * w * 0.2
		frame.add_ellipsoid(c + _o(east, Vector3(u, -h * 0.5 - 0.08, 0.2)), Vector3(0.07, 0.07, 0.07), flowers[k % flowers.size()], flowers[k % flowers.size()].lightened(0.2), 5, 3, true)


# ---------------------------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------------------------

static func _house(mb: MeshBuilder, look: WorldLook, glass: MeshBuilder) -> void:
	var x0: float = float(WorldGrid.HOUSE.position.x)
	var z0: float = float(WorldGrid.HOUSE.position.y)
	var x1: float = float(WorldGrid.HOUSE.end.x)
	var z1: float = float(WorldGrid.HOUSE.end.y)
	var xm: float = (x0 + x1) * 0.5
	var zc: float = (z0 + z1) * 0.5
	var wall_h: float = look.num("house", "wall_height")
	var rise: float = look.num("house", "roof_rise")
	var c_wall: Color = look.color("colors", "wall")
	var c_trim: Color = look.color("colors", "wall_trim")
	var c_stone: Color = look.color("colors", "stone")
	var c_door: Color = look.color("colors", "door")
	var wood_a: Color = look.color("colors", "wood_a")
	var wood_b: Color = look.color("colors", "wood_b")
	var palette: Array[Color] = look.color_list(GROUP, "flowerbox_palette")
	var leaf: Color = look.color("colors", "leaf_mid")
	var no_flowers: Array[Color] = []

	# Stone base, plaster walls, timber corner posts and top beams.
	mb.add_box(Vector3(xm, 0.2, zc), Vector3(x1 - x0 + 0.1, 0.4, z1 - z0 + 0.1), c_stone)
	mb.add_box(Vector3(xm, 0.4 + (wall_h - 0.4) * 0.5, zc), Vector3(x1 - x0, wall_h - 0.4, z1 - z0), c_wall)
	for cx: float in [x0, x1]:
		for cz: float in [z0, z1]:
			mb.add_box(Vector3(cx, 0.4 + (wall_h - 0.4) * 0.5, cz), Vector3(0.16, wall_h - 0.4, 0.16), c_trim)
	for cz: float in [z0, z1]:
		mb.add_box(Vector3(xm, wall_h - 0.07, cz), Vector3(x1 - x0 + 0.16, 0.14, 0.16), c_trim)
	for cx: float in [x0, x1]:
		mb.add_box(Vector3(cx, wall_h - 0.07, zc), Vector3(0.16, 0.14, z1 - z0 + 0.16), c_trim)

	# Exposed timber: vertical beams, a mid rail and diagonal braces on the south and east walls.
	for bx: float in [x0 + 0.55, x1 - 0.35]:
		_box(mb, bx - 0.05, 0.4, z1, bx + 0.05, wall_h - 0.14, z1 + 0.05, c_trim)
	for bz: float in [z0 + 1.0, z0 + 3.0]:
		_box(mb, x1, 0.4, bz - 0.05, x1 + 0.05, wall_h - 0.14, bz + 0.05, c_trim)
	_box(mb, x0, 1.95, z1, x1, 2.02, z1 + 0.05, c_trim)
	_box(mb, x1, 1.95, z0, x1 + 0.05, 2.02, z1, c_trim)
	_beam(mb, Vector3(x0 + 0.1, 1.95, z1 + 0.03), Vector3(x0 + 0.55, 2.3, z1 + 0.03), 0.07, c_trim)
	_beam(mb, Vector3(x1 - 0.1, 1.95, z1 + 0.03), Vector3(x1 - 0.35, 2.3, z1 + 0.03), 0.07, c_trim)

	# Tiled gable roof, ridge along x.
	_gable(mb, x0, x1, z0, z1, wall_h, rise, look.num("house", "roof_overhang"), look.integer("house", "roof_bands"), look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), c_wall, c_trim)

	# Chimney on the ridge: stone with darker courses and a dark cap.
	var top: Vector3 = PropMeshes.chimney_top(look)
	var ridge_y: float = wall_h + rise
	mb.add_box(Vector3(top.x, (top.y - 0.08 + ridge_y - 0.6) * 0.5, top.z), Vector3(0.5, top.y - 0.08 - (ridge_y - 0.6), 0.5), c_stone)
	for k in 3:
		mb.add_box(Vector3(top.x, ridge_y + 0.1 + float(k) * 0.22, top.z), Vector3(0.54, 0.05, 0.54), c_stone.darkened(0.25))
	mb.add_box(Vector3(top.x, top.y - 0.04, top.z), Vector3(0.62, 0.08, 0.62), look.color("colors", "roof_ridge"))

	# Door with frame, knob, and the fish sign over it.
	var door_x: float = float(WorldGrid.DOOR.x) + 0.5
	mb.add_box(Vector3(door_x, 0.97, z1 + 0.05), Vector3(1.15, 1.9, 0.1), c_trim)
	mb.add_box(Vector3(door_x, 0.9, z1 + 0.08), Vector3(0.95, 1.75, 0.1), c_door)
	mb.add_box(Vector3(door_x + 0.3, 0.9, z1 + 0.16), Vector3(0.07, 0.07, 0.06), look.color("colors", "lantern_glass"))
	mb.add_box(Vector3(door_x, 2.1, z1 + 0.06), Vector3(0.95, 0.32, 0.08), look.color("colors", "sign_board"))
	mb.add_box(Vector3(door_x - 0.05, 2.1, z1 + 0.11), Vector3(0.5, 0.13, 0.03), look.color("colors", "sign_blue"))
	mb.add_box(Vector3(door_x + 0.28, 2.1, z1 + 0.11), Vector3(0.12, 0.2, 0.03), look.color("colors", "sign_blue"))

	# Windows: two on the south wall with flower boxes, one on the east wall.
	var glass_color: Color = look.color("colors", "window")
	for wx: float in [7.2, 9.8]:
		_window(mb, glass, Vector3(wx, 1.35, z1), false, 0.7, 0.6, c_trim, glass_color, palette, leaf)
	_window(mb, glass, Vector3(x1, 1.35, zc), true, 0.7, 0.6, c_trim, glass_color, no_flowers, leaf)

	# Wooden porch in front of the door (low, so the fisherman walks over it): planks, posts,
	# rails with balusters either side of the steps, and two steps.
	var px0: float = x0 + 0.1
	var px1: float = x1 - 1.1
	for k in 5:
		_box(mb, px0, 0.0, z1 + float(k) * 0.19, px1, 0.14, z1 + float(k + 1) * 0.19, wood_a if k % 2 == 0 else wood_b)
	_box(mb, door_x - 0.5, 0.0, z1 + 0.95, door_x + 0.5, 0.08, z1 + 1.22, wood_b)
	_box(mb, door_x - 0.5, 0.0, z1 + 1.22, door_x + 0.5, 0.04, z1 + 1.45, wood_a)
	for post_x: float in [px0 + 0.05, door_x - 0.55, door_x + 0.55, px1 - 0.05]:
		_box(mb, post_x - 0.05, 0.0, z1 + 0.82, post_x + 0.05, 1.0, z1 + 0.92, c_trim)
	for seg: Vector2 in [Vector2(px0 + 0.05, door_x - 0.55), Vector2(door_x + 0.55, px1 - 0.05)]:
		_box(mb, seg.x, 0.92, z1 + 0.84, seg.y, 1.0, z1 + 0.9, c_trim)
		_box(mb, seg.x, 0.45, z1 + 0.85, seg.y, 0.5, z1 + 0.89, c_trim)
		var count: int = int((seg.y - seg.x) / 0.3)
		for k in count:
			var bx: float = seg.x + (float(k) + 0.5) * (seg.y - seg.x) / float(count)
			_box(mb, bx - 0.025, 0.14, z1 + 0.85, bx + 0.025, 0.92, z1 + 0.89, wood_b)
	_box(mb, px0 + 0.0, 0.92, z1, px0 + 0.06, 1.0, z1 + 0.9, c_trim)
	_box(mb, px1 - 0.06, 0.92, z1, px1, 1.0, z1 + 0.9, c_trim)

	# Sign post beside the door (a solid block in the grid).
	mb.add_box(Vector3(WorldGrid.SIGN.x, 0.475, WorldGrid.SIGN.y), Vector3(0.09, 0.95, 0.09), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(WorldGrid.SIGN.x, 1.0, WorldGrid.SIGN.y), Vector3(0.62, 0.42, 0.06), look.color("colors", "sign_board"))
	mb.add_box(Vector3(WorldGrid.SIGN.x, 1.0, WorldGrid.SIGN.y + 0.04), Vector3(0.4, 0.12, 0.03), look.color("colors", "sign_blue"))


static func _shed(mb: MeshBuilder, look: WorldLook) -> void:
	var r: Rect2i = cell_rect(look, "shed")
	var x0: float = float(r.position.x)
	var x1: float = float(r.end.x)
	var z0: float = float(r.position.y)
	var z1: float = float(r.end.y)
	var wall_y: float = look.num(GROUP, "shed_wall_height")
	var wood_a: Color = look.color("colors", "wood_a")
	var wood_b: Color = look.color("colors", "wood_b")
	var post: Color = look.color("colors", "wood_dark")
	var lift: float = look.num(GROUP, "ground_lift")
	_box(mb, x0, 0.0, z0, x1, 0.05 + lift, z1, look.color("colors", "dirt_b"))
	_planks(mb, x0, x1, z0, z0 + 0.12, 0.05, wall_y, 12, wood_a, wood_b)
	_planks(mb, x0, x0 + 0.12, z0, z1, 0.05, wall_y, 12, wood_a, wood_b)
	_box(mb, x1 - 0.1, 0.9, z0, x1, 1.0, z1, post)
	_box(mb, x1 - 0.1, 1.7, z0, x1, 1.8, z1, post)
	for px: float in [x0, x1]:
		for pz: float in [z0, z1]:
			_box(mb, px - 0.1, 0.0, pz - 0.1, px + 0.1, wall_y, pz + 0.1, post)
	_box(mb, x0 - 0.1, wall_y - 0.28, z1 - 0.1, x1 + 0.1, wall_y, z1 + 0.1, post)
	_beam(mb, Vector3(x0 + 0.1, wall_y - 0.28, z1), Vector3(x0 + 0.7, wall_y - 0.9, z1), 0.1, post)
	_beam(mb, Vector3(x1 - 0.1, wall_y - 0.28, z1), Vector3(x1 - 0.7, wall_y - 0.9, z1), 0.1, post)
	_gable(mb, x0, x1, z0, z1, wall_y, look.num(GROUP, "shed_roof_rise"), 0.35, look.integer(GROUP, "roof_bands"), look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), wood_a, post)


static func _tractor(mb: MeshBuilder, look: WorldLook) -> void:
	var r: Rect2i = cell_rect(look, "tractor")
	var cx: float = float(r.position.x) + float(r.size.x) * 0.5
	var cz: float = float(r.position.y) + float(r.size.y) * 0.5
	var red: Color = look.color(GROUP, "tractor_red")
	var dark: Color = look.color(GROUP, "tractor_dark")
	var metal: Color = look.color(GROUP, "metal")
	var pane: Color = look.color(GROUP, "tractor_glass")
	var big_r: float = look.num(GROUP, "wheel_big_radius")
	# Chassis, hood, grille, headlights and exhaust (the tractor faces east).
	_box(mb, cx - 0.9, 0.35, cz - 0.3, cx + 1.1, 0.65, cz + 0.3, dark)
	_box(mb, cx + 0.1, 0.6, cz - 0.34, cx + 1.05, 1.15, cz + 0.34, red)
	_box(mb, cx + 0.1, 1.15, cz - 0.3, cx + 1.05, 1.2, cz + 0.3, dark)
	_box(mb, cx + 1.05, 0.65, cz - 0.28, cx + 1.1, 1.05, cz + 0.28, metal)
	for hz: float in [-0.2, 0.2]:
		mb.add_ellipsoid(Vector3(cx + 1.1, 0.95, cz + hz), Vector3(0.05, 0.08, 0.08), look.color(GROUP, "headlight"), look.color(GROUP, "headlight"), 6, 4, true)
	mb.add_cone(Vector3(cx + 0.7, 1.2, cz + 0.2), 0.05, 0.04, 0.55, metal, dark, 6, true)
	# Rear fenders over the big wheels, cabin with floor, seat, posts, glass and roof.
	for side: float in [-1.0, 1.0]:
		_box(mb, cx - 1.0, big_r * 2.0 + 0.02, cz + side * 0.62 - 0.25, cx - 0.2, big_r * 2.0 + 0.08, cz + side * 0.62 + 0.25, red)
		_box(mb, cx - 0.95, 0.6, cz + side * 0.33 - 0.04, cx - 0.1, 1.9, cz + side * 0.33 + 0.04, pane.darkened(0.1))
	_box(mb, cx - 1.0, 0.6, cz - 0.38, cx - 0.05, 0.68, cz + 0.38, dark)
	_box(mb, cx - 0.8, 0.68, cz - 0.2, cx - 0.4, 0.95, cz + 0.2, dark)
	_box(mb, cx - 0.8, 0.95, cz - 0.2, cx - 0.72, 1.35, cz + 0.2, dark)
	for px: float in [cx - 1.0, cx - 0.05]:
		for pz: float in [cz - 0.38, cz + 0.38]:
			_box(mb, px - 0.04, 0.68, pz - 0.04, px + 0.04, 2.0, pz + 0.04, red)
	_box(mb, cx - 1.1, 2.0, cz - 0.5, cx + 0.05, 2.1, cz + 0.5, red)
	_box(mb, cx - 0.98, 0.7, cz - 0.36, cx - 0.92, 1.9, cz + 0.36, pane.darkened(0.1))
	_box(mb, cx - 0.5, 0.95, cz - 0.04, cx - 0.46, 1.25, cz + 0.04, metal)


static func _garden(mb: MeshBuilder, look: WorldLook) -> void:
	var g: Rect2i = cell_rect(look, "garden")
	var soil_dark: Color = look.color(GROUP, "soil_dark")
	var soil_light: Color = look.color(GROUP, "soil_light")
	var beds: Array[Vector3] = garden_beds(look)
	var x_end: float = float(g.end.x) - look.num(GROUP, "garden_strip")
	var lift: float = look.num(GROUP, "ground_lift")
	_box(mb, float(g.position.x) + 0.3, 0.0, float(g.position.y) + 0.3, x_end + 0.2, 0.04 + lift, float(g.end.y) - 0.3, soil_light)
	for bed: Vector3 in beds:
		_box(mb, bed.x, 0.0, bed.y - 0.21, bed.z, 0.16 + lift, bed.y + 0.21, soil_dark)
		_box(mb, bed.x + 0.05, 0.16 + lift, bed.y - 0.08, bed.z - 0.05, 0.175 + lift, bed.y + 0.08, soil_light)
	# Scarecrow in the free strip: pole, arms, shirt, head, straw hat and straw tufts.
	var s: Vector2 = garden_strip_center(look) + Vector2(0.0, -0.6)
	var wood: Color = look.color("colors", "wood_dark")
	var straw: Color = look.color(GROUP, "straw")
	_box(mb, s.x - 0.04, 0.0, s.y - 0.04, s.x + 0.04, 1.75, s.y + 0.04, wood)
	_box(mb, s.x - 0.04, 1.28, s.y - 0.6, s.x + 0.04, 1.34, s.y + 0.6, wood)
	_box(mb, s.x - 0.12, 0.85, s.y - 0.27, s.x + 0.12, 1.4, s.y + 0.27, look.color(GROUP, "scarecrow_shirt"))
	_box(mb, s.x + 0.12, 1.0, s.y - 0.1, s.x + 0.14, 1.12, s.y + 0.1, look.color("colors", "sign_blue"))
	mb.add_ellipsoid(Vector3(s.x, 1.55, s.y), Vector3(0.15, 0.15, 0.15), look.color("colors", "skin"), look.color("colors", "skin"), 8, 5, true)
	mb.add_cone(Vector3(s.x, 1.66, s.y), 0.32, 0.3, 0.04, straw, straw, 10, true)
	mb.add_cone(Vector3(s.x, 1.7, s.y), 0.17, 0.12, 0.18, straw.darkened(0.1), straw, 10, true)
	_box(mb, s.x - 0.17, 1.7, s.y - 0.18, s.x + 0.17, 1.76, s.y + 0.18, look.color("colors", "hat_band"))
	for side: float in [-1.0, 1.0]:
		mb.add_ellipsoid(Vector3(s.x, 1.31, s.y + side * 0.62), Vector3(0.1, 0.1, 0.12), straw, straw, 5, 3, true)
		mb.add_ellipsoid(Vector3(s.x, 0.85, s.y + side * 0.18), Vector3(0.1, 0.1, 0.1), straw, straw, 5, 3, true)


static func _coop(mb: MeshBuilder, look: WorldLook) -> void:
	var pen: Rect2i = cell_rect(look, "pen")
	var x0: float = float(pen.position.x) + 0.4
	var z0: float = float(pen.position.y) + 0.3
	var x1: float = x0 + look.num(GROUP, "coop_width")
	var z1: float = z0 + look.num(GROUP, "coop_depth")
	var wall: Color = look.color(GROUP, "coop_wall")
	var wood: Color = look.color("colors", "wood_dark")
	var hay: Color = look.color(GROUP, "hay")
	_box(mb, x0 - 0.05, 0.0, z0 - 0.05, x1 + 0.05, 0.35, z1 + 0.05, look.color("colors", "stone"))
	_planks(mb, x0, x1, z0, z1, 0.35, 1.25, 6, wall, wall.darkened(0.12))
	var door_x: float = (x0 + x1) * 0.5
	_box(mb, door_x - 0.25, 0.35, z1, door_x + 0.25, 0.95, z1 + 0.05, wood.darkened(0.5))
	_box(mb, door_x - 0.3, 0.35, z1, door_x - 0.25, 1.0, z1 + 0.08, wood)
	_box(mb, door_x + 0.25, 0.35, z1, door_x + 0.3, 1.0, z1 + 0.08, wood)
	_box(mb, door_x - 0.3, 0.97, z1, door_x + 0.3, 1.03, z1 + 0.08, wood)
	mb.add_quad(Vector3(door_x - 0.22, 0.38, z1 + 0.05), Vector3(door_x + 0.22, 0.38, z1 + 0.05), Vector3(door_x + 0.22, 0.04, z1 + 0.75), Vector3(door_x - 0.22, 0.04, z1 + 0.75), wall.lightened(0.15), Vector3.UP)
	for k in 4:
		_box(mb, door_x - 0.22, 0.38 - float(k) * 0.085 - 0.01, z1 + 0.05 + float(k) * 0.18, door_x + 0.22, 0.4 - float(k) * 0.085, z1 + 0.07 + float(k) * 0.18, wood)
	_gable(mb, x0, x1, z0, z1, 1.25, 0.6, 0.2, 6, look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), wall, wood)
	_box(mb, x1, 0.55, z0 + 0.3, x1 + 0.4, 1.0, z0 + 0.9, wall.darkened(0.08))
	_box(mb, x1 - 0.02, 1.0, z0 + 0.25, x1 + 0.45, 1.05, z0 + 0.95, look.color("colors", "roof_b"))
	# Hay patches, a feeder and a water bowl inside the pen.
	for spot: Vector3 in [Vector3(0.9, 0.0, 1.9), Vector3(2.5, 0.0, 2.9), Vector3(1.6, 0.0, 3.2)]:
		mb.add_ellipsoid(Vector3(float(pen.position.x) + spot.x, 0.02 + look.num(GROUP, "ground_lift"), float(pen.position.y) + spot.z), Vector3(0.28, 0.05, 0.22), hay.darkened(0.1), hay, 7, 3, true)
	var fx: float = float(pen.end.x) - 0.7
	_box(mb, fx - 0.2, 0.0, float(pen.end.y) - 0.7, fx + 0.2, 0.16, float(pen.end.y) - 0.5, wood)
	mb.add_cone(Vector3(fx - 0.4, 0.0, float(pen.end.y) - 0.9), 0.14, 0.17, 0.08, look.color(GROUP, "water_bowl"), look.color(GROUP, "water_bowl"), 8, true)


static func _tower(mb: MeshBuilder, look: WorldLook) -> void:
	var r: Rect2i = cell_rect(look, "tower")
	var cx: float = float(r.position.x) + float(r.size.x) * 0.5
	var cz: float = float(r.position.y) + float(r.size.y) * 0.5
	var radius: float = 0.85
	var y0: float = 2.1
	var y1: float = 3.4
	var wood: Color = look.color("colors", "wood_dark")
	var band: Color = look.color(GROUP, "tank_band")
	var slats: int = 14
	for k in slats:
		var a0: float = TAU * float(k) / float(slats)
		var a1: float = TAU * float(k + 1) / float(slats)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var color: Color = look.color(GROUP, "tank_a" if k % 2 == 0 else "tank_b")
		mb.add_quad(Vector3(cx, y0, cz) + d0 * radius, Vector3(cx, y0, cz) + d1 * radius, Vector3(cx, y1, cz) + d1 * radius, Vector3(cx, y1, cz) + d0 * radius, color, d0 + d1)
	for by: float in [y0 + 0.12, (y0 + y1) * 0.5, y1 - 0.12]:
		mb.add_cone(Vector3(cx, by - 0.04, cz), radius + 0.025, radius + 0.025, 0.08, band, band, 14)
	mb.add_cone(Vector3(cx, y1, cz), radius + 0.1, 0.0, 0.5, look.color("colors", "roof_b"), look.color("colors", "roof_a"), 14)
	mb.add_cone(Vector3(cx, y0 - 0.12, cz), radius + 0.1, radius + 0.1, 0.12, wood, wood, 14, true)
	for k in 4:
		var a: float = PI * 0.25 + float(k) * PI * 0.5
		var d := Vector3(cos(a), 0.0, sin(a))
		_beam(mb, Vector3(cx, y0 - 0.1, cz) + d * 0.7, Vector3(cx, 0.0, cz) + d * 1.0, 0.13, wood)
		var a2: float = a + PI * 0.5
		var d2 := Vector3(cos(a2), 0.0, sin(a2))
		_beam(mb, Vector3(cx, 0.35, cz) + d * 0.95, Vector3(cx, 1.65, cz) + d2 * 0.9, 0.06, wood.lightened(0.15))
		_beam(mb, Vector3(cx, 1.65, cz) + d * 0.9, Vector3(cx, 0.35, cz) + d2 * 0.95, 0.06, wood.lightened(0.15))
	_beam(mb, Vector3(cx + 0.55, 0.0, cz + 1.0), Vector3(cx + 0.55, y0 + 0.9, cz + 0.8), 0.07, wood.lightened(0.3))
	_beam(mb, Vector3(cx + 0.95, 0.0, cz + 0.95), Vector3(cx + 0.95, y0 + 0.9, cz + 0.75), 0.07, wood.lightened(0.3))


static func _mill_tower(mb: MeshBuilder, look: WorldLook) -> void:
	var r: Rect2i = cell_rect(look, "mill")
	var cx: float = float(r.position.x) + float(r.size.x) * 0.5
	var cz: float = float(r.position.y) + float(r.size.y) * 0.5
	var wall: Color = look.color(GROUP, "mill_wall")
	var stone: Color = look.color("colors", "stone")
	var yaw: float = deg_to_rad(look.num(GROUP, "mill_yaw_degrees"))
	var n := Vector3(sin(yaw), 0.0, cos(yaw))
	var t := Vector3(cos(yaw), 0.0, -sin(yaw))
	mb.add_cone(Vector3(cx, 0.0, cz), 1.0, 0.96, 0.5, stone.darkened(0.1), stone, 10)
	mb.add_cone(Vector3(cx, 0.5, cz), 0.95, 0.58, 2.5, wall.darkened(0.12), wall, 10)
	mb.add_cone(Vector3(cx, 2.95, cz), 0.66, 0.0, 0.8, look.color("colors", "roof_b"), look.color("colors", "roof_a"), 10)
	mb.add_cone(Vector3(cx, 2.9, cz), 0.66, 0.66, 0.08, look.color("colors", "wood_dark"), look.color("colors", "wood_dark"), 10)
	var door_c: Vector3 = Vector3(cx, 0.0, cz) + n * 0.92
	var trim: Color = look.color("colors", "wall_trim")
	mb.add_quad(door_c - t * 0.4, door_c + t * 0.4, door_c + t * 0.4 + Vector3(0.0, 1.5, 0.0), door_c - t * 0.4 + Vector3(0.0, 1.5, 0.0), trim, n)
	var door_f: Vector3 = door_c + n * 0.02
	mb.add_quad(door_f - t * 0.3, door_f + t * 0.3, door_f + t * 0.3 + Vector3(0.0, 1.35, 0.0), door_f - t * 0.3 + Vector3(0.0, 1.35, 0.0), look.color("colors", "door"), n)
	var win_c: Vector3 = Vector3(cx, 1.9, cz) + n * 0.72 + t * 0.0
	mb.add_quad(win_c - t * 0.2 - Vector3(0.0, 0.2, 0.0), win_c + t * 0.2 - Vector3(0.0, 0.2, 0.0), win_c + t * 0.2 + Vector3(0.0, 0.2, 0.0), win_c - t * 0.2 + Vector3(0.0, 0.2, 0.0), look.color("colors", "wood_dark"), n)
	mb.add_ellipsoid(Vector3(cx, 0.0, cz) + n * 0.7 + Vector3(0.0, 3.1, 0.0), Vector3(0.22, 0.22, 0.22), trim, trim, 6, 4, true)


static func _shop(mb: MeshBuilder, look: WorldLook, glass: MeshBuilder) -> void:
	var r: Rect2i = cell_rect(look, "shop")
	var x0: float = float(r.position.x)
	var x1: float = float(r.end.x)
	var z0: float = float(r.position.y)
	var z1: float = float(r.end.y)
	var zc: float = (z0 + z1) * 0.5
	var wall_y: float = look.num(GROUP, "shop_wall_height")
	var rise: float = look.num(GROUP, "shop_roof_rise")
	var wall_a: Color = look.color(GROUP, "shop_wall_a")
	var wall_b: Color = look.color(GROUP, "shop_wall_b")
	var trim: Color = look.color("colors", "wall_trim")
	_box(mb, x0 - 0.05, 0.0, z0 - 0.05, x1 + 0.05, 0.3, z1 + 0.05, look.color("colors", "stone"))
	_planks(mb, x0, x1, z0, z1, 0.3, wall_y, 8, wall_a, wall_b)
	for px: float in [x0, x1]:
		for pz: float in [z0, z1]:
			_box(mb, px - 0.08, 0.3, pz - 0.08, px + 0.08, wall_y, pz + 0.08, trim)
	_gable(mb, x0, x1, z0, z1, wall_y, rise, 0.35, look.integer(GROUP, "roof_bands"), look.color(GROUP, "shop_roof_a"), look.color(GROUP, "shop_roof_b"), look.color(GROUP, "shop_ridge"), wall_a, trim)
	# Blue door with frame on the east (front) wall, and two windows either side.
	_box(mb, x1, 0.3, zc - 0.6, x1 + 0.1, 1.95, zc + 0.6, trim)
	_box(mb, x1, 0.3, zc - 0.47, x1 + 0.14, 1.85, zc + 0.47, look.color(GROUP, "shop_door"))
	_box(mb, x1 + 0.14, 1.0, zc + 0.3, x1 + 0.2, 1.07, zc + 0.37, look.color("colors", "lantern_glass"))
	var glass_color: Color = look.color("colors", "window")
	var no_flowers: Array[Color] = []
	for wz: float in [z0 + 0.5, z1 - 0.5]:
		_window(mb, glass, Vector3(x1, 1.3, wz), true, 0.6, 0.6, trim, glass_color, no_flowers, trim)
	# Striped awning (slanted stripes plus a hanging valance) over the whole front.
	var stripes: int = look.integer(GROUP, "awning_stripes")
	var az0: float = z0 + 0.1
	var az1: float = z1 - 0.1
	var blue: Color = look.color(GROUP, "awning_blue")
	var white: Color = look.color(GROUP, "awning_white")
	for k in stripes:
		var za: float = lerpf(az0, az1, float(k) / float(stripes))
		var zb: float = lerpf(az0, az1, float(k + 1) / float(stripes))
		var color: Color = blue if k % 2 == 0 else white
		mb.add_quad(Vector3(x1 + 0.02, 2.15, za), Vector3(x1 + 0.02, 2.15, zb), Vector3(x1 + 0.95, 1.75, zb), Vector3(x1 + 0.95, 1.75, za), color, Vector3(0.4, 1.0, 0.0))
		mb.add_quad(Vector3(x1 + 0.95, 1.75, za), Vector3(x1 + 0.95, 1.75, zb), Vector3(x1 + 0.95, 1.55, zb), Vector3(x1 + 0.95, 1.55, za), color, Vector3.RIGHT)
		mb.add_triangle(Vector3(x1 + 0.95, 1.55, za), Vector3(x1 + 0.95, 1.55, zb), Vector3(x1 + 0.95, 1.45, (za + zb) * 0.5), color, Vector3.RIGHT)
	_box(mb, x1 + 0.9, 1.72, az0 - 0.04, x1 + 0.97, 1.78, az1 + 0.04, trim)
	# Wooden fish sign on the gable: board, frame, blue fish with tail and eye.
	var sx: float = x1 + 0.03
	_box(mb, sx, 2.37, zc - 0.58, sx + 0.07, 2.87, zc + 0.58, look.color("colors", "wood_dark"))
	_box(mb, sx + 0.07, 2.41, zc - 0.54, sx + 0.1, 2.83, zc + 0.54, look.color("colors", "sign_board"))
	mb.add_ellipsoid(Vector3(sx + 0.12, 2.62, zc - 0.05), Vector3(0.025, 0.13, 0.28), look.color("colors", "sign_blue").darkened(0.15), look.color("colors", "sign_blue"), 8, 5, true)
	mb.add_triangle(Vector3(sx + 0.12, 2.62, zc + 0.2), Vector3(sx + 0.12, 2.8, zc + 0.42), Vector3(sx + 0.12, 2.44, zc + 0.42), look.color("colors", "sign_blue"), Vector3.RIGHT)
	mb.add_ellipsoid(Vector3(sx + 0.15, 2.67, zc - 0.22), Vector3(0.02, 0.03, 0.03), Color.WHITE, Color.WHITE, 4, 3, true)


static func _board_and_bench(mb: MeshBuilder, look: WorldLook) -> void:
	var wood: Color = look.color("colors", "wood_dark")
	var board: Color = look.color("colors", "sign_board")
	var b: Rect2i = cell_rect(look, "board")
	var bx: float = float(b.position.x) + float(b.size.x) * 0.5
	var bz: float = float(b.position.y) + float(b.size.y) * 0.5
	for lx: float in [-0.7, 0.7]:
		_box(mb, bx + lx - 0.05, 0.0, bz - 0.05, bx + lx + 0.05, 1.95, bz + 0.05, wood)
	_box(mb, bx - 0.85, 0.75, bz - 0.04, bx + 0.85, 1.75, bz + 0.04, wood)
	_box(mb, bx - 0.8, 0.8, bz + 0.04, bx + 0.8, 1.7, bz + 0.06, board)
	_box(mb, bx - 0.95, 1.93, bz - 0.12, bx + 0.95, 2.0, bz + 0.12, look.color("colors", "roof_a"))
	var papers: Array[Color] = [look.color(GROUP, "paper_a"), look.color(GROUP, "paper_b"), look.color(GROUP, "paper_c")]
	for k in 5:
		var px: float = bx - 0.58 + float(k) * 0.29
		var py: float = 1.45 if k % 2 == 0 else 1.05
		_box(mb, px - 0.12, py - 0.17, bz + 0.06, px + 0.12, py + 0.17, bz + 0.075, papers[k % papers.size()])
		_box(mb, px - 0.02, py + 0.13, bz + 0.075, px + 0.02, py + 0.17, bz + 0.09, look.color(GROUP, "pin"))
	var s: Rect2i = cell_rect(look, "bench")
	var sx: float = float(s.position.x) + float(s.size.x) * 0.5
	var sz: float = float(s.position.y) + float(s.size.y) * 0.5
	var wood_a: Color = look.color("colors", "wood_a")
	var wood_b: Color = look.color("colors", "wood_b")
	for k in 3:
		_box(mb, sx - 0.8, 0.42, sz - 0.25 + float(k) * 0.17, sx + 0.8, 0.48, sz - 0.1 + float(k) * 0.17, wood_a if k % 2 == 0 else wood_b)
	for k in 2:
		_box(mb, sx - 0.8, 0.62 + float(k) * 0.2, sz + 0.22, sx + 0.8, 0.72 + float(k) * 0.2, sz + 0.27, wood_b if k == 0 else wood_a)
	for lx: float in [-0.65, 0.65]:
		_box(mb, sx + lx - 0.04, 0.0, sz - 0.2, sx + lx + 0.04, 0.42, sz - 0.12, wood)
		_box(mb, sx + lx - 0.04, 0.0, sz + 0.18, sx + lx + 0.04, 1.0, sz + 0.26, wood)


static func _lamps(mb: MeshBuilder, look: WorldLook, glass: MeshBuilder) -> void:
	var iron: Color = look.color(GROUP, "lamp_iron")
	for i in look.integer(GROUP, "lamp_count"):
		var r: Rect2i = cell_rect(look, "lamp_%d" % (i + 1))
		var x: float = float(r.position.x) + 0.5
		var z: float = float(r.position.y) + 0.5
		mb.add_cone(Vector3(x, 0.0, z), 0.16, 0.08, 0.3, iron, iron, 6)
		mb.add_box(Vector3(x, 1.2, z), Vector3(0.08, 2.4, 0.08), iron)
		mb.add_box(Vector3(x, 2.43, z), Vector3(0.32, 0.05, 0.32), iron)
		glass.add_box(Vector3(x, 2.65, z), Vector3(0.24, 0.36, 0.24), look.color("colors", "lantern_glass"))
		for cx: float in [-0.13, 0.13]:
			for cz: float in [-0.13, 0.13]:
				mb.add_box(Vector3(x + cx, 2.65, z + cz), Vector3(0.03, 0.38, 0.03), iron)
		mb.add_cone(Vector3(x, 2.83, z), 0.26, 0.0, 0.22, iron, iron, 4)
		mb.add_ellipsoid(Vector3(x, 3.07, z), Vector3(0.04, 0.04, 0.04), iron, iron, 4, 3, true)
