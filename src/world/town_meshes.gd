class_name TownMeshes
extends RefCounted
## Vertex-colored models of the town buildings (Stories 010-018), one mesh per lot, in the cozy
## modern-farm style of the estate: stone base, painted walls, tiled gable roof, glowing windows.
## Each lot has a "site" model used while it is not built: stakes, rope, a sign post and a
## small pile of planks. Colors and sizes come from the "town" group of world_look.json.
##
## Usage:
## [codeblock]
## var glass := MeshBuilder.new()
## var mesh: ArrayMesh = TownMeshes.building(look, "armazem", glass)
## var site: ArrayMesh = TownMeshes.site(look, "armazem")
## [/codeblock]

const GROUP: String = "town"
const WALL_H: float = 2.5
const ROOF_RISE: float = 1.3


## The built model of lot [param id]; window glass goes to [param glass] (it glows at night).
static func building(look: WorldLook, id: String, glass: MeshBuilder) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var r: Rect2i = TownPlan.lot_rect(look, id)
	var south: bool = TownPlan.lot_side(look, id) != TownPlan.Side.NORTH
	match id:
		"prefeitura":
			_townhall(mb, glass, look, r)
		"armazem", "galpao":
			_warehouse(mb, glass, look, r)
		"galinheiro":
			_coop_lot(mb, glass, look, r)
		"curral":
			_corral(mb, look, r)
		"plantacao":
			_lot_fence(mb, look, r, "plantacao")
		"silo":
			_silo(mb, look, r)
		"fabrica_racao":
			_factory(mb, glass, look, r, _c(look, "plank"), _c(look, "roof_green"), true)
		"padaria":
			_factory(mb, glass, look, r, _c(look, "wall_cream"), _c(look, "roof_tile_a"), true)
		"laticinios":
			_factory(mb, glass, look, r, _c(look, "wall_blue"), _c(look, "roof_slate"), false)
		"usina":
			_factory(mb, glass, look, r, _c(look, "brick"), _c(look, "roof_brown"), true)
		"chiqueiro":
			_pen(mb, look, r, "chiqueiro", _c(look, "crop_soil_wet"))
		"ovelhas":
			_pen(mb, look, r, "ovelhas", look.color("colors", "grass_c"))
		"quadro":
			_order_board(mb, look, r)
		"barraca":
			_stall(mb, look, r)
		"roupas":
			_clothes(mb, glass, look, r)
		"restaurante":
			_restaurant(mb, glass, look, r)
		"oficina":
			_workshop(mb, glass, look, r)
		"casa_1":
			_home(mb, glass, look, r, south, _c(look, "wall_blue"), _c(look, "roof_brown"))
		"casa_2":
			_home(mb, glass, look, r, south, _c(look, "wall_green"), _c(look, "roof_tile_a"))
		"casa_3":
			_home(mb, glass, look, r, south, _c(look, "wall_yellow"), _c(look, "roof_blue"))
		"campos":
			_fence_ring(mb, look, r, true)
		"pasto":
			_pasture(mb, look, r)
	return mb.build()


## The building-site model of lot [param id] (shown until the mayor builds it).
static func site(look: WorldLook, id: String) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var r: Rect2i = TownPlan.lot_rect(look, id)
	var stake: Color = _c(look, "site_fence")
	var x0: float = float(r.position.x) + 0.2
	var z0: float = float(r.position.y) + 0.2
	var x1: float = float(r.end.x) - 0.2
	var z1: float = float(r.end.y) - 0.2
	var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var n: int = maxi(1, int(a.distance_to(b) / 1.2))
		for k in n + 1:
			var p: Vector2 = a.lerp(b, float(k) / float(n))
			mb.add_box(Vector3(p.x, 0.35, p.y), Vector3(0.08, 0.7, 0.08), stake)
		EstateMeshes._beam(mb, Vector3(a.x, 0.55, a.y), Vector3(b.x, 0.55, b.y), 0.03, _c(look, "flag_red"))
	var d: Vector2 = TownPlan.lot_door(look, id)
	mb.add_box(Vector3(d.x + 0.9, 0.6, d.y), Vector3(0.1, 1.2, 0.1), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(d.x + 0.9, 1.1, d.y), Vector3(0.9, 0.5, 0.08), _c(look, "sign_color"))
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	for k in 4:
		mb.add_box(Vector3(cx, 0.08 + float(k) * 0.12, cz + float(k % 2) * 0.05), Vector3(1.6, 0.1, 0.35), _c(look, "plank") if k % 2 == 0 else _c(look, "plank_light"))
	return mb.build()


