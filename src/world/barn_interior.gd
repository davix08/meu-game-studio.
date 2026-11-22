class_name BarnInterior
extends Node3D
## The inside of the barn ("Celeiro", the galpao lot), 2026-11-22, built like the house inside:
## a separate space far from the farm, seen with two walls cut away. Two floors:
##   - ground floor: plank floor with hay, three horse stalls along the west wall with a horse
##     (the owner's horse model; the first one can be taken out to ride, spot "ride")
##     in each (idle: head and tail move), hay bales and the big door in the north wall;
##   - the loft (upper floor) along the north wall, reached by the stairs on the east side,
##     with the barn chests in a row. Chests fill in order (Production.chest_fill): when one is
##     full the next one takes the goods. Each chest shows its number and how full it is.
## The fisherman walks here through [method is_blocked] / [method floor_height] (the loft and
## the stairs have height). Furniture uses the pixel material of the house. Data: "barn" group.
##
## Usage:
## [codeblock]
## var barn := BarnInterior.new()
## add_child(barn)
## barn.build(look, production)
## fisherman.blocked_fn = barn.is_blocked
## fisherman.height_fn = barn.floor_height
## [/codeblock]

const GROUP: String = "barn"

var _look: WorldLook
var _prod: Production
var _origin: Vector3 = Vector3.ZERO
var _size: Vector2 = Vector2(12.0, 9.0)
var _loft: Rect2 = Rect2(5.0, 0.0, 7.0, 3.5)
var _stairs: Rect2 = Rect2(10.5, 3.5, 1.1, 3.5)
var _loft_h: float = 2.4
var _blocks: Array[Rect2] = []
var _chests: Node3D
var _chest_labels: Array[Label3D] = []
var _shown_chests: int = -1
var _horses: Array[Node3D] = []
var _time: float = 0.0
var _timer: float = 0.0


## Builds the barn at the "barn" origin; [param production] gives the chests.
func build(look: WorldLook, production: Production) -> void:
	_look = look
	_prod = production
	var o: Array = look.raw(GROUP, "origin")
	_origin = Vector3(float(o[0]), 0.0, float(o[1]))
	var sz: Array = look.raw(GROUP, "size")
	_size = Vector2(float(sz[0]), float(sz[1]))
	_loft_h = look.num(GROUP, "loft_height")
	var material: ShaderMaterial = HouseInterior.pixel_material(look)
	var mb := MeshBuilder.new()
	_build_room(mb)
	_build_stalls(mb)
	_build_loft(mb)
	_build_stairs(mb)
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = material
	node.position = _origin
	add_child(node)
	for k in 3:
		var horse: Node3D = AnimalModels.horse_node(look, look.color(GROUP, "horse_%d" % k), material)
		horse.position = _origin + Vector3(1.35, 0.0, 4.5 + float(k) * 1.8)
		horse.rotation.y = PI * 0.5
		add_child(horse)
		_horses.append(horse)
	_chests = Node3D.new()
	_chests.position = _origin
	add_child(_chests)
	var mat_lamp := OmniLight3D.new()
	mat_lamp.light_color = look.color(GROUP, "light")
	mat_lamp.light_energy = look.num(GROUP, "lamp_energy")
	mat_lamp.omni_range = look.num(GROUP, "lamp_range")
	mat_lamp.position = _origin + Vector3(3.5, 2.6, 5.5)
	add_child(mat_lamp)
	var loft_lamp := OmniLight3D.new()
	loft_lamp.light_color = look.color(GROUP, "light")
	loft_lamp.light_energy = look.num(GROUP, "lamp_energy") * 0.8
	loft_lamp.omni_range = look.num(GROUP, "lamp_range") * 0.7
	loft_lamp.position = _origin + Vector3(8.5, _loft_h + 2.0, 2.0)
	add_child(loft_lamp)
	refresh()


