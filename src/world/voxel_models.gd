class_name VoxelModels
extends RefCounted
## Blocky ("voxel") models made after the owner's reference pictures of 2026-11-22: the cow,
## the horse, the red barn (gambrel roof, X doors, lean-to with hay and a cart, windmill), the
## two-storey farmhouse with a porch, and the dressing of the crop field (fence, scarecrow,
## lanterns, crates). The pictures were style references only; every model is our own, built
## from boxes so the pixel material (pixel_furniture.gdshader) gives each face its border,
## bevel and pixel grain. Colors: the "voxel" group of world_look.json.
##
## Usage:
## [codeblock]
## var mb := MeshBuilder.new()
## VoxelModels.barn(mb, glass, look, lot_rect)
## var cow: ArrayMesh = VoxelModels.cow(look)
## [/codeblock]

const GROUP: String = "voxel"


static func _b(mb: MeshBuilder, x0: float, y0: float, z0: float, x1: float, y1: float, z1: float, color: Color) -> void:
	mb.add_box(Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)), color)


static func _c(look: WorldLook, key: String) -> Color:
	return look.color(GROUP, key)


# --- Animals ---

## A Holstein cow facing +x (about 1.3 m long): white body with jagged black patches, black
## head with a white blaze, pink muzzle and udder, cream horns, black hooves and tail tuft.
static func cow(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var white: Color = _c(look, "cow_white")
	var black: Color = _c(look, "cow_black")
	var pink: Color = _c(look, "cow_pink")
	var horn: Color = _c(look, "horn")
	mb.add_box(Vector3(0.0, 0.8, 0.0), Vector3(1.2, 0.6, 0.64), white)
	# Patches: groups of boxes just proud of the body, so their edges look jagged.
	var e: float = 0.012
	for side: float in [-1.0, 1.0]:
		var z: float = side * (0.32 + e * 0.5)
		for p: Array in [[-0.32, 0.88, 0.36, 0.34], [-0.2, 0.72, 0.2, 0.2], [0.18, 0.92, 0.3, 0.22], [0.3, 0.78, 0.16, 0.18], [-0.48, 0.66, 0.14, 0.16]]:
			mb.add_box(Vector3(float(p[0]) * side, float(p[1]), z), Vector3(float(p[2]), float(p[3]), e), black)
	for p: Array in [[-0.3, -0.1, 0.4, 0.3], [-0.12, 0.12, 0.2, 0.2], [0.28, 0.05, 0.28, 0.4], [0.44, -0.18, 0.12, 0.14]]:
		mb.add_box(Vector3(float(p[0]), 1.1 + e * 0.5, float(p[1])), Vector3(float(p[2]), e, float(p[3])), black)
	mb.add_box(Vector3(-0.6 - e * 0.5, 0.85, 0.05), Vector3(e, 0.3, 0.34), black)
	# Head, blaze, muzzle, nostrils, eyes, horns, ears.
	mb.add_box(Vector3(0.75, 0.98, 0.0), Vector3(0.34, 0.4, 0.44), black)
	mb.add_box(Vector3(0.75, 1.18 + e * 0.5, 0.0), Vector3(0.3, e, 0.16), white)
	mb.add_box(Vector3(0.92 + e * 0.5, 1.02, 0.0), Vector3(e, 0.34, 0.16), white)
	mb.add_box(Vector3(0.98, 0.85, 0.0), Vector3(0.14, 0.18, 0.34), pink)
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(1.055, 0.86, side * 0.08), Vector3(0.01, 0.06, 0.05), black.lightened(0.1))
		mb.add_box(Vector3(0.92 + e, 1.04, side * 0.17), Vector3(e, 0.07, 0.07), white)
		mb.add_box(Vector3(0.925 + e, 1.04, side * 0.185), Vector3(e, 0.05, 0.035), black)
		mb.add_box(Vector3(0.7, 1.24, side * 0.17), Vector3(0.08, 0.12, 0.08), horn)
		mb.add_box(Vector3(0.72, 1.33, side * 0.2), Vector3(0.06, 0.08, 0.06), horn.lightened(0.15))
		mb.add_box(Vector3(0.66, 1.06, side * 0.3), Vector3(0.08, 0.12, 0.18), black)
		mb.add_box(Vector3(0.705, 1.06, side * 0.31), Vector3(0.01, 0.08, 0.12), pink.darkened(0.15))
	# Udder and teats.
	mb.add_box(Vector3(-0.08, 0.45, 0.0), Vector3(0.3, 0.12, 0.28), pink)
	for p: Vector2 in [Vector2(-0.16, -0.07), Vector2(-0.16, 0.07), Vector2(0.0, -0.07), Vector2(0.0, 0.07)]:
		mb.add_box(Vector3(p.x, 0.36, p.y), Vector3(0.04, 0.07, 0.04), pink.darkened(0.1))
	# Legs with black hooves.
	for p: Vector2 in [Vector2(-0.42, -0.2), Vector2(-0.42, 0.2), Vector2(0.4, -0.2), Vector2(0.4, 0.2)]:
		mb.add_box(Vector3(p.x, 0.3, p.y), Vector3(0.17, 0.42, 0.17), white)
		mb.add_box(Vector3(p.x, 0.05, p.y), Vector3(0.18, 0.1, 0.18), black)
	# Tail: white, black tuft.
	mb.add_box(Vector3(-0.63, 0.78, 0.0), Vector3(0.05, 0.42, 0.06), white)
	mb.add_box(Vector3(-0.63, 0.5, 0.0), Vector3(0.08, 0.14, 0.08), black)
	return mb.build()