## Top of the chimney of lot [param id] (for smoke), or Vector3.INF when it has none.
static func chimney_top(look: WorldLook, id: String) -> Vector3:
	var r: Rect2i = TownPlan.lot_rect(look, id)
	if id in ["fabrica_racao", "padaria", "usina"]:
		return Vector3(float(r.end.x) - 1.0, WALL_H + ROOF_RISE + 0.9, float(r.position.y) + 1.0)
	if id == "restaurante" or id == "oficina":
		return Vector3(float(r.end.x) - 1.0, WALL_H + ROOF_RISE + 0.9, float(r.position.y) + 1.3)
	return Vector3.INF


# --- shared parts ---

## Base, walls, door, windows and roof. [param south]: the door faces south (+z), else north.
static func _body(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i, south: bool, wall: Color, roof: Color, door: Color, wall_h: float) -> void:
	var x0: float = float(r.position.x) + 0.25
	var z0: float = float(r.position.y) + 0.35
	var x1: float = float(r.end.x) - 0.25
	var z1: float = float(r.end.y) - 0.35
	var lift: float = look.num("estate", "ground_lift")
	var trim: Color = look.color("colors", "wall_trim")
	EstateMeshes._box(mb, x0 - 0.08, -0.3, z0 - 0.08, x1 + 0.08, lift + 0.12, z1 + 0.08, look.color("colors", "stone"))
	EstateMeshes._box(mb, x0, lift, z0, x1, wall_h, z1, wall)
	for px: float in [x0, x1]:
		for pz: float in [z0, z1]:
			EstateMeshes._box(mb, px - 0.07, lift, pz - 0.07, px + 0.07, wall_h, pz + 0.07, trim)
	var zf: float = z1 if south else z0
	var s: float = 1.0 if south else -1.0
	var xc: float = (x0 + x1) * 0.5
	mb.add_box(Vector3(xc, lift + 0.6, zf + s * 0.04), Vector3(0.9, 1.25, 0.08), door)
	mb.add_box(Vector3(xc, lift + 1.27, zf + s * 0.05), Vector3(1.1, 0.1, 0.1), trim)
	mb.add_box(Vector3(xc, lift + 0.05, zf + s * 0.3), Vector3(1.2, 0.1, 0.5), look.color("colors", "stone"))
	mb.add_box(Vector3(xc + 0.3, lift + 0.6, zf + s * 0.09), Vector3(0.07, 0.07, 0.04), look.color("estate", "hub"))
	var wy: float = lift + (wall_h - lift) * 0.58
	for wx: float in [lerpf(x0, x1, 0.2), lerpf(x0, x1, 0.8)]:
		_pane(mb, glass, look, Vector3(wx, wy, zf), Vector3(0.75, 0.7, 0.0), trim)
	for side_x: float in [x0, x1]:
		_pane(mb, glass, look, Vector3(side_x, wy, (z0 + z1) * 0.5), Vector3(0.0, 0.7, 0.75), trim)
	EstateMeshes._gable(mb, x0, x1, z0, z1, wall_h, ROOF_RISE, 0.35, look.integer("estate", "roof_bands"), roof, roof.darkened(0.15), roof.darkened(0.35), wall, trim)


## A window crossing a wall (seen from both sides): frame plus glow-able glass. [param size] has
## the window width on x or z (the other one 0) and the height on y.
static func _pane(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, c: Vector3, size: Vector3, trim: Color) -> void:
	var frame := Vector3(size.x + 0.16 if size.x > 0.0 else 0.1, size.y + 0.16, size.z + 0.16 if size.z > 0.0 else 0.1)
	mb.add_box(c, frame, trim)
	glass.add_box(c, Vector3(size.x if size.x > 0.0 else 0.14, size.y, size.z if size.z > 0.0 else 0.14), look.color("colors", "window"))


static func _chimney(mb: MeshBuilder, look: WorldLook, top: Vector3) -> void:
	EstateMeshes._box(mb, top.x - 0.3, WALL_H, top.z - 0.3, top.x + 0.3, top.y, top.z + 0.3, _c(look, "brick"))
	EstateMeshes._box(mb, top.x - 0.36, top.y - 0.12, top.z - 0.36, top.x + 0.36, top.y, top.z + 0.36, look.color("colors", "stone"))