func _build_room(mb: MeshBuilder) -> void:
	var w: float = _size.x
	var d: float = _size.y
	var wall_h: float = _look.num(GROUP, "wall_height")
	# Plank floor (strips along x) with hay patches.
	var strips: int = int(d / 0.5)
	for k in strips:
		var c: Color = _c("floor_a") if k % 2 == 0 else _c("floor_b")
		_box(mb, Vector3(w * 0.5, -0.05, 0.25 + float(k) * 0.5), Vector3(w, 0.1, 0.5), c)
	for p: Vector3 in [Vector3(3.6, 0.0, 4.6), Vector3(3.2, 0.0, 7.8), Vector3(7.5, 0.0, 7.6), Vector3(4.2, 0.0, 2.0)]:
		_box(mb, p + Vector3(0.0, 0.015, 0.0), Vector3(1.2, 0.03, 0.8), _c("hay"))
	# North and west walls: red boards with white trim and an X brace.
	_box(mb, Vector3(w * 0.5, wall_h * 0.5, -0.1), Vector3(w + 0.2, wall_h, 0.2), _c("wall"))
	_box(mb, Vector3(-0.1, wall_h * 0.5, d * 0.5), Vector3(0.2, wall_h, d), _c("wall"))
	for k in int(w / 0.75):
		_box(mb, Vector3(0.375 + float(k) * 0.75, wall_h * 0.5, 0.01), Vector3(0.05, wall_h, 0.02), _c("wall").darkened(0.18))
	for k in int(d / 0.75):
		_box(mb, Vector3(0.01, wall_h * 0.5, 0.375 + float(k) * 0.75), Vector3(0.02, wall_h, 0.05), _c("wall").darkened(0.18))
	_box(mb, Vector3(w * 0.5, wall_h - 0.08, 0.03), Vector3(w, 0.16, 0.06), _c("trim"))
	_box(mb, Vector3(0.03, wall_h - 0.08, d * 0.5), Vector3(0.06, 0.16, d), _c("trim"))
	_box(mb, Vector3(w * 0.5, 0.08, 0.03), Vector3(w, 0.16, 0.06), _c("trim"))
	_box(mb, Vector3(0.03, 0.08, d * 0.5), Vector3(0.06, 0.16, d), _c("trim"))
	# Low edge on the open sides.
	_box(mb, Vector3(w * 0.5, 0.1, d + 0.05), Vector3(w + 0.2, 0.2, 0.1), _c("wood_dark"))
	_box(mb, Vector3(w + 0.05, 0.1, d * 0.5), Vector3(0.1, 0.2, d), _c("wood_dark"))
	# Big barn door (north wall) with the white X.
	var door: Vector2 = door_spot()
	_box(mb, Vector3(door.x, 1.2, 0.05), Vector3(1.8, 2.4, 0.08), _c("door"))
	_box(mb, Vector3(door.x, 1.2, 0.1), Vector3(1.8, 0.12, 0.02), _c("trim"))
	_box(mb, Vector3(door.x, 2.36, 0.1), Vector3(1.8, 0.1, 0.02), _c("trim"))
	_box(mb, Vector3(door.x - 0.85, 1.2, 0.1), Vector3(0.1, 2.4, 0.02), _c("trim"))
	_box(mb, Vector3(door.x + 0.85, 1.2, 0.1), Vector3(0.1, 2.4, 0.02), _c("trim"))
	# Window in the west wall, above the stalls.
	_box(mb, Vector3(0.05, 2.1, 6.3), Vector3(0.08, 0.8, 1.2), _c("trim"))
	_box(mb, Vector3(0.09, 2.1, 6.3), Vector3(0.04, 0.65, 1.05), _c("window"))
	# Hay bales and a pitchfork on the ground floor.
	for r: Rect2 in [Rect2(6.0, 5.2, 1.2, 0.8), Rect2(6.2, 6.3, 0.9, 0.7)]:
		_furniture(mb, r, 0.6, _c("hay_bale"))
		_box(mb, Vector3(r.get_center().x, 0.3, r.end.y + 0.005), Vector3(r.size.x, 0.05, 0.01), _c("hay_bale").darkened(0.3))
	_box(mb, Vector3(7.1, 1.0, 5.2), Vector3(0.05, 1.6, 0.05), _c("wood"))
	_box(mb, Vector3(7.1, 1.85, 5.2), Vector3(0.3, 0.08, 0.04), _c("metal"))