## A horse facing +z (about 1.6 m long) on three nodes, so it can move its head and tail.
## Children: 0 body mesh, 1 head pivot, 2 tail pivot. [param coat] is the body color; the mane,
## tail and hooves are darker, with a white blaze and white socks.
static func horse(look: WorldLook, coat: Color, material: Material) -> Node3D:
	var root := Node3D.new()
	var mane: Color = _c(look, "horse_mane") if coat.get_luminance() < 0.6 else coat.darkened(0.45)
	var white: Color = _c(look, "horse_white")
	var hoof: Color = _c(look, "horse_hoof")
	var body := MeshBuilder.new()
	body.add_box(Vector3(0.0, 1.0, -0.02), Vector3(0.52, 0.52, 1.2), coat)
	for p: Vector2 in [Vector2(-0.16, -0.45), Vector2(0.16, -0.45), Vector2(-0.16, 0.42), Vector2(0.16, 0.42)]:
		body.add_box(Vector3(p.x, 0.52, p.y), Vector3(0.15, 0.5, 0.15), coat.darkened(0.06))
		body.add_box(Vector3(p.x, 0.2, p.y), Vector3(0.16, 0.2, 0.16), white)
		body.add_box(Vector3(p.x, 0.05, p.y), Vector3(0.17, 0.1, 0.17), hoof)
	root.add_child(_mesh_node(body.build(), material))
	var head_pivot := Node3D.new()
	head_pivot.position = Vector3(0.0, 1.1, 0.48)
	root.add_child(head_pivot)
	var head := MeshBuilder.new()
	# Neck rising up and forward, then the long head.
	head.add_box(Vector3(0.0, 0.3, 0.06), Vector3(0.28, 0.6, 0.3), coat)
	head.add_box(Vector3(0.0, 0.62, 0.14), Vector3(0.26, 0.24, 0.28), coat)
	head.add_box(Vector3(0.0, 0.66, 0.4), Vector3(0.26, 0.26, 0.4), coat)
	head.add_box(Vector3(0.0, 0.6, 0.64), Vector3(0.24, 0.22, 0.14), white.darkened(0.08))
	head.add_box(Vector3(0.0, 0.795, 0.38), Vector3(0.09, 0.01, 0.4), white)
	head.add_box(Vector3(0.0, 0.7, 0.605), Vector3(0.09, 0.14, 0.01), white)
	for side: float in [-1.0, 1.0]:
		head.add_box(Vector3(side * 0.06, 0.58, 0.715), Vector3(0.04, 0.05, 0.01), hoof)
		head.add_box(Vector3(side * 0.135, 0.72, 0.4), Vector3(0.01, 0.08, 0.08), hoof)
		head.add_box(Vector3(side * 0.137, 0.74, 0.42), Vector3(0.01, 0.03, 0.03), white)
		head.add_box(Vector3(side * 0.08, 0.86, 0.24), Vector3(0.07, 0.16, 0.07), coat)
	# Mane: dark blocks stepping down the back of the neck, and a forelock.
	for k in 6:
		head.add_box(Vector3(0.0, 0.78 - float(k) * 0.13, -0.06 - float(k % 2) * 0.03), Vector3(0.14, 0.15, 0.12), mane)
	head.add_box(Vector3(0.0, 0.82, 0.3), Vector3(0.12, 0.08, 0.1), mane)
	head_pivot.add_child(_mesh_node(head.build(), material))
	var tail_pivot := Node3D.new()
	tail_pivot.position = Vector3(0.0, 1.15, -0.64)
	root.add_child(tail_pivot)
	var tail := MeshBuilder.new()
	tail.add_box(Vector3(0.0, -0.05, -0.08), Vector3(0.18, 0.2, 0.18), mane)
	tail.add_box(Vector3(0.0, -0.4, -0.12), Vector3(0.2, 0.55, 0.16), mane)
	tail.add_box(Vector3(0.0, -0.72, -0.1), Vector3(0.16, 0.16, 0.12), mane.darkened(0.1))
	tail_pivot.add_child(_mesh_node(tail.build(), material))
	return root


