class_name HouseInterior
extends Node3D
## The inside of the farmer's house (2026-11-22), a separate little space far from the farm: a
## warm room seen from the isometric camera with two walls cut away. It has a checkered floor
## and wainscoted walls, a kitchen corner (fridge, stove with hood, counters, cabinets), a table
## with chairs, a rug, a sofa, a floor lamp with a warm light, a window, the bed and the door.
## The fisherman walks here through [member Fisherman.blocked_fn] / [member Fisherman.height_fn];
## the bed is where he sleeps, the sofa where he rests. Sizes and colors: "interior" group.
##
## Usage:
## [codeblock]
## var house := HouseInterior.new()
## add_child(house)
## house.build(look)
## fisherman.blocked_fn = house.is_blocked
## [/codeblock]

var _look: WorldLook
var _origin: Vector3 = Vector3.ZERO
var _size: Vector2 = Vector2(10.0, 8.0)
var _blocks: Array[Rect2] = []
var _lamp: OmniLight3D


## Builds the room at the "interior" origin.
func build(look: WorldLook) -> void:
	_look = look
	var o: Array = look.raw("interior", "origin")
	_origin = Vector3(float(o[0]), 0.0, float(o[1]))
	var sz: Array = look.raw("interior", "size")
	_size = Vector2(float(sz[0]), float(sz[1]))
	var mb := MeshBuilder.new()
	var w: float = _size.x
	var d: float = _size.y
	var wall_h: float = look.num("interior", "wall_height")
	# Floor: checkered tiles.
	for z in int(d):
		for x in int(w):
			var c: Color = _c("tile_a") if (x + z) % 2 == 0 else _c("tile_b")
			_box(mb, Vector3(x + 0.5, -0.05, z + 0.5), Vector3(1.0, 0.1, 1.0), c)
	# Back walls (north and west) with a wooden wainscot and a top trim.
	_box(mb, Vector3(w * 0.5, wall_h * 0.5, -0.1), Vector3(w + 0.2, wall_h, 0.2), _c("wall"))
	_box(mb, Vector3(-0.1, wall_h * 0.5, d * 0.5), Vector3(0.2, wall_h, d), _c("wall"))
	_box(mb, Vector3(w * 0.5, 0.45, 0.02), Vector3(w, 0.9, 0.06), _c("wood_dark"))
	_box(mb, Vector3(0.02, 0.45, d * 0.5), Vector3(0.06, 0.9, d), _c("wood_dark"))
	_box(mb, Vector3(w * 0.5, wall_h - 0.05, 0.03), Vector3(w, 0.1, 0.08), _c("wood"))
	_box(mb, Vector3(0.03, wall_h - 0.05, d * 0.5), Vector3(0.08, 0.1, d), _c("wood"))
	# Low edge on the open sides so the room reads as a cutaway.
	_box(mb, Vector3(w * 0.5, 0.1, d + 0.05), Vector3(w + 0.2, 0.2, 0.1), _c("wood_dark"))
	_box(mb, Vector3(w + 0.05, 0.1, d * 0.5), Vector3(0.1, 0.2, d), _c("wood_dark"))
	# Door in the north wall (right side), red with panels.
	var door: Vector2 = door_spot()
	_box(mb, Vector3(door.x, 1.05, 0.06), Vector3(1.0, 2.1, 0.08), _c("door"))
	for k in 2:
		_box(mb, Vector3(door.x, 0.6 + float(k) * 0.9, 0.11), Vector3(0.7, 0.6, 0.02), _c("door").darkened(0.2))
	_box(mb, Vector3(door.x + 0.35, 1.0, 0.13), Vector3(0.06, 0.06, 0.04), _c("metal"))
	# Kitchen corner along the north wall: fridge, counters, stove with hood, cabinets.
	_furniture(mb, Rect2(0.3, 0.2, 0.9, 0.8), 1.9, _c("fridge"))
	_box(mb, Vector3(0.75, 1.3, 0.62), Vector3(0.05, 0.4, 0.04), _c("metal"))
	_furniture(mb, Rect2(1.2, 0.2, 2.6, 0.7), 0.9, _c("wood"))
	_box(mb, Vector3(2.5, 0.92, 0.55), Vector3(2.6, 0.06, 0.74), _c("counter"))
	_box(mb, Vector3(2.0, 0.96, 0.55), Vector3(0.7, 0.04, 0.5), _c("metal"))
	_furniture(mb, Rect2(3.8, 0.2, 0.8, 0.7), 0.9, _c("stove"))
	_box(mb, Vector3(4.2, 1.7, 0.4), Vector3(0.9, 0.5, 0.5), _c("hood"))
	_box(mb, Vector3(2.5, 2.0, 0.3), Vector3(2.6, 0.7, 0.4), _c("wood"))
	for k in 3:
		_box(mb, Vector3(1.6 + float(k) * 0.9, 2.0, 0.51), Vector3(0.8, 0.6, 0.02), _c("wood_dark"))
	_box(mb, Vector3(5.6, 1.7, 0.03), Vector3(0.5, 0.5, 0.04), _c("metal"))
	# Table with four chairs, a jug and cups.
	var t := Vector2(5.4, 4.6)
	_furniture(mb, Rect2(t.x - 1.0, t.y - 0.5, 2.0, 1.0), 0.78, _c("wood_dark"))
	_box(mb, Vector3(t.x - 0.3, 0.86, t.y), Vector3(0.14, 0.14, 0.14), _c("counter"))
	_box(mb, Vector3(t.x + 0.4, 0.84, t.y - 0.1), Vector3(0.1, 0.1, 0.1), _c("counter"))
	for p: Vector2 in [Vector2(-0.6, -0.8), Vector2(0.6, -0.8), Vector2(-0.6, 0.8), Vector2(0.6, 0.8)]:
		var cpos := Vector3(t.x + p.x, 0.0, t.y + p.y)
		_box(mb, cpos + Vector3(0.0, 0.45, 0.0), Vector3(0.45, 0.06, 0.45), _c("wood_dark"))
		_box(mb, cpos + Vector3(0.0, 0.78, signf(p.y) * 0.2), Vector3(0.45, 0.6, 0.06), _c("wood_dark"))
		for q: Vector2 in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
			_box(mb, cpos + Vector3(q.x, 0.22, q.y), Vector3(0.05, 0.45, 0.05), _c("wood_dark"))
	# Rug, sofa and the floor lamp.
	_box(mb, Vector3(2.4, 0.01, 5.6), Vector3(3.0, 0.02, 2.2), _c("rug"))
	_box(mb, Vector3(2.4, 0.015, 5.6), Vector3(2.6, 0.02, 1.8), _c("rug").lightened(0.15))
	var sofa: Rect2 = sofa_rect()
	_furniture(mb, sofa, 0.45, _c("sofa"))
	_box(mb, Vector3(sofa.position.x + 0.15, 0.75, sofa.get_center().y), Vector3(0.3, 0.6, sofa.size.y), _c("sofa").darkened(0.15))
	for k in 2:
		_box(mb, Vector3(sofa.get_center().x, 0.6, sofa.position.y + float(k) * (sofa.size.y - 0.25) + 0.12), Vector3(sofa.size.x, 0.35, 0.25), _c("sofa").darkened(0.1))
	var lamp := Vector3(0.6, 0.0, 6.9)
	_box(mb, lamp + Vector3(0.0, 0.03, 0.0), Vector3(0.35, 0.06, 0.35), _c("metal"))
	_box(mb, lamp + Vector3(0.0, 0.85, 0.0), Vector3(0.06, 1.7, 0.06), _c("metal"))
	_box(mb, lamp + Vector3(0.0, 1.8, 0.0), Vector3(0.45, 0.35, 0.45), _c("lampshade"))
	_blocks.append(Rect2(lamp.x - 0.3, lamp.z - 0.3, 0.6, 0.6))
	# Window in the west wall with light coming in.
	_box(mb, Vector3(0.05, 1.5, 3.4), Vector3(0.08, 1.1, 1.3), _c("wood"))
	_box(mb, Vector3(0.09, 1.5, 3.4), Vector3(0.04, 0.95, 1.15), _c("window"))
	# Bed against the west wall, with pillow and blanket.
	var bed: Rect2 = bed_rect()
	_furniture(mb, bed, 0.45, _c("wood_dark"))
	_box(mb, Vector3(bed.get_center().x, 0.55, bed.get_center().y), Vector3(bed.size.x - 0.1, 0.2, bed.size.y - 0.1), _c("sheet"))
	_box(mb, Vector3(bed.position.x + 0.35, 0.72, bed.get_center().y), Vector3(0.45, 0.14, bed.size.y - 0.3), _c("pillow"))
	_box(mb, Vector3(bed.get_center().x + 0.3, 0.67, bed.get_center().y), Vector3(bed.size.x - 0.8, 0.08, bed.size.y), _c("blanket"))
	_box(mb, Vector3(bed.position.x + 0.05, 0.85, bed.get_center().y), Vector3(0.1, 1.0, bed.size.y), _c("wood_dark"))
	# A cupboard with plates by the west wall.
	_furniture(mb, Rect2(0.2, 1.4, 0.6, 1.2), 1.6, _c("wood"))
	for k in 3:
		_box(mb, Vector3(0.82, 0.5 + float(k) * 0.45, 2.0), Vector3(0.02, 0.35, 1.0), _c("wood_dark"))
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = MeshBuilder.make_material(0.8)
	node.position = _origin
	add_child(node)
	_lamp = OmniLight3D.new()
	_lamp.light_color = _c("light")
	_lamp.light_energy = look.num("interior", "lamp_energy")
	_lamp.omni_range = look.num("interior", "lamp_range")
	_lamp.position = _origin + lamp + Vector3(0.4, 1.7, -0.4)
	add_child(_lamp)
	var window_light := OmniLight3D.new()
	window_light.light_color = _c("window_light")
	window_light.light_energy = look.num("interior", "window_energy")
	window_light.omni_range = 4.0
	window_light.position = _origin + Vector3(1.2, 1.5, 3.4)
	add_child(window_light)