static func _fence_ring(mb: MeshBuilder, look: WorldLook, r: Rect2i, gate: bool) -> void:
	var wood: Color = look.color("colors", "wood_b")
	var post: Color = look.color("colors", "wood_dark")
	var x0: float = float(r.position.x) + 0.5
	var z0: float = float(r.position.y) + 0.5
	var x1: float = float(r.end.x) - 0.5
	var z1: float = float(r.end.y) - 0.5
	var door: Vector2 = TownPlan.lot_door(look, "campos" if gate else "pasto")
	var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var n: int = int(a.distance_to(b))
		for k in n:
			var p0: Vector2 = a.lerp(b, float(k) / float(n))
			var p1: Vector2 = a.lerp(b, float(k + 1) / float(n))
			var mid: Vector2 = (p0 + p1) * 0.5
			if gate and absf(mid.y - door.y) < 0.8 and absf(mid.x - (door.x - 0.5)) < 0.8:
				continue
			mb.add_box(Vector3(p0.x, 0.4, p0.y), Vector3(0.12, 0.8, 0.12), post)
			EstateMeshes._beam(mb, Vector3(p0.x, 0.55, p0.y), Vector3(p1.x, 0.55, p1.y), 0.07, wood)
			EstateMeshes._beam(mb, Vector3(p0.x, 0.3, p0.y), Vector3(p1.x, 0.3, p1.y), 0.07, wood)


# --- lots ---