func _build_stalls(mb: MeshBuilder) -> void:
	var x1: float = 2.7
	var z0: float = 3.6
	_blocks.append(Rect2(0.0, z0, x1, _size.y - z0))
	for k in 4:
		var z: float = z0 + float(k) * 1.8
		if z > _size.y:
			break
		_box(mb, Vector3(x1 * 0.5, 0.45, z), Vector3(x1, 0.9, 0.1), _c("wood"))
		_box(mb, Vector3(x1 * 0.5, 0.92, z), Vector3(x1, 0.06, 0.14), _c("wood_dark"))
	# Front rail of each stall, with a gap at the head; feed trough and water bucket.
	for k in 3:
		var zc: float = z0 + 0.9 + float(k) * 1.8
		_box(mb, Vector3(x1, 0.45, zc - 0.55), Vector3(0.1, 0.9, 0.7), _c("wood"))
		_box(mb, Vector3(x1, 0.45, zc + 0.55), Vector3(0.1, 0.9, 0.7), _c("wood"))
		_box(mb, Vector3(0.3, 0.45, zc - 0.4), Vector3(0.45, 0.3, 0.6), _c("wood_dark"))
		_box(mb, Vector3(0.3, 0.6, zc - 0.4), Vector3(0.38, 0.04, 0.5), _c("hay"))
		_box(mb, Vector3(0.35, 0.18, zc + 0.55), Vector3(0.3, 0.36, 0.3), _c("metal"))
		_box(mb, Vector3(0.35, 0.36, zc + 0.55), Vector3(0.24, 0.01, 0.24), _c("water"))
		_box(mb, Vector3(1.3, 0.02, zc), Vector3(2.2, 0.04, 1.6), _c("hay"))


func _build_loft(mb: MeshBuilder) -> void:
	var l: Rect2 = _loft
	var h: float = _loft_h
	# Loft floor (planks), beams under it and posts.
	for k in int(l.size.y / 0.5):
		var c: Color = _c("floor_a") if k % 2 == 0 else _c("floor_b")
		_box(mb, Vector3(l.get_center().x, h - 0.08, l.position.y + 0.25 + float(k) * 0.5), Vector3(l.size.x, 0.16, 0.5), c)
	_box(mb, Vector3(l.get_center().x, h - 0.25, l.end.y - 0.1), Vector3(l.size.x, 0.2, 0.2), _c("wood_dark"))
	for x: float in [l.position.x + 0.1, l.position.x + 2.5, l.position.x + 5.0]:
		_box(mb, Vector3(x, (h - 0.2) * 0.5, l.end.y - 0.1), Vector3(0.18, h - 0.2, 0.18), _c("wood_dark"))
	# Railings on the open edges of the loft.
	var rail_h: float = 0.9
	_box(mb, Vector3((l.position.x + _stairs.position.x) * 0.5, h + rail_h, l.end.y - 0.05), Vector3(_stairs.position.x - l.position.x, 0.08, 0.08), _c("wood"))
	_box(mb, Vector3(l.position.x + 0.05, h + rail_h, l.get_center().y), Vector3(0.08, 0.08, l.size.y), _c("wood"))
	var x: float = l.position.x
	while x <= _stairs.position.x:
		_box(mb, Vector3(x, h + rail_h * 0.5, l.end.y - 0.05), Vector3(0.07, rail_h, 0.07), _c("wood"))
		x += 0.7
	var z: float = 0.0
	while z <= l.end.y:
		_box(mb, Vector3(l.position.x + 0.05, h + rail_h * 0.5, z), Vector3(0.07, rail_h, 0.07), _c("wood"))
		z += 0.7
	_blocks.append(Rect2(l.position.x, l.end.y - 0.1, _stairs.position.x - l.position.x, 0.2))
	_blocks.append(Rect2(l.position.x - 0.1, 0.0, 0.2, l.end.y))
	# The chest row against the north wall of the loft.
	_blocks.append(Rect2(l.position.x + 0.3, 0.0, _stairs.position.x - l.position.x - 0.5, 0.85))
	# Under the loft: stacked hay (scenery, the space below is not walkable).
	for p: Vector3 in [Vector3(6.2, 0.3, 1.0), Vector3(7.4, 0.3, 1.0), Vector3(6.8, 0.9, 1.0), Vector3(9.3, 0.3, 1.2)]:
		_box(mb, p, Vector3(1.1, 0.6, 1.4), _c("hay_bale"))