## True when the fisherman box at (x, z) (world meters) hits a wall or furniture.
func is_blocked(x: float, z: float) -> bool:
	var p := Vector2(x - _origin.x, z - _origin.z)
	var r: float = 0.25
	if p.x < 0.35 or p.y < 0.35 or p.x > _size.x - r or p.y > _size.y - r:
		return true
	for b: Rect2 in _blocks:
		if b.grow(r).has_point(p):
			return true
	return false


## Floor height inside (0).
func floor_height(_x: float, _z: float) -> float:
	return 0.0


## Where the fisherman appears when he comes in (world meters, x z).
func entry() -> Vector2:
	return Vector2(_origin.x, _origin.z) + door_spot() + Vector2(0.0, 1.0)


## The door (room meters).
func door_spot() -> Vector2:
	return Vector2(_size.x - 1.6, 0.0)


## The bed (room meters).
func bed_rect() -> Rect2:
	return Rect2(0.2, 5.0, 2.2, 1.4)


## The sofa (room meters).
func sofa_rect() -> Rect2:
	return Rect2(3.0, 6.6, 2.4, 0.9)


## Spots (world meters) for the context button: door, bed side, sofa.
func spot(name: String) -> Vector2:
	var o := Vector2(_origin.x, _origin.z)
	match name:
		"door":
			return o + door_spot() + Vector2(0.0, 0.9)
		"bed":
			return o + Vector2(bed_rect().end.x + 0.4, bed_rect().get_center().y)
		"sofa":
			return o + Vector2(sofa_rect().get_center().x, sofa_rect().position.y - 0.5)
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
	return _look.color("interior", key)