static func _townhall(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_body(mb, glass, look, r, true, _c(look, "wall_cream"), _c(look, "roof_slate"), look.color("colors", "door"), WALL_H + 0.4)
	var xc: float = float(r.position.x) + float(r.size.x) * 0.5
	var zf: float = float(r.end.y) - 0.35
	for k in 2:
		mb.add_box(Vector3(xc + (float(k) * 2.0 - 1.0) * 1.0, 1.4, zf + 0.25), Vector3(0.22, 2.8, 0.22), _c(look, "wall_cream").darkened(0.08))
	mb.add_box(Vector3(xc, 2.85, zf + 0.25), Vector3(2.6, 0.2, 0.7), _c(look, "roof_slate"))
	mb.add_box(Vector3(xc, 3.4, zf - 0.02), Vector3(0.7, 0.7, 0.1), look.color("colors", "wall_trim"))
	glass.add_box(Vector3(xc, 3.4, zf + 0.04), Vector3(0.5, 0.5, 0.06), look.color("colors", "window"))
	var pole := Vector3(float(r.position.x) + 0.6, 0.0, float(r.end.y) + 0.2)
	mb.add_box(pole + Vector3(0.0, 2.3, 0.0), Vector3(0.08, 4.6, 0.08), _c(look, "metal"))
	mb.add_box(pole + Vector3(0.55, 4.15, 0.0), Vector3(1.0, 0.25, 0.04), _c(look, "flag_red"))
	mb.add_box(pole + Vector3(0.55, 3.9, 0.0), Vector3(1.0, 0.25, 0.04), _c(look, "flag_white"))
	mb.add_box(pole + Vector3(0.55, 3.65, 0.0), Vector3(1.0, 0.25, 0.04), _c(look, "flag_red"))


static func _warehouse(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_body(mb, glass, look, r, true, _c(look, "plank"), look.color("colors", "roof_a"), look.color("colors", "wood_dark"), WALL_H + 0.3)
	var xc: float = float(r.position.x) + float(r.size.x) * 0.5
	var zf: float = float(r.end.y) - 0.35
	mb.add_box(Vector3(xc, 0.95, zf + 0.06), Vector3(2.0, 1.9, 0.06), look.color("colors", "wood_dark"))
	EstateMeshes._beam(mb, Vector3(xc - 0.95, 0.1, zf + 0.1), Vector3(xc + 0.95, 1.8, zf + 0.1), 0.1, _c(look, "plank_light"))
	EstateMeshes._beam(mb, Vector3(xc + 0.95, 0.1, zf + 0.1), Vector3(xc - 0.95, 1.8, zf + 0.1), 0.1, _c(look, "plank_light"))
	for k in 3:
		var x: float = float(r.end.x) - 0.6 - float(k % 2) * 0.55
		mb.add_box(Vector3(x, 0.25 + float(k / 2) * 0.5, zf + 0.7), Vector3(0.5, 0.5, 0.5), _c(look, "plank_light"))


static func _clothes(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_body(mb, glass, look, r, true, _c(look, "wall_pink"), _c(look, "roof_green"), look.color("estate", "shop_door"), WALL_H)
	var x0: float = float(r.position.x) + 0.25
	var zf: float = float(r.end.y) - 0.35
	glass.add_box(Vector3(x0 + 0.95, 1.2, zf + 0.02), Vector3(1.2, 1.2, 0.14), look.color("colors", "window"))
	for k in 2:
		var mx: float = x0 + 0.6 + float(k) * 0.7
		mb.add_box(Vector3(mx, 0.9, zf - 0.2), Vector3(0.28, 0.6, 0.18), _c(look, "cloth_a") if k == 0 else _c(look, "cloth_b"))
		mb.add_ellipsoid(Vector3(mx, 1.32, zf - 0.2), Vector3(0.12, 0.12, 0.12), look.color("colors", "wall"), look.color("colors", "wall"), 6, 4, true)
	var lx: float = float(r.end.x) + 0.2
	var za: float = float(r.position.y) + 0.6
	var zb: float = float(r.end.y) - 0.6
	for z: float in [za, zb]:
		mb.add_box(Vector3(lx, 0.9, z), Vector3(0.08, 1.8, 0.08), look.color("colors", "wood_dark"))
	EstateMeshes._beam(mb, Vector3(lx, 1.7, za), Vector3(lx, 1.7, zb), 0.02, look.color("colors", "wall"))
	var cloths: Array[Color] = [_c(look, "cloth_a"), _c(look, "cloth_b"), _c(look, "cloth_c")]
	for k in 3:
		mb.add_box(Vector3(lx, 1.4, lerpf(za, zb, 0.25 + 0.25 * float(k))), Vector3(0.04, 0.55, 0.5), cloths[k])


static func _restaurant(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_body(mb, glass, look, r, true, _c(look, "wall_cream"), look.color("colors", "roof_a"), look.color("colors", "door"), WALL_H + 0.2)
	EstateMeshes._box(mb, float(r.position.x) + 0.2, 0.0, float(r.end.y) - 0.42, float(r.end.x) - 0.2, 0.9, float(r.end.y) - 0.28, _c(look, "brick"))
	_chimney(mb, look, chimney_top(look, "restaurante"))
	var zf: float = float(r.end.y) + 0.6
	for k in 2:
		var tx: float = float(r.position.x) + 1.2 + float(k) * (float(r.size.x) - 2.4)
		mb.add_box(Vector3(tx, 0.7, zf), Vector3(1.1, 0.08, 0.7), _c(look, "table"))
		mb.add_box(Vector3(tx, 0.35, zf), Vector3(0.12, 0.7, 0.12), look.color("colors", "wood_dark"))
		for side: float in [-1.0, 1.0]:
			mb.add_box(Vector3(tx, 0.4, zf + side * 0.6), Vector3(1.1, 0.07, 0.28), _c(look, "plank"))
	for k in 3:
		var bx: float = float(r.end.x) + 0.15
		var bz: float = float(r.position.y) + 0.8 + float(k) * 0.75
		mb.add_cone(Vector3(bx, 0.0, bz), 0.3, 0.3, 0.8, _c(look, "barrel"), _c(look, "barrel").lightened(0.15), 10, true)
		mb.add_cone(Vector3(bx, 0.2, bz), 0.32, 0.32, 0.06, look.color("estate", "barrel_band"), look.color("estate", "barrel_band"), 10)
		mb.add_cone(Vector3(bx, 0.6, bz), 0.32, 0.32, 0.06, look.color("estate", "barrel_band"), look.color("estate", "barrel_band"), 10)


static func _workshop(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_body(mb, glass, look, r, true, _c(look, "plank_light"), _c(look, "roof_slate"), look.color("colors", "wood_dark"), WALL_H)
	_chimney(mb, look, chimney_top(look, "oficina"))
	var zf: float = float(r.end.y) + 0.35
	var x0: float = float(r.position.x) + 0.4
	mb.add_box(Vector3(x0 + 0.7, 0.8, zf), Vector3(1.4, 0.1, 0.6), _c(look, "table"))
	for dx: float in [0.1, 1.3]:
		mb.add_box(Vector3(x0 + dx, 0.4, zf), Vector3(0.1, 0.8, 0.5), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(float(r.end.x) - 1.0, 0.25, zf), Vector3(0.35, 0.5, 0.35), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(float(r.end.x) - 1.0, 0.6, zf), Vector3(0.6, 0.2, 0.28), _c(look, "anvil"))
	mb.add_box(Vector3(x0 + 0.4, 0.9, zf), Vector3(0.9, 0.04, 0.04), _c(look, "metal"))
	mb.add_ellipsoid(Vector3(float(r.end.x) - 0.5, 0.45, float(r.end.y) - 0.15), Vector3(0.25, 0.25, 0.25), _c(look, "fire"), _c(look, "fire").lightened(0.3), 6, 4, true)


static func _home(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i, south: bool, wall: Color, roof: Color) -> void:
	_body(mb, glass, look, r, south, wall, roof, look.color("colors", "door"), WALL_H)
	var door: Vector2 = Vector2(float(r.position.x) + float(r.size.x) * 0.5, float(r.end.y) if south else float(r.position.y))
	var s: float = 1.0 if south else -1.0
	var box := Vector3(door.x + 1.4, 0.0, door.y + s * 0.6)
	mb.add_box(box + Vector3(0.0, 0.5, 0.0), Vector3(0.08, 1.0, 0.08), look.color("colors", "wood_dark"))
	mb.add_box(box + Vector3(0.0, 1.05, 0.0), Vector3(0.24, 0.22, 0.38), _c(look, "mailbox"))
	var flowers: Array[Color] = look.color_list("estate", "flowerbox_palette")
	for k in 4:
		var fx: float = door.x - 1.6 + float(k) * 0.3
		mb.add_ellipsoid(Vector3(fx, 0.2, door.y + s * 0.15), Vector3(0.12, 0.12, 0.12), look.color("colors", "bush_dark"), look.color("colors", "bush_light"), 6, 4, true)
		mb.add_ellipsoid(Vector3(fx, 0.32, door.y + s * 0.15), Vector3(0.05, 0.05, 0.05), flowers[k % flowers.size()], flowers[k % flowers.size()], 5, 3, true)


static func _pasture(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_fence_ring(mb, look, r, false)
	var door: Vector2 = TownPlan.lot_door(look, "pasto")
	var tx: float = float(r.end.x) - 1.0
	mb.add_box(Vector3(tx, 0.25, door.y - 1.0), Vector3(0.6, 0.35, 1.4), _c(look, "trough"))
	mb.add_box(Vector3(tx, 0.4, door.y - 1.0), Vector3(0.45, 0.06, 1.2), _c(look, "hay"))
	mb.add_cone(Vector3(tx, 0.0, door.y + 1.0), 0.45, 0.45, 0.45, _c(look, "trough"), _c(look, "trough"), 10)
	mb.add_cone(Vector3(tx, 0.4, door.y + 1.0), 0.4, 0.4, 0.04, _c(look, "water_blue"), _c(look, "water_blue"), 10, true)
	var bx0: float = float(r.position.x) + 1.0
	var bz0: float = float(r.position.y) + 1.0
	EstateMeshes._box(mb, bx0, 0.0, bz0, bx0 + 3.0, 1.8, bz0 + 2.0, look.color("colors", "wood_a"))
	EstateMeshes._gable(mb, bx0, bx0 + 3.0, bz0, bz0 + 2.0, 1.8, 0.8, 0.25, 6, look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), look.color("colors", "wood_a"), look.color("colors", "wood_dark"))
	EstateMeshes._box(mb, bx0 + 1.0, 0.0, bz0 + 1.98, bx0 + 2.0, 1.3, bz0 + 2.04, look.color("colors", "wood_dark"))


# --- farm (2026-11-19 map) ---

## The chicken coop lot: a small red-roofed coop at the back, a fenced yard with a gate at the
## door, a feeder and the egg basket outside the gate.
static func _coop_lot(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_lot_fence(mb, look, r, "galinheiro")
	var x0: float = float(r.position.x) + 0.6
	var z0: float = float(r.position.y) + 0.4
	var x1: float = x0 + 4.0
	var z1: float = z0 + 2.2
	EstateMeshes._box(mb, x0, 0.0, z0, x1, 0.25, z1, look.color("colors", "stone"))
	EstateMeshes._planks(mb, x0, x1, z0, z1, 0.25, 1.9, 8, look.color("estate", "coop_wall"), look.color("estate", "coop_wall").darkened(0.1))
	EstateMeshes._gable(mb, x0, x1, z0, z1, 1.9, 0.9, 0.3, 8, look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), look.color("estate", "coop_wall"), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(x0 + 1.0, 0.75, z1 + 0.03), Vector3(0.6, 0.9, 0.06), look.color("colors", "door"))
	EstateMeshes._beam(mb, Vector3(x0 + 1.0, 0.0, z1 + 0.9), Vector3(x0 + 1.0, 0.35, z1 + 0.05), 0.25, _c(look, "plank"))
	_pane(mb, glass, look, Vector3(x0 + 2.8, 1.2, z1), Vector3(0.6, 0.5, 0.0), look.color("colors", "wall_trim"))
	mb.add_box(Vector3(x1 + 1.2, 0.2, z1 + 0.8), Vector3(1.2, 0.3, 0.4), _c(look, "trough"))
	mb.add_box(Vector3(x1 + 1.2, 0.36, z1 + 0.8), Vector3(1.0, 0.04, 0.3), look.color("estate", "hay"))
	var basket: Vector3 = egg_basket(look)
	mb.add_cone(basket, 0.32, 0.38, 0.28, look.color("estate", "straw").darkened(0.25), look.color("estate", "straw"), 10, false, true)


## Where the egg basket stands (outside the coop gate).
static func egg_basket(look: WorldLook) -> Vector3:
	var d: Vector2 = TownPlan.lot_door(look, "galinheiro")
	return Vector3(d.x - 1.4, 0.0, d.y + 0.2)


## The milking corral: fence with a gate, a roofed milking stall, a feed trough and a water tub.
static func _corral(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_lot_fence(mb, look, r, "curral")
	var x0: float = float(r.position.x) + 0.7
	var z0: float = float(r.position.y) + 0.7
	var post: Color = look.color("colors", "wood_dark")
	for p: Vector2 in [Vector2(x0, z0), Vector2(x0 + 3.0, z0), Vector2(x0, z0 + 2.6), Vector2(x0 + 3.0, z0 + 2.6)]:
		mb.add_box(Vector3(p.x, 1.1, p.y), Vector3(0.14, 2.2, 0.14), post)
	EstateMeshes._gable(mb, x0 - 0.1, x0 + 3.1, z0 - 0.1, z0 + 2.7, 2.2, 0.7, 0.25, 6, look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), _c(look, "plank"), post)
	EstateMeshes._planks(mb, x0, x0 + 3.0, z0, z0 + 0.1, 0.0, 1.2, 4, _c(look, "plank"), _c(look, "plank_light"))
	mb.add_box(Vector3(x0 + 1.5, 0.2, z0 + 1.3), Vector3(0.35, 0.4, 0.35), post)
	var door: Vector2 = TownPlan.lot_door(look, "curral")
	var tx: float = float(r.end.x) - 1.0
	mb.add_box(Vector3(tx, 0.25, door.y - 2.0), Vector3(0.6, 0.35, 1.6), _c(look, "trough"))
	mb.add_box(Vector3(tx, 0.4, door.y - 2.0), Vector3(0.45, 0.06, 1.4), _c(look, "hay"))
	mb.add_cone(Vector3(tx, 0.0, door.y + 1.6), 0.45, 0.45, 0.45, _c(look, "trough"), _c(look, "trough"), 10)
	mb.add_cone(Vector3(tx, 0.4, door.y + 1.6), 0.4, 0.4, 0.04, _c(look, "water_blue"), _c(look, "water_blue"), 10, true)


## The future field (locked at farm level 8): fence, tilled rows and small sprouts.
static func _field(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	_lot_fence(mb, look, r, "plantacao")
	var soil: Color = _c(look, "crop_soil_dry")
	var leaf: Color = _c(look, "crop_leaf")
	var rows: int = r.size.y - 2
	for k in rows:
		var z: float = float(r.position.y) + 1.5 + float(k)
		EstateMeshes._box(mb, float(r.position.x) + 1.0, 0.0, z - 0.32, float(r.end.x) - 1.0, 0.16, z + 0.32, soil.darkened(0.05 * float(k % 2)))
		var n: int = r.size.x - 2
		for i in n:
			var x: float = float(r.position.x) + 1.5 + float(i)
			mb.add_ellipsoid(Vector3(x, 0.24, z), Vector3(0.12, 0.1, 0.12), leaf.darkened(0.2), leaf, 5, 3, true)


## A fence around lot [param id] with a gap at its door.
static func _lot_fence(mb: MeshBuilder, look: WorldLook, r: Rect2i, id: String) -> void:
	var wood: Color = look.color("colors", "wood_b")
	var post: Color = look.color("colors", "wood_dark")
	var x0: float = float(r.position.x) + 0.15
	var z0: float = float(r.position.y) + 0.15
	var x1: float = float(r.end.x) - 0.15
	var z1: float = float(r.end.y) - 0.15
	var door: Vector2 = TownPlan.lot_door(look, id)
	var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var n: int = maxi(1, int(a.distance_to(b)))
		for k in n:
			var p0: Vector2 = a.lerp(b, float(k) / float(n))
			var p1: Vector2 = a.lerp(b, float(k + 1) / float(n))
			var mid: Vector2 = (p0 + p1) * 0.5
			if mid.distance_to(door) < 1.25:
				continue
			mb.add_box(Vector3(p0.x, 0.45, p0.y), Vector3(0.12, 0.9, 0.12), post)
			EstateMeshes._beam(mb, Vector3(p0.x, 0.65, p0.y), Vector3(p1.x, 0.65, p1.y), 0.07, wood)
			EstateMeshes._beam(mb, Vector3(p0.x, 0.35, p0.y), Vector3(p1.x, 0.35, p1.y), 0.07, wood)


## The closed road to the city: barrier posts and a signpost (the striped arm that lifts for the
## truck is built by [DeliveryTruck]).
static func city_gate(look: WorldLook) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var g: Array = look.raw(GROUP, "city_gate")
	var x: float = float(g[0]) + 0.5
	var z0: float = float(g[1])
	var z1: float = float(g[1]) + float(g[3])
	var post: Color = look.color("colors", "wood_dark")
	for z: float in [z0 + 0.2, z1 - 0.2]:
		mb.add_box(Vector3(x, 0.6, z), Vector3(0.18, 1.2, 0.18), post)
	var sign: Array = look.raw(GROUP, "city_sign")
	var s := Vector3(float(sign[0]), 0.0, float(sign[1]))
	mb.add_box(s + Vector3(0.0, 0.8, 0.0), Vector3(0.1, 1.6, 0.1), post)
	mb.add_box(s + Vector3(0.35, 1.4, 0.0), Vector3(0.9, 0.3, 0.06), _c(look, "sign_color"))
	mb.add_triangle(s + Vector3(0.8, 1.25, 0.0), s + Vector3(0.8, 1.55, 0.0), s + Vector3(1.0, 1.4, 0.0), _c(look, "sign_color"), Vector3.BACK)
	return mb.build()


# --- production buildings (2026-11-21) ---

## A round grain silo with a cone roof and a ladder.
static func _silo(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	var c := Vector3(float(r.position.x) + float(r.size.x) * 0.5, 0.0, float(r.position.y) + float(r.size.y) * 0.5)
	var radius: float = minf(float(r.size.x), float(r.size.y)) * 0.42
	mb.add_cone(c, radius, radius, 4.2, _c(look, "wall_cream").darkened(0.05), _c(look, "wall_cream"), 16, false, true)
	for k in 4:
		mb.add_cone(c + Vector3(0.0, 0.6 + float(k) * 1.0, 0.0), radius + 0.03, radius + 0.03, 0.12, _c(look, "metal"), _c(look, "metal"), 16)
	mb.add_cone(c + Vector3(0.0, 4.2, 0.0), radius + 0.15, 0.1, 1.3, _c(look, "roof_tile_a"), _c(look, "roof_tile_b"), 16, false, true)
	var front: float = c.z + radius + 0.03
	for k in 12:
		mb.add_box(Vector3(c.x + 0.3, 0.3 + float(k) * 0.32, front), Vector3(0.4, 0.05, 0.05), _c(look, "metal"))
	mb.add_box(Vector3(c.x, 0.6, front), Vector3(0.6, 1.2, 0.06), look.color("colors", "door"))


## A workshop building with a door on the south and, when [param chimney], a smoking chimney.
static func _factory(mb: MeshBuilder, glass: MeshBuilder, look: WorldLook, r: Rect2i, wall: Color, roof: Color, chimney: bool) -> void:
	_body(mb, glass, look, r, true, wall, roof, look.color("colors", "door"), WALL_H)
	if chimney:
		_chimney(mb, look, Vector3(float(r.end.x) - 1.0, WALL_H + ROOF_RISE + 0.9, float(r.position.y) + 1.0))
	var x: float = float(r.end.x) - 0.5
	var z: float = float(r.end.y) + 0.4
	for k in 2:
		mb.add_box(Vector3(x - float(k) * 0.55, 0.25, z), Vector3(0.5, 0.5, 0.5), _c(look, "plank_light"))


## A fenced animal pen with a gate, a small shelter, a trough and [param ground] floor.
static func _pen(mb: MeshBuilder, look: WorldLook, r: Rect2i, id: String, ground: Color) -> void:
	_lot_fence(mb, look, r, id)
	EstateMeshes._box(mb, float(r.position.x) + 0.3, 0.0, float(r.position.y) + 0.3, float(r.end.x) - 0.3, 0.04, float(r.end.y) - 0.3, ground)
	var x0: float = float(r.position.x) + 0.6
	var z0: float = float(r.position.y) + 0.6
	if id == "chiqueiro":
		z0 = float(r.end.y) - 2.4
	EstateMeshes._box(mb, x0, 0.0, z0, x0 + 2.6, 1.5, z0 + 1.8, look.color("colors", "wood_a"))
	EstateMeshes._gable(mb, x0, x0 + 2.6, z0, z0 + 1.8, 1.5, 0.7, 0.2, 6, look.color("colors", "roof_a"), look.color("colors", "roof_b"), look.color("colors", "roof_ridge"), look.color("colors", "wood_a"), look.color("colors", "wood_dark"))
	mb.add_box(Vector3(float(r.end.x) - 1.2, 0.22, float(r.position.y) + 1.0), Vector3(1.4, 0.3, 0.5), _c(look, "trough"))


## The order board: two posts, a board with paper notes and a little roof.
static func _order_board(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	var c := Vector3(float(r.position.x) + float(r.size.x) * 0.5, 0.0, float(r.position.y) + float(r.size.y) * 0.5)
	var wood: Color = look.color("colors", "wood_dark")
	for dx: float in [-0.8, 0.8]:
		mb.add_box(c + Vector3(dx, 1.0, 0.0), Vector3(0.12, 2.0, 0.12), wood)
	mb.add_box(c + Vector3(0.0, 1.3, 0.0), Vector3(1.8, 1.1, 0.08), look.color("colors", "sign_board"))
	mb.add_box(c + Vector3(0.0, 2.05, 0.0), Vector3(2.1, 0.08, 0.4), look.color("colors", "roof_a"))
	var papers: Array[Color] = [look.color("estate", "paper_a"), look.color("estate", "paper_b"), look.color("estate", "paper_c")]
	for k in 6:
		mb.add_box(c + Vector3(-0.55 + float(k % 3) * 0.55, 1.55 - float(k / 3) * 0.5, 0.06), Vector3(0.4, 0.35, 0.02), papers[k % 3])


## The roadside stall: counter, striped awning on posts, crates and a price sign.
static func _stall(mb: MeshBuilder, look: WorldLook, r: Rect2i) -> void:
	var x0: float = float(r.position.x) + 0.3
	var z0: float = float(r.position.y) + 0.3
	var x1: float = float(r.end.x) - 0.3
	var z1: float = float(r.end.y) - 0.3
	EstateMeshes._box(mb, x0, 0.0, z0 + 0.6, x0 + 0.7, 0.9, z1 - 0.6, _c(look, "plank"))
	EstateMeshes._box(mb, x0 - 0.05, 0.9, z0 + 0.55, x0 + 0.75, 0.98, z1 - 0.55, _c(look, "plank_light"))
	for p: Vector2 in [Vector2(x0, z0), Vector2(x0, z1), Vector2(x1, z0), Vector2(x1, z1)]:
		mb.add_box(Vector3(p.x, 1.1, p.y), Vector3(0.1, 2.2, 0.1), look.color("colors", "wood_dark"))
	var stripes: int = 6
	for k in stripes:
		var za: float = lerpf(z0, z1, float(k) / float(stripes))
		var zb: float = lerpf(z0, z1, float(k + 1) / float(stripes))
		mb.add_quad(Vector3(x1, 2.2, za), Vector3(x1, 2.2, zb), Vector3(x0 - 0.3, 1.9, zb), Vector3(x0 - 0.3, 1.9, za), look.color("estate", "awning_blue") if k % 2 == 0 else look.color("estate", "awning_white"), Vector3(-0.3, 1.0, 0.0))
	for k in 3:
		mb.add_box(Vector3(x0 + 0.35, 1.1, z0 + 0.9 + float(k) * 0.5), Vector3(0.35, 0.22, 0.35), [_c(look, "cloth_c"), _c(look, "flag_red"), _c(look, "crop_leaf")][k])


static func _c(look: WorldLook, key: String) -> Color:
	return look.color(GROUP, key)