func _build_stairs(mb: MeshBuilder) -> void:
	var s: Rect2 = _stairs
	var steps: int = _look.integer(GROUP, "stair_steps")
	var step_d: float = s.size.y / float(steps)
	for k in steps:
		var top: float = _loft_h * float(k + 1) / float(steps)
		var zc: float = s.end.y - step_d * (float(k) + 0.5)
		_box(mb, Vector3(s.get_center().x, top - 0.06, zc), Vector3(s.size.x, 0.12, step_d), _c("wood"))
		_box(mb, Vector3(s.get_center().x, (top - 0.12) * 0.5, zc), Vector3(s.size.x - 0.1, top - 0.12, step_d * 0.9), _c("wood_dark"))
	# Hand rail on the open (west) side.
	for k in 4:
		var t: float = float(k) / 3.0
		var zp: float = lerpf(s.end.y - 0.2, s.position.y + 0.2, t)
		var base: float = _loft_h * (s.end.y - zp) / s.size.y
		_box(mb, Vector3(s.position.x, base + 0.45, zp), Vector3(0.07, 0.9, 0.07), _c("wood"))
	_blocks.append(Rect2(s.position.x - 0.1, s.position.y + 0.1, 0.1, s.size.y - 0.6))


## Shows one chest per [method Production.chest_count] on the loft, with "Baú n" and its
## fill above it. Called when the goods change and every second.
func refresh() -> void:
	if _prod == null:
		return
	var n: int = _prod.chest_count()
	if n != _shown_chests:
		_shown_chests = n
		for child: Node in _chests.get_children():
			child.free()
		_chest_labels.clear()
		var mb := MeshBuilder.new()
		for i in n:
			var c: Vector3 = chest_position(i)
			_box(mb, c + Vector3(0.0, 0.25, 0.0), Vector3(0.8, 0.5, 0.55), _c("chest"))
			_box(mb, c + Vector3(0.0, 0.58, 0.0), Vector3(0.84, 0.16, 0.59), _c("chest").darkened(0.12))
			for dx: float in [-0.28, 0.28]:
				_box(mb, c + Vector3(dx, 0.33, 0.0), Vector3(0.07, 0.68, 0.6), _c("metal"))
			_box(mb, c + Vector3(0.0, 0.45, 0.29), Vector3(0.12, 0.14, 0.03), _c("lock"))
			var label := Label3D.new()
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 40
			label.outline_size = 10
			label.pixel_size = 0.006
			label.position = c + Vector3(0.0, 1.05, 0.0)
			_chests.add_child(label)
			_chest_labels.append(label)
		var node := MeshInstance3D.new()
		node.mesh = mb.build()
		node.material_override = HouseInterior.pixel_material(_look)
		_chests.add_child(node)
	for i in n:
		var fill: Vector2i = _prod.chest_fill(i)
		var full: bool = fill.x >= fill.y
		_chest_labels[i].text = Texts.fmt("chest_label", [i + 1, fill.x, fill.y])
		_chest_labels[i].modulate = _look.color(GROUP, "chest_full") if full else (_look.color(GROUP, "chest_used") if fill.x > 0 else Color.WHITE)