static func _mesh_node(mesh: ArrayMesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	return node


# --- Shared pieces ---

## A stepped (voxel) roof. The ridge runs along x when [param along_x], else along z.
## [param a0]/[param a1] span the ridge axis, [param c] is the ridge line across it, and each
## step of [param steps] is [half width, bottom y, top y], from the eaves up. The gable ends
## are filled with [param wall] when [param fill].
static func roof(mb: MeshBuilder, along_x: bool, a0: float, a1: float, c: float, steps: Array, over: float, shingle_a: Color, shingle_b: Color, wall: Color, fill: bool) -> void:
	for k in steps.size():
		var s: Array = steps[k]
		var half: float = s[0]
		var next_half: float = (steps[k + 1] as Array)[0] if k + 1 < steps.size() else 0.0
		var t: float = maxf(half - next_half, 0.0) + 0.14
		var col: Color = shingle_a if k % 2 == 0 else shingle_b
		for side: float in [-1.0, 1.0]:
			var outer: float = c + side * half
			var inner: float = outer - side * t
			_axis_box(mb, along_x, a0 - over, a1 + over, minf(inner, outer), maxf(inner, outer), float(s[1]), float(s[2]), col)
		if fill and half - t > 0.0:
			_axis_box(mb, along_x, a0, a1, c - half + t, c + half - t, float(s[1]), float(s[2]), wall)
	var top: Array = steps[steps.size() - 1]
	_axis_box(mb, along_x, a0 - over - 0.05, a1 + over + 0.05, c - 0.16, c + 0.16, float(top[2]), float(top[2]) + 0.1, shingle_b.darkened(0.25))


static func _axis_box(mb: MeshBuilder, along_x: bool, a0: float, a1: float, b0: float, b1: float, y0: float, y1: float, color: Color) -> void:
	if along_x:
		_b(mb, a0, y0, b0, a1, y1, b1, color)
	else:
		_b(mb, b0, y0, a0, b1, y1, a1, color)


## Steps for a simple gable: [param n] steps from half width [param half] at [param wall_y]
## up to the ridge [param rise] higher.
static func gable_steps(half: float, wall_y: float, rise: float, n: int) -> Array:
	var out: Array = []
	for k in n:
		out.append([half * (1.0 - float(k) / float(n)), wall_y + rise * float(k) / float(n), wall_y + rise * float(k + 1) / float(n)])
	return out


## A hanging lantern on a bracket: post optional, glow-able glass in [param glass].
static func lantern(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, at: Vector3, with_post: bool) -> void:
	var wood: Color = _c(look, "wood_dark")
	var metal: Color = _c(look, "metal")
	if with_post:
		_b(mb, at.x - 0.07, 0.0, at.z - 0.07, at.x + 0.07, at.y + 0.55, at.z + 0.07, wood)
		_b(mb, at.x - 0.07, at.y + 0.45, at.z - 0.07, at.x + 0.5, at.y + 0.55, at.z + 0.07, wood)
		at += Vector3(0.4, 0.0, 0.0)
	_b(mb, at.x - 0.01, at.y + 0.2, at.z - 0.01, at.x + 0.01, at.y + 0.45, at.z + 0.01, metal)
	_b(mb, at.x - 0.11, at.y + 0.13, at.z - 0.11, at.x + 0.11, at.y + 0.2, at.z + 0.11, metal)
	_b(mb, at.x - 0.11, at.y - 0.13, at.z - 0.11, at.x + 0.11, at.y - 0.07, at.z + 0.11, metal)
	glass.add_box(at, Vector3(0.17, 0.2, 0.17), _c(look, "lantern_glow"))


## A wooden fence run from [param a] to [param b] (x z): square posts every meter, two rails.
static func fence(mb: MeshBuilder, look: WorldLook, a: Vector2, b: Vector2) -> void:
	var post: Color = _c(look, "fence_post")
	var rail: Color = _c(look, "fence_rail")
	var n: int = maxi(1, int(round(a.distance_to(b))))
	for k in n + 1:
		var p: Vector2 = a.lerp(b, float(k) / float(n))
		_b(mb, p.x - 0.08, 0.0, p.y - 0.08, p.x + 0.08, 0.95, p.y + 0.08, post)
		_b(mb, p.x - 0.1, 0.95, p.y - 0.1, p.x + 0.1, 1.0, p.y + 0.1, post.darkened(0.15))
	var horizontal: bool = absf(b.x - a.x) > absf(b.y - a.y)
	for y: float in [0.38, 0.72]:
		if horizontal:
			_b(mb, minf(a.x, b.x), y - 0.07, a.y - 0.04, maxf(a.x, b.x), y + 0.07, a.y + 0.04, rail)
		else:
			_b(mb, a.x - 0.04, y - 0.07, minf(a.y, b.y), a.x + 0.04, y + 0.07, maxf(a.y, b.y), rail)


## A hay bale (about 0.9 x 0.5 x 0.55) with two strings.
static func hay_bale(mb: MeshBuilder, look: WorldLook, c: Vector3) -> void:
	var hay: Color = _c(look, "hay")
	_b(mb, c.x - 0.45, c.y, c.z - 0.28, c.x + 0.45, c.y + 0.5, c.z + 0.28, hay)
	for dx: float in [-0.22, 0.22]:
		_b(mb, c.x + dx - 0.025, c.y - 0.005, c.z - 0.285, c.x + dx + 0.025, c.y + 0.505, c.z + 0.285, hay.darkened(0.3))


## A barrel with dark hoops.
static func barrel(mb: MeshBuilder, look: WorldLook, c: Vector3) -> void:
	var wood: Color = _c(look, "barrel")
	var hoop: Color = _c(look, "metal").darkened(0.3)
	_b(mb, c.x - 0.25, c.y, c.z - 0.25, c.x + 0.25, c.y + 0.7, c.z + 0.25, wood)
	_b(mb, c.x - 0.28, c.y + 0.1, c.z - 0.28, c.x + 0.28, c.y + 0.6, c.z + 0.28, wood.lightened(0.05))
	for y: float in [0.12, 0.55]:
		_b(mb, c.x - 0.29, c.y + y, c.z - 0.29, c.x + 0.29, c.y + y + 0.05, c.z + 0.29, hoop)


## A wooden crate, optionally full of produce of [param fill] color.
static func crate(mb: MeshBuilder, look: WorldLook, c: Vector3, fill: Color) -> void:
	var wood: Color = _c(look, "crate")
	_b(mb, c.x - 0.3, c.y, c.z - 0.25, c.x + 0.3, c.y + 0.4, c.z + 0.25, wood)
	_b(mb, c.x - 0.31, c.y + 0.17, c.z - 0.26, c.x + 0.31, c.y + 0.23, c.z + 0.26, wood.darkened(0.25))
	if fill.a > 0.0:
		for k in 6:
			var px: float = c.x - 0.18 + float(k % 3) * 0.18
			var pz: float = c.z - 0.09 + float(k / 3) * 0.18
			_b(mb, px - 0.07, c.y + 0.38, pz - 0.07, px + 0.07, c.y + 0.5, pz + 0.07, fill if k % 2 == 0 else fill.darkened(0.15))


## A wooden cart along x with two wheels.
static func cart(mb: MeshBuilder, look: WorldLook, c: Vector3) -> void:
	var wood: Color = _c(look, "fence_rail")
	_b(mb, c.x - 0.6, c.y + 0.35, c.z - 0.35, c.x + 0.6, c.y + 0.45, c.z + 0.35, wood)
	for side: float in [-1.0, 1.0]:
		_b(mb, c.x - 0.6, c.y + 0.45, c.z + side * 0.35 - 0.04, c.x + 0.6, c.y + 0.7, c.z + side * 0.35 + 0.04, wood.darkened(0.1))
		_wheel(mb, look, Vector3(c.x, c.y + 0.32, c.z + side * 0.44))
	_b(mb, c.x + 0.6, c.y + 0.38, c.z - 0.04, c.x + 1.1, c.y + 0.44, c.z + 0.04, wood)


## A spoked wheel standing in the x-y plane.
static func _wheel(mb: MeshBuilder, look: WorldLook, c: Vector3) -> void:
	var wood: Color = _c(look, "wood_dark")
	for k in 8:
		var a: float = float(k) * TAU / 8.0
		var p := Vector3(cos(a), sin(a), 0.0) * 0.28
		mb.add_box(c + p, Vector3(0.1, 0.1, 0.06), wood)
	_b(mb, c.x - 0.28, c.y - 0.02, c.z - 0.02, c.x + 0.28, c.y + 0.02, c.z + 0.02, wood)
	_b(mb, c.x - 0.02, c.y - 0.28, c.z - 0.02, c.x + 0.02, c.y + 0.28, c.z + 0.02, wood)
	_b(mb, c.x - 0.06, c.y - 0.06, c.z - 0.04, c.x + 0.06, c.y + 0.06, c.z + 0.04, _c(look, "metal"))


## A window with a frame, glow-able glass, a cross and wooden shutters, on a wall facing
## +z ([param east] false) or +x ([param east] true). [param c] is on the wall surface.
static func window(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, c: Vector3, east: bool, w: float, h: float, shutters: bool) -> void:
	var frame: Color = _c(look, "trim_dark")
	var shutter: Color = _c(look, "shutter")
	_face_box(mb, east, c, Vector2(w + 0.14, h + 0.14), 0.0, 0.06, frame)
	glass.add_box(c + _out(east, 0.07), Vector3(0.02, h, w) if east else Vector3(w, h, 0.02), _c(look, "window_glow"))
	_face_box(mb, east, c, Vector2(0.05, h), 0.06, 0.1, frame)
	_face_box(mb, east, c, Vector2(w, 0.05), 0.06, 0.1, frame)
	_face_box(mb, east, c + Vector3(0.0, -h * 0.5 - 0.1, 0.0), Vector2(w + 0.24, 0.06), 0.0, 0.14, frame)
	if shutters:
		for side: float in [-1.0, 1.0]:
			var off: float = side * (w * 0.5 + 0.2)
			var pos: Vector3 = c + (Vector3(0.0, 0.0, off) if east else Vector3(off, 0.0, 0.0))
			_face_box(mb, east, pos, Vector2(0.3, h + 0.1), 0.0, 0.06, shutter)
			_face_box(mb, east, pos, Vector2(0.3, 0.05), 0.06, 0.08, shutter.darkened(0.25))


## A box on a wall: [param size] is (across, up), from [param from] to [param to] meters out.
static func _face_box(mb: MeshBuilder, east: bool, c: Vector3, size: Vector2, from: float, to: float, color: Color) -> void:
	var depth: float = to - from
	var mid: Vector3 = c + _out(east, (from + to) * 0.5)
	mb.add_box(mid, Vector3(depth, size.y, size.x) if east else Vector3(size.x, size.y, depth), color)


static func _out(east: bool, d: float) -> Vector3:
	return Vector3(d, 0.0, 0.0) if east else Vector3(0.0, 0.0, d)


# --- Buildings ---

## The red barn on lot [param r] (door to the south): board walls with white trim, a stepped
## gambrel roof with its gable to the front, X double doors under a little roof with a lantern,
## a hay-loft window, a lean-to on the east side with hay bales and a cart, a windmill behind,
## and a barrel, a planter crate and a short fence by the door.
static func barn(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	var red: Color = _c(look, "barn_red")
	var red_dark: Color = red.darkened(0.18)
	var trim: Color = _c(look, "barn_trim")
	var roof_a: Color = _c(look, "barn_roof")
	var roof_b: Color = roof_a.darkened(0.12)
	var x0: float = float(r.position.x) + 0.35
	var xm1: float = float(r.position.x) + 3.95
	var x1: float = float(r.end.x) - 0.2
	var z0: float = float(r.position.y) + 0.45
	var z1: float = float(r.end.y) - 0.6
	var wall_h: float = 2.5
	var xc: float = (x0 + xm1) * 0.5
	var half: float = (xm1 - x0) * 0.5
	# Stone footing and walls of vertical boards.
	_b(mb, x0 - 0.06, -0.2, z0 - 0.06, xm1 + 0.06, 0.18, z1 + 0.06, _c(look, "stone"))
	_b(mb, x0, 0.18, z0, xm1, wall_h, z1, red)
	var boards: int = int((xm1 - x0) / 0.3)
	for k in boards:
		if k % 2 == 1:
			var bx: float = x0 + float(k) * 0.3
			_b(mb, bx, 0.18, z1, bx + 0.3, wall_h, z1 + 0.02, red_dark)
	for k in int((z1 - z0) / 0.3):
		if k % 2 == 1:
			var bz: float = z0 + float(k) * 0.3
			_b(mb, x0 - 0.02, 0.18, bz, x0, wall_h, bz + 0.3, red_dark)
	for px: float in [x0, xm1]:
		for pz: float in [z0, z1]:
			_b(mb, px - 0.09, 0.18, pz - 0.09, px + 0.09, wall_h, pz + 0.09, trim)
	_b(mb, x0, wall_h - 0.12, z1, xm1, wall_h, z1 + 0.06, trim)
	_b(mb, x0, 1.95, z1, xm1, 2.03, z1 + 0.05, red_dark.darkened(0.2))
	# Gambrel roof (ridge along z): steep lower part, flatter upper part; the gable is filled.
	var steps: Array = [
		[half + 0.3, wall_h, wall_h + 0.3], [half + 0.12, wall_h + 0.3, wall_h + 0.6], [half - 0.05, wall_h + 0.6, wall_h + 0.9],
		[half - 0.35, wall_h + 0.9, wall_h + 1.1], [half - 0.75, wall_h + 1.1, wall_h + 1.3], [half - 1.15, wall_h + 1.3, wall_h + 1.45],
		[half - 1.5, wall_h + 1.45, wall_h + 1.55],
	]
	roof(mb, false, z0, z1, xc, steps, 0.25, roof_a, roof_b, red, true)
	# White trim following the gable steps, and the hay-loft window with an X.
	for k in steps.size() - 1:
		var s: Array = steps[k]
		for side: float in [-1.0, 1.0]:
			var ex: float = xc + side * (float(s[0]) - 0.14)
			_b(mb, ex - 0.07, float(s[1]), z1, ex + 0.07, float(s[2]) + 0.02, z1 + 0.05, trim)
	_b(mb, xc - 0.38, wall_h + 0.2, z1, xc + 0.38, wall_h + 1.0, z1 + 0.06, trim)
	_b(mb, xc - 0.3, wall_h + 0.28, z1 + 0.02, xc + 0.3, wall_h + 0.92, z1 + 0.07, red_dark)
	EstateMeshes._beam(mb, Vector3(xc - 0.28, wall_h + 0.3, z1 + 0.08), Vector3(xc + 0.28, wall_h + 0.9, z1 + 0.08), 0.06, trim)
	EstateMeshes._beam(mb, Vector3(xc + 0.28, wall_h + 0.3, z1 + 0.08), Vector3(xc - 0.28, wall_h + 0.9, z1 + 0.08), 0.06, trim)
	# Double doors with white frames and X braces, handles, a small roof and a lantern.
	var dw: float = 0.75
	for side: float in [-1.0, 1.0]:
		var dc: float = xc + side * dw * 0.5
		_b(mb, dc - dw * 0.5, 0.18, z1, dc + dw * 0.5, 1.9, z1 + 0.06, red)
		_b(mb, dc - dw * 0.5, 0.18, z1 + 0.06, dc - dw * 0.5 + 0.08, 1.9, z1 + 0.1, trim)
		_b(mb, dc + dw * 0.5 - 0.08, 0.18, z1 + 0.06, dc + dw * 0.5, 1.9, z1 + 0.1, trim)
		_b(mb, dc - dw * 0.5, 1.82, z1 + 0.06, dc + dw * 0.5, 1.9, z1 + 0.1, trim)
		_b(mb, dc - dw * 0.5, 0.18, z1 + 0.06, dc + dw * 0.5, 0.26, z1 + 0.1, trim)
		EstateMeshes._beam(mb, Vector3(dc - dw * 0.42, 0.3, z1 + 0.1), Vector3(dc + dw * 0.42, 1.78, z1 + 0.1), 0.07, trim)
		EstateMeshes._beam(mb, Vector3(dc + dw * 0.42, 0.3, z1 + 0.1), Vector3(dc - dw * 0.42, 1.78, z1 + 0.1), 0.07, trim)
		_b(mb, xc + side * 0.06 - 0.025, 0.85, z1 + 0.1, xc + side * 0.06 + 0.025, 1.15, z1 + 0.14, _c(look, "metal").darkened(0.4))
	_b(mb, xc - 1.0, 2.0, z1, xc + 1.0, 2.08, z1 + 0.45, roof_b)
	_b(mb, xc - 0.95, 2.08, z1, xc + 0.95, 2.16, z1 + 0.35, roof_a)
	lantern(mb, glass, look, Vector3(xc, 2.45, z1 + 0.15), false)
	# Lean-to on the east side: back and side walls, posts, a sloping stepped roof, hay and a cart.
	_b(mb, xm1, 0.0, z0, x1, 1.9, z0 + 0.1, red)
	_b(mb, x1 - 0.1, 0.0, z0, x1, 1.9, z0 + (z1 - z0) * 0.45, red)
	for pz: float in [z0 + (z1 - z0) * 0.5, z1 + 0.2]:
		_b(mb, x1 - 0.12, 0.0, pz - 0.08, x1 + 0.04, 1.6, pz + 0.08, _c(look, "fence_post"))
	var lean: int = 5
	for k in lean:
		var t0: float = float(k) / float(lean)
		var xa: float = lerpf(xm1, x1 + 0.25, t0)
		var xb: float = lerpf(xm1, x1 + 0.25, float(k + 1) / float(lean))
		var y: float = lerpf(2.05, 1.6, t0)
		_b(mb, xa, y, z0 - 0.2, xb, y + 0.14, z1 + 0.45, roof_a if k % 2 == 0 else roof_b)
	_b(mb, xm1, 1.94, z1 + 0.42, x1 + 0.25, 2.0, z1 + 0.5, trim)
	hay_bale(mb, look, Vector3(xm1 + 0.6, 0.0, z0 + 0.5))
	hay_bale(mb, look, Vector3(xm1 + 0.6, 0.5, z0 + 0.5))
	hay_bale(mb, look, Vector3(xm1 + 0.6, 0.0, z0 + 1.1))
	cart(mb, look, Vector3(xm1 + 0.75, 0.0, z1 - 0.6))
	# Windmill behind the barn (north-west corner).
	var wm := Vector2(x0 + 0.1, z0 + 0.15)
	var tower_h: float = 4.6
	var wood: Color = _c(look, "fence_post")
	for p: Vector2 in [Vector2(-0.35, -0.35), Vector2(0.35, -0.35), Vector2(-0.35, 0.35), Vector2(0.35, 0.35)]:
		EstateMeshes._beam(mb, Vector3(wm.x + p.x, 0.0, wm.y + p.y), Vector3(wm.x + p.x * 0.3, tower_h, wm.y + p.y * 0.3), 0.08, wood)
	for k in 4:
		var y: float = 0.9 + float(k) * 0.95
		var s: float = 0.35 * (1.0 - y / tower_h * 0.7)
		_b(mb, wm.x - s, y, wm.y - s, wm.x + s, y + 0.06, wm.y + s, wood)
	var hub := Vector3(wm.x, tower_h + 0.1, wm.y + 0.25)
	_b(mb, hub.x - 0.15, hub.y - 0.15, hub.z - 0.3, hub.x + 0.15, hub.y + 0.15, hub.z + 0.05, _c(look, "metal"))
	for k in 12:
		var a: float = float(k) * TAU / 12.0
		var dir := Vector3(cos(a), sin(a), 0.0)
		mb.add_box(hub + dir * 0.6 + Vector3(0.0, 0.0, 0.08), Vector3(0.12, 0.12, 0.03) + Vector3(absf(dir.x), absf(dir.y), 0.0) * 0.55, _c(look, "blade"))
	_b(mb, hub.x - 0.04, hub.y - 0.06, hub.z - 1.2, hub.x + 0.04, hub.y + 0.06, hub.z - 0.3, wood)
	_b(mb, hub.x - 0.03, hub.y - 0.25, hub.z - 1.3, hub.x + 0.03, hub.y + 0.35, hub.z - 1.15, _c(look, "blade"))
	# By the door: barrel, planter crate, a short fence and a lantern post.
	barrel(mb, look, Vector3(x0 + 0.35, 0.0, z1 + 0.35))
	crate(mb, look, Vector3(x0 + 0.95, 0.0, z1 + 0.35), Color(0, 0, 0, 0))
	for k in 4:
		_b(mb, x0 + 0.75 + float(k) * 0.1, 0.4, z1 + 0.3, x0 + 0.8 + float(k) * 0.1, 0.62, z1 + 0.35, _c(look, "leaf"))
	fence(mb, look, Vector2(float(r.position.x) + 0.1, float(r.end.y) - 0.1), Vector2(xc - 1.2, float(r.end.y) - 0.1))
	lantern(mb, glass, look, Vector3(float(r.position.x) + 0.15, 1.3, float(r.end.y) - 0.35), true)


## The farmer's house on [param rect] (blocks) with the door at [param door_x] on the south
## side: a stone footing, cream plaster walls with dark timber, a porch along the south with
## posts, rails and steps, a red stepped tile roof over the porch, the upper floor with its own
## gable roof and windows with shutters and a flower box, a stone chimney and lanterns.
## Returns the top of the chimney (for the smoke).
static func farmhouse(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, rect: Rect2i, door_x: float) -> Vector3:
	var plaster: Color = _c(look, "plaster")
	var timber: Color = _c(look, "timber")
	var stone: Color = _c(look, "stone")
	var tile_a: Color = _c(look, "roof_tile")
	var tile_b: Color = tile_a.darkened(0.12)
	var wood: Color = _c(look, "porch")
	var x0: float = float(rect.position.x) + 0.1
	var x1: float = float(rect.end.x) - 0.1
	var z0: float = float(rect.position.y) + 0.1
	var z1: float = float(rect.end.y)
	var h1: float = 2.3
	var xc: float = (x0 + x1) * 0.5
	var zc: float = (z0 + z1) * 0.5
	# Ground floor.
	_b(mb, x0 - 0.08, -0.2, z0 - 0.08, x1 + 0.08, 0.3, z1 + 0.04, stone)
	for k in int((x1 - x0) / 0.5):
		_b(mb, x0 + float(k) * 0.5 + 0.02, 0.0, z1 + 0.04, x0 + float(k) * 0.5 + 0.46, 0.28, z1 + 0.06, stone.darkened(0.12 * float(k % 2)))
	_b(mb, x0, 0.3, z0, x1, h1, z1, plaster)
	for px: float in [x0, x1]:
		for pz: float in [z0, z1]:
			_b(mb, px - 0.09, 0.3, pz - 0.09, px + 0.09, h1, pz + 0.09, timber)
	_b(mb, x0, h1 - 0.14, z1, x1, h1, z1 + 0.05, timber)
	_b(mb, x1, h1 - 0.14, z0, x1 + 0.05, h1, z1, timber)
	# Door.
	_b(mb, door_x - 0.5, 0.3, z1, door_x + 0.5, 2.05, z1 + 0.06, timber)
	_b(mb, door_x - 0.42, 0.3, z1 + 0.04, door_x + 0.42, 1.98, z1 + 0.09, _c(look, "door"))
	for k in 3:
		_b(mb, door_x - 0.42 + float(k) * 0.28 + 0.03, 0.35, z1 + 0.09, door_x - 0.42 + float(k) * 0.28 + 0.06, 1.93, z1 + 0.1, _c(look, "door").darkened(0.2))
	_b(mb, door_x + 0.26, 1.05, z1 + 0.09, door_x + 0.32, 1.15, z1 + 0.13, _c(look, "metal"))
	_b(mb, door_x - 0.35, 0.3, z1 + 0.1, door_x + 0.35, 0.33, z1 + 0.5, _c(look, "mat"))
	# Ground floor windows with shutters (south either side of the door, east).
	for wx: float in [lerpf(x0, x1, 0.18), lerpf(x0, x1, 0.84)]:
		if absf(wx - door_x) > 0.9:
			window(mb, glass, look, Vector3(wx, 1.35, z1), false, 0.55, 0.65, true)
	window(mb, glass, look, Vector3(x1, 1.35, zc), true, 0.55, 0.65, true)
	# Porch: deck, posts, rails with balusters (gap at the steps), steps, roof over it.
	var pz1: float = z1 + 1.1
	for k in 4:
		_b(mb, x0 - 0.2, 0.0, z1 + float(k) * 0.275, x1 + 0.2, 0.16, z1 + float(k + 1) * 0.275, wood if k % 2 == 0 else wood.darkened(0.1))
	_b(mb, door_x - 0.55, 0.0, pz1, door_x + 0.55, 0.09, pz1 + 0.3, wood.darkened(0.1))
	var posts: Array[float] = [x0 - 0.1, door_x - 0.65, door_x + 0.65, x1 + 0.1]
	for px: float in posts:
		_b(mb, px - 0.08, 0.16, pz1 - 0.16, px + 0.08, h1 + 0.1, pz1, timber)
		_b(mb, px - 0.2, h1 - 0.15, pz1 - 0.12, px + 0.2, h1 - 0.07, pz1 - 0.04, timber)
	for seg: Vector2 in [Vector2(x0 - 0.1, door_x - 0.65), Vector2(door_x + 0.65, x1 + 0.1)]:
		_b(mb, seg.x, 0.8, pz1 - 0.12, seg.y, 0.88, pz1 - 0.04, timber)
		var count: int = maxi(1, int((seg.y - seg.x) / 0.25))
		for k in count:
			var bx: float = seg.x + (float(k) + 0.5) * (seg.y - seg.x) / float(count)
			_b(mb, bx - 0.03, 0.16, pz1 - 0.1, bx + 0.03, 0.8, pz1 - 0.06, wood.darkened(0.2))
	# Porch roof: stepped tiles sloping down to the south, on all of the front.
	var porch_steps: int = 5
	for k in porch_steps:
		var za: float = lerpf(pz1 + 0.3, z1, float(k) / float(porch_steps))
		var zb: float = lerpf(pz1 + 0.3, z1, float(k + 1) / float(porch_steps))
		var y: float = lerpf(h1 + 0.1, h1 + 0.55, float(k) / float(porch_steps))
		_b(mb, x0 - 0.4, y, minf(za, zb), x1 + 0.4, y + 0.14, maxf(za, zb) + 0.06, tile_a if k % 2 == 0 else tile_b)
	_b(mb, x0 - 0.4, h1 + 0.03, pz1 + 0.24, x1 + 0.4, h1 + 0.12, pz1 + 0.32, timber)
	# Upper floor (set back), its windows and its gable roof (ridge along x).
	var ux0: float = x0 + 0.4
	var ux1: float = x1 - 0.4
	var uz0: float = z0 + 0.3
	var uz1: float = z1 - 0.5
	var h2: float = h1 + 1.55
	_b(mb, ux0, h1, uz0, ux1, h2, uz1, plaster)
	for px: float in [ux0, ux1]:
		_b(mb, px - 0.07, h1, uz1 - 0.07, px + 0.07, h2, uz1 + 0.07, timber)
	_b(mb, ux0, h1 + 0.02, uz1, ux1, h1 + 0.12, uz1 + 0.05, timber)
	_b(mb, ux0, h2 - 0.1, uz1, ux1, h2, uz1 + 0.05, timber)
	EstateMeshes._beam(mb, Vector3(ux0 + 0.1, h1 + 0.12, uz1 + 0.04), Vector3(ux0 + 0.6, h2 - 0.1, uz1 + 0.04), 0.07, timber)
	EstateMeshes._beam(mb, Vector3(ux1 - 0.1, h1 + 0.12, uz1 + 0.04), Vector3(ux1 - 0.6, h2 - 0.1, uz1 + 0.04), 0.07, timber)
	var uxc: float = (ux0 + ux1) * 0.5
	window(mb, glass, look, Vector3(uxc, h1 + 0.85, uz1), false, 0.7, 0.6, true)
	_b(mb, uxc - 0.45, h1 + 0.35, uz1, uxc + 0.45, h1 + 0.5, uz1 + 0.25, _c(look, "porch").darkened(0.2))
	for k in 5:
		var fx: float = uxc - 0.36 + float(k) * 0.18
		_b(mb, fx - 0.06, h1 + 0.5, uz1 + 0.06, fx + 0.06, h1 + 0.62, uz1 + 0.18, _c(look, "leaf") if k % 2 == 0 else _c(look, "flower"))
	window(mb, glass, look, Vector3(ux1, h1 + 0.8, (uz0 + uz1) * 0.5), true, 0.45, 0.5, true)
	var uhalf: float = (uz1 - uz0) * 0.5
	roof(mb, true, ux0, ux1, (uz0 + uz1) * 0.5, gable_steps(uhalf + 0.35, h2, 1.4, 7), 0.3, tile_a, tile_b, plaster, true)
	# Back roof of the ground floor (behind the upper floor) and the east side eave.
	_b(mb, x0 - 0.3, h1, z0 - 0.3, x1 + 0.3, h1 + 0.2, uz0 + 0.05, tile_b)
	_b(mb, ux1 - 0.05, h1, uz0, x1 + 0.3, h1 + 0.2, uz1, tile_a)
	_b(mb, x0 - 0.3, h1, uz0, ux0 + 0.05, h1 + 0.2, uz1, tile_a)
	# Stone chimney on the east end.
	var top: Vector3 = farmhouse_chimney(rect) - Vector3(0.0, 0.15, 0.0)
	_b(mb, top.x - 0.3, h1, top.z - 0.3, top.x + 0.3, top.y, top.z + 0.3, stone)
	for k in int((top.y - h1) / 0.25):
		var y: float = h1 + float(k) * 0.25
		_b(mb, top.x - 0.31 + float(k % 2) * 0.3, y + 0.02, top.z - 0.31, top.x - 0.01 + float(k % 2) * 0.3, y + 0.22, top.z + 0.31, stone.darkened(0.12))
	_b(mb, top.x - 0.36, top.y, top.z - 0.36, top.x + 0.36, top.y + 0.1, top.z + 0.36, stone.darkened(0.3))
	# Lanterns on the porch posts and a lamp post by the path.
	for px: float in [x0 - 0.1, x1 + 0.1]:
		lantern(mb, glass, look, Vector3(px, 1.75, pz1 + 0.12), false)
	lantern(mb, glass, look, Vector3(door_x + 0.2, 1.85, pz1 - 0.05), false)
	# Hay bales and a barrel by the east side.
	hay_bale(mb, look, Vector3(x1 + 0.75, 0.0, z0 + 0.6))
	hay_bale(mb, look, Vector3(x1 + 0.75, 0.5, z0 + 0.6))
	barrel(mb, look, Vector3(x1 + 0.6, 0.0, z0 + 1.4))
	return top + Vector3(0.0, 0.15, 0.0)


## Top of the farmhouse chimney on [param rect] (where the smoke starts).
static func farmhouse_chimney(rect: Rect2i) -> Vector3:
	var ux1: float = float(rect.end.x) - 0.5
	var uz0: float = float(rect.position.y) + 0.4
	var uz1: float = float(rect.end.y) - 0.5
	return Vector3(ux1 - 0.45, 2.3 + 1.55 + 1.75 + 0.15, (uz0 + uz1) * 0.5 - 0.2)


## The dressing of the crop field lot [param r] (door gap at [param door]): a sturdy wooden
## fence, a scarecrow with a straw hat and a red plaid shirt, two lantern posts and crates with
## produce by the gate.
static func field(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i, door: Vector2) -> void:
	var x0: float = float(r.position.x) + 0.15
	var z0: float = float(r.position.y) + 0.15
	var x1: float = float(r.end.x) - 0.15
	var z1: float = float(r.end.y) - 0.15
	var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		# Split the side around the gate when the door is on it.
		var ab: Vector2 = b - a
		var t: float = clampf((door - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var near: Vector2 = a + ab * t
		if near.distance_to(door) < 1.0:
			var gap: float = 1.1 / ab.length()
			if t - gap > 0.0:
				fence(mb, look, a, a + ab * (t - gap))
			if t + gap < 1.0:
				fence(mb, look, a + ab * (t + gap), b)
		else:
			fence(mb, look, a, b)
	# Scarecrow on the west strip.
	var s := Vector3(x0 + 0.55, 0.0, (z0 + z1) * 0.5)
	var straw: Color = _c(look, "hay")
	_b(mb, s.x - 0.05, 0.0, s.z - 0.05, s.x + 0.05, 1.7, s.z + 0.05, _c(look, "fence_post"))
	_b(mb, s.x - 0.05, 1.3, s.z - 0.65, s.x + 0.05, 1.38, s.z + 0.65, _c(look, "fence_post"))
	_b(mb, s.x - 0.14, 0.95, s.z - 0.22, s.x + 0.14, 1.45, s.z + 0.22, _c(look, "plaid"))
	_b(mb, s.x - 0.15, 1.2, s.z - 0.23, s.x + 0.15, 1.26, s.z + 0.23, _c(look, "plaid").darkened(0.35))
	for side: float in [-1.0, 1.0]:
		_b(mb, s.x - 0.1, 1.28, s.z + side * 0.2, s.x + 0.1, 1.42, s.z + side * 0.55, _c(look, "plaid"))
		_b(mb, s.x - 0.07, 1.27, s.z + side * 0.55, s.x + 0.07, 1.4, s.z + side * 0.66, straw)
	_b(mb, s.x - 0.12, 1.45, s.z - 0.12, s.x + 0.12, 1.72, s.z + 0.12, _c(look, "sack"))
	_b(mb, s.x + 0.12, 1.58, s.z - 0.07, s.x + 0.13, 1.62, s.z - 0.03, _c(look, "trim_dark"))
	_b(mb, s.x + 0.12, 1.58, s.z + 0.03, s.x + 0.13, 1.62, s.z + 0.07, _c(look, "trim_dark"))
	_b(mb, s.x - 0.25, 1.72, s.z - 0.25, s.x + 0.25, 1.76, s.z + 0.25, straw)
	_b(mb, s.x - 0.14, 1.76, s.z - 0.14, s.x + 0.14, 1.9, s.z + 0.14, straw.darkened(0.08))
	_b(mb, s.x - 0.145, 1.76, s.z - 0.145, s.x + 0.145, 1.8, s.z + 0.145, _c(look, "plaid"))
	# Lantern posts at the two corners by the gate side, crates with produce by the gate.
	lantern(mb, glass, look, Vector3(x0 + 0.1, 1.6, z0 + 0.1), true)
	lantern(mb, glass, look, Vector3(x1 - 0.55, 1.6, z0 + 0.1), true)
	crate(mb, look, Vector3(door.x - 2.0, 0.0, z0 + 0.45), _c(look, "tomato"))
	crate(mb, look, Vector3(door.x + 2.0, 0.0, z0 + 0.45), _c(look, "carrot"))