## Hides the horse of the first stall while it is out riding (shown again when put back).
func set_horse_out(out: bool) -> void:
	if not _horses.is_empty():
		_horses[0].visible = not out


## Where chest [param i] stands (room meters, on the loft floor).
func chest_position(i: int) -> Vector3:
	var n: int = maxi(1, _shown_chests)
	var span: float = _stairs.position.x - _loft.position.x - 1.0
	var x: float = _loft.position.x + 0.8 + (span * (float(i) + 0.5) / float(n))
	return Vector3(x, _loft_h, 0.55)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for k in _horses.size():
		var horse: Node3D = _horses[k]
		var t: float = _time + float(k) * 1.7
		if horse.get_child_count() >= 3:
			(horse.get_child(1) as Node3D).rotation.x = 0.12 + sin(t * 0.8) * 0.12 + maxf(0.0, sin(t * 0.23)) * 0.5
			(horse.get_child(2) as Node3D).rotation.z = sin(t * 2.1) * 0.25
		else:
			# One-mesh horse: breathing and a slow nod of the whole body.
			var body: Node3D = horse.get_child(0)
			body.scale = Vector3(1.0, 1.0 + sin(t * 1.3) * 0.012, 1.0)
			body.rotation.x = maxf(0.0, sin(t * 0.23)) * 0.04
	_timer -= delta
	if _timer <= 0.0:
		_timer = 1.0
		refresh()


## True when the fisherman at (x, z) (world meters) hits a wall, a stall, a rail or a bale.
func is_blocked(x: float, z: float) -> bool:
	var p := Vector2(x - _origin.x, z - _origin.z)
	var r: float = 0.25
	if p.x < 0.35 or p.y < 0.35 or p.x > _size.x - r or p.y > _size.y - r:
		return true
	for b: Rect2 in _blocks:
		if b.grow(r).has_point(p):
			return true
	return false


## Floor height: the loft is up, the stairs climb from the ground to it, the rest is ground.
func floor_height(x: float, z: float) -> float:
	var p := Vector2(x - _origin.x, z - _origin.z)
	if _stairs.has_point(p):
		return _loft_h * clampf((_stairs.end.y - p.y) / _stairs.size.y, 0.0, 1.0)
	if _loft.has_point(p):
		return _loft_h
	return 0.0


## Where the fisherman appears when he comes in (world meters, x z).
func entry() -> Vector2:
	return Vector2(_origin.x, _origin.z) + door_spot() + Vector2(0.0, 1.0)


## The door (room meters).
func door_spot() -> Vector2:
	return Vector2(3.0, 0.0)


## Spots (world meters) for the context button: "door" and "chests" (in front of them).
func spot(name: String) -> Vector2:
	var o := Vector2(_origin.x, _origin.z)
	match name:
		"door":
			return o + door_spot() + Vector2(0.0, 0.9)
		"chests":
			return o + Vector2(_loft.get_center().x - 0.5, 1.7)
		"ride":
			return o + Vector2(3.2, 4.5)
	return o


## The room bounds in world meters (for the camera).
func bounds() -> Rect2:
	return Rect2(Vector2(_origin.x, _origin.z), _size)


func _furniture(mb: MeshBuilder, r: Rect2, height: float, color: Color) -> void:
	_box(mb, Vector3(r.get_center().x, height * 0.5, r.get_center().y), Vector3(r.size.x, height, r.size.y), color)
	_blocks.append(r)


func _box(mb: MeshBuilder, center: Vector3, size: Vector3, color: Color) -> void:
	mb.add_box(center, size, color)


func _c(key: String) -> Color:
	return _look.color(GROUP, key)
