class_name DeliveryTruck
extends Node3D
## The delivery truck (2026-11-19 farm map): a small blue pickup with cardboard boxes in the bed,
## built in code in a chunky pixel style (vertex colors plus the pixel texture shader). When the
## player orders by phone ([Farm.order_good], [Farm.order_animal]) it comes in on the road from
## the city (the barrier lifts), drives along the dirt roads to each destination, stops, leaves a
## box at the door (shed for goods, coop or corral for animals) and drives away.
## It also draws the boxes waiting to be opened, with a label of what is inside.
##
## Usage:
## [codeblock]
## var truck := DeliveryTruck.new()
## add_child(truck)
## truck.setup(look, town_data, state, farm, grid, terrain)
## for spot: Vector2 in truck.box_spots(): print(spot)
## [/codeblock]

enum Mode { IDLE, DRIVE, UNLOAD, LEAVE }

var _look: WorldLook
var _town: TownData
var _state: GameState
var _farm: Farm
var _grid: WorldGrid
var _terrain: LakeTerrain
var _body: Node3D
var _wheels: Array[Node3D] = []
var _cargo: Array[Node3D] = []
var _arm: Node3D
var _gate_x: float = 0.0
var _gate_z: float = 0.0
var _start := Vector2.ZERO
var _mode: Mode = Mode.IDLE
var _wait: float = 0.0
var _path: Array[Vector2] = []
var _path_i: int = 0
var _pos := Vector2.ZERO
var _heading: float = 0.0
var _stops: Array[String] = []
var _unload_t: float = 0.0
var _dropped: bool = false
var _speed: float = 5.0
var _box_root: Node3D
var _box_mesh: ArrayMesh
var _material: ShaderMaterial
var _pickups: int = 0


## Builds the truck, the barrier arm and the box drawing.
func setup(look: WorldLook, town: TownData, state: GameState, farm: Farm, grid: WorldGrid, terrain: LakeTerrain) -> void:
	_look = look
	_town = town
	_state = state
	_farm = farm
	_grid = grid
	_terrain = terrain
	_speed = town.num("farm_life", "truck_speed")
	var s: Array = look.raw("farm", "truck_start")
	_start = Vector2(float(s[0]), float(s[1]))
	_material = ShaderMaterial.new()
	_material.shader = load(look.text("player", "model_shader")) as Shader
	_material.set_shader_parameter("pixel_tex", load(look.text("player", "model_texture")) as Texture2D)
	_material.set_shader_parameter("texel_scale", look.num("truck", "texel_scale"))
	_material.set_shader_parameter("detail", look.num("truck", "texture_detail"))
	_material.set_shader_parameter("colors_srgb", 1.0)
	_build_truck()
	_build_arm()
	_box_root = Node3D.new()
	add_child(_box_root)
	_box_mesh = _crate_mesh()
	_body.visible = false
	state.town_changed.connect(_draw_boxes)
	_draw_boxes()


## An order of the board was delivered: the truck comes to take its box (2026-11-21).
func pickup() -> void:
	_pickups += 1


## Where each waiting box is (meters, x z), in [member GameState.boxes] order.
func box_spots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var per_dest: Dictionary = {}
	for box: Dictionary in _state.boxes:
		var dest: String = str(box["dest"])
		var k: int = int(per_dest.get(dest, 0))
		per_dest[dest] = k + 1
		out.append(_drop_point(dest) + Vector2(float(k) * 0.8 - 0.4, 0.0))
	return out


## Short text of what is inside box [param index].
func box_text(index: int) -> String:
	var items: Dictionary = _state.boxes[index]["items"]
	var parts: PackedStringArray = PackedStringArray()
	for id: Variant in items:
		var name: String = _town.good_name(str(id))
		if not _town.animal(str(id)).is_empty():
			name = str(_town.animal(str(id))["name"])
		parts.append("%s ×%d" % [name, int(items[id])])
	return ", ".join(parts)


func _process(delta: float) -> void:
	_update_arm(delta)
	match _mode:
		Mode.IDLE:
			if _farm.order_destinations().is_empty() and _pickups == 0:
				_wait = 0.0
				return
			_wait += delta
			if _wait >= _town.num("farm_life", "truck_delay_seconds"):
				_wait = 0.0
				_stops = _farm.order_destinations()
				var pickup_now: bool = _pickups > 0
				if pickup_now:
					_stops.append("@quadro")
				_pos = _start
				_heading = -PI * 0.5
				_body.visible = true
				var delivering: int = _stops.size() - (1 if pickup_now else 0)
				for k in _cargo.size():
					_cargo[k].visible = k < delivering
				_go_to(_stop_cell(_stops[0]))
				_mode = Mode.DRIVE
		Mode.DRIVE, Mode.LEAVE:
			if _drive(delta):
				if _mode == Mode.LEAVE:
					_body.visible = false
					_mode = Mode.IDLE
				else:
					_unload_t = 0.0
					_dropped = false
					_mode = Mode.UNLOAD
		Mode.UNLOAD:
			_unload_t += delta
			var total: float = _town.num("farm_life", "truck_unload_seconds")
			if not _dropped and _unload_t >= total * 0.5:
				_dropped = true
				if _stops[0].begins_with("@"):
					_pickups = 0
					for c: Node3D in _cargo:
						if not c.visible:
							c.visible = true
							break
				else:
					_farm.drop_box(_stops[0])
					for c: Node3D in _cargo:
						if c.visible:
							c.visible = false
							break
			if _unload_t >= total:
				_stops.remove_at(0)
				if _stops.is_empty():
					_go_to(Vector2i(floori(_start.x), floori(_start.y)))
					_mode = Mode.LEAVE
				else:
					_go_to(_stop_cell(_stops[0]))
					_mode = Mode.DRIVE
	_place()


## Moves along the path; true when the end is reached.
func _drive(delta: float) -> bool:
	if _path_i >= _path.size():
		return true
	var goal: Vector2 = _path[_path_i]
	var to_goal: Vector2 = goal - _pos
	var dist: float = to_goal.length()
	var step: float = _speed * delta
	if dist <= step:
		_pos = goal
		_path_i += 1
	else:
		_pos += to_goal / dist * step
		_heading = lerp_angle(_heading, atan2(to_goal.x, to_goal.y), minf(1.0, _look.num("truck", "turn_speed") * delta))
	for w: Node3D in _wheels:
		w.rotation.x += step / _look.num("truck", "wheel_radius")
	return false


func _place() -> void:
	if not _body.visible:
		return
	_body.position = Vector3(_pos.x, _terrain.ground_height_at(_pos.x, _pos.y), _pos.y)
	_body.rotation.y = _heading


## Plans the road path from the truck to [param target].
func _go_to(target: Vector2i) -> void:
	_path.clear()
	_path_i = 0
	for cell: Vector2i in _road_path(Vector2i(floori(_pos.x), floori(_pos.y)), target):
		_path.append(Vector2(cell) + Vector2(0.5, 0.5))
	if target == Vector2i(floori(_start.x), floori(_start.y)):
		_path.append(_start + Vector2(3.0, 0.0))


## The road cell where the truck stops for [param dest]: one block past the door, on the road.
func _stop_cell(dest: String) -> Vector2i:
	dest = dest.trim_prefix("@")
	var door: Vector2i = TownPlan.door_cell(_look, dest)
	var best: Vector2i = door
	var best_d: float = INF
	# Buildings can be placed anywhere (2026-11-22): look for the closest road block nearby.
	for dy in range(-14, 15):
		for dx in range(-14, 15):
			var c := Vector2i(door.x + dx, door.y + dy)
			if _road(c) and not TownPlan.lot_rect(_look, dest).has_point(c) and c != door:
				var d: float = Vector2(c).distance_to(Vector2(door))
				if d < best_d:
					best_d = d
					best = c
	return best


## Where the boxes for [param dest] are left (the door block).
func _drop_point(dest: String) -> Vector2:
	return TownPlan.lot_door(_look, dest)


func _road(c: Vector2i) -> bool:
	var t: int = _grid.tile_at(c.x, c.y)
	return t == WorldGrid.Tile.DIRT or t == WorldGrid.Tile.BRIDGE


## Breadth-first path over road blocks (dirt and bridges).
func _road_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var parents: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur == to:
			break
		for d: Vector2i in dirs:
			var n: Vector2i = cur + d
			if parents.has(n) or not _road(n):
				continue
			parents[n] = cur
			queue.append(n)
	if not parents.has(to):
		return out
	var back: Vector2i = to
	while back != from:
		out.push_front(back)
		back = parents[back]
	return out


func _update_arm(delta: float) -> void:
	var near: bool = _body.visible and absf(_pos.x - _gate_x) < _look.num("truck", "gate_lift_distance")
	_arm.rotation.x = lerpf(_arm.rotation.x, -1.35 if near else 0.0, minf(1.0, 4.0 * delta))


func _draw_boxes() -> void:
	for child: Node in _box_root.get_children():
		child.queue_free()
	var spots: Array[Vector2] = box_spots()
	for i in spots.size():
		var node := MeshInstance3D.new()
		node.mesh = _box_mesh
		node.material_override = _material
		node.position = Vector3(spots[i].x, _terrain.ground_height_at(spots[i].x, spots[i].y), spots[i].y)
		node.rotation.y = 0.3 * float(i)
		var label := Label3D.new()
		label.text = box_text(i)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = _look.integer("truck", "box_label_size")
		label.pixel_size = 0.01
		label.outline_size = 10
		label.position = Vector3(0.0, 1.0, 0.0)
		node.add_child(label)
		_box_root.add_child(node)


func _c(key: String) -> Color:
	return _look.color("truck", key)


## A pickup about 3.1 m long, facing +z: chassis, cab with windows, hood, grille, lights,
## bumpers, an open bed with low sides, four wheels and a few boxes in the bed.
func _build_truck() -> void:
	_body = Node3D.new()
	add_child(_body)
	var mb := MeshBuilder.new()
	var body: Color = _c("body")
	var dark: Color = _c("body_dark")
	var trim: Color = _c("trim")
	var glass: Color = _c("glass")
	var chrome: Color = _c("chrome")
	mb.add_box(Vector3(0.0, 0.42, 0.0), Vector3(1.3, 0.22, 3.0), trim)
	# Cab.
	mb.add_box(Vector3(0.0, 0.82, 0.78), Vector3(1.48, 0.58, 1.0), body)
	mb.add_box(Vector3(0.0, 1.36, 0.72), Vector3(1.38, 0.52, 0.86), body)
	mb.add_box(Vector3(0.0, 1.64, 0.72), Vector3(1.42, 0.06, 0.92), dark)
	mb.add_box(Vector3(0.0, 1.38, 1.155), Vector3(1.2, 0.42, 0.04), glass)
	mb.add_box(Vector3(0.0, 1.38, 0.29), Vector3(1.1, 0.36, 0.04), glass)
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(side * 0.695, 1.38, 0.78), Vector3(0.04, 0.38, 0.6), glass)
		mb.add_box(Vector3(side * 0.75, 0.86, 0.78), Vector3(0.02, 0.5, 0.9), dark)
		mb.add_box(Vector3(side * 0.79, 1.3, 1.12), Vector3(0.08, 0.12, 0.05), chrome)
		mb.add_box(Vector3(side * 0.755, 0.9, 0.62), Vector3(0.03, 0.04, 0.16), chrome)
	# Hood, grille, lights and bumper.
	mb.add_box(Vector3(0.0, 0.8, 1.6), Vector3(1.44, 0.5, 0.66), body)
	mb.add_box(Vector3(0.0, 1.06, 1.6), Vector3(1.3, 0.04, 0.6), dark)
	mb.add_box(Vector3(0.0, 0.78, 1.935), Vector3(0.9, 0.3, 0.04), trim)
	for k in 4:
		mb.add_box(Vector3(0.0, 0.68 + float(k) * 0.065, 1.96), Vector3(0.86, 0.02, 0.02), chrome)
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(side * 0.56, 0.82, 1.95), Vector3(0.2, 0.18, 0.04), _c("light"))
		mb.add_box(Vector3(side * 0.62, 0.62, -1.48), Vector3(0.14, 0.12, 0.04), _c("tail"))
		for z: float in [1.25, -0.95]:
			mb.add_box(Vector3(side * 0.7, 0.68, z), Vector3(0.14, 0.12, 0.8), dark)
	mb.add_box(Vector3(0.0, 0.52, 2.0), Vector3(1.52, 0.12, 0.12), chrome)
	mb.add_box(Vector3(0.0, 0.5, -1.52), Vector3(1.5, 0.1, 0.1), chrome)
	mb.add_box(Vector3(0.0, 0.5, 2.06), Vector3(0.4, 0.14, 0.02), Color.WHITE)
	# Open bed with low sides and a tailgate.
	mb.add_box(Vector3(0.0, 0.72, -0.62), Vector3(1.46, 0.08, 1.72), dark)
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(side * 0.7, 0.92, -0.62), Vector3(0.08, 0.36, 1.72), body)
		mb.add_box(Vector3(side * 0.705, 1.11, -0.62), Vector3(0.1, 0.04, 1.74), dark)
	mb.add_box(Vector3(0.0, 0.92, -1.46), Vector3(1.46, 0.36, 0.08), body)
	mb.add_box(Vector3(0.0, 0.9, -1.505), Vector3(0.3, 0.12, 0.02), Color.WHITE)
	var shell := MeshInstance3D.new()
	shell.mesh = mb.build()
	shell.material_override = _material
	_body.add_child(shell)
	# Wheels (spin around x while driving).
	var r: float = _look.num("truck", "wheel_radius")
	var wheel_mb := MeshBuilder.new()
	wheel_mb.add_cone(Vector3(0.0, -0.12, 0.0), r, r, 0.24, _c("tire"), _c("tire"), 10, true, true)
	wheel_mb.add_cone(Vector3(0.0, -0.13, 0.0), r * 0.5, r * 0.5, 0.26, chrome, chrome, 8, true, true)
	var wheel_mesh: ArrayMesh = wheel_mb.build()
	for side: float in [-1.0, 1.0]:
		for z: float in [1.25, -0.95]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.66, r, z)
			var w := MeshInstance3D.new()
			w.mesh = wheel_mesh
			w.material_override = _material
			w.rotation.z = PI * 0.5
			pivot.add_child(w)
			_body.add_child(pivot)
			_wheels.append(pivot)
	# Cargo boxes (one disappears at each stop).
	var cargo: ArrayMesh = _crate_mesh()
	for k in _look.integer("truck", "cargo_boxes"):
		var c := MeshInstance3D.new()
		c.mesh = cargo
		c.material_override = _material
		c.position = Vector3(-0.3 + float(k % 2) * 0.6, 0.76 + float(k / 2) * 0.55, -0.35 - float(k % 2) * 0.55)
		c.scale = Vector3.ONE * 0.9
		_body.add_child(c)
		_cargo.append(c)


## A cardboard box 0.6 m wide with tape and a red band (cargo and delivered boxes).
func _crate_mesh() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_box(Vector3(0.0, 0.3, 0.0), Vector3(0.6, 0.6, 0.6), _c("box"))
	mb.add_box(Vector3(0.0, 0.605, 0.0), Vector3(0.12, 0.012, 0.62), _c("box_dark"))
	mb.add_box(Vector3(0.0, 0.42, 0.0), Vector3(0.61, 0.1, 0.61), _c("box_stripe"))
	mb.add_box(Vector3(0.0, 0.2, 0.305), Vector3(0.2, 0.14, 0.01), Color.WHITE)
	return mb.build()


## The striped arm of the city barrier (lifted while the truck passes).
func _build_arm() -> void:
	var g: Array = _look.raw("town", "city_gate")
	_gate_x = float(g[0]) + 0.5
	_gate_z = float(g[1]) + 0.2
	_arm = Node3D.new()
	_arm.position = Vector3(_gate_x, 0.95, _gate_z)
	add_child(_arm)
	var length: float = float(g[3]) - 0.4
	var mb := MeshBuilder.new()
	var stripes: int = 6
	for k in stripes:
		var za: float = length * float(k) / float(stripes)
		var zb: float = length * float(k + 1) / float(stripes)
		mb.add_box(Vector3(0.0, 0.0, (za + zb) * 0.5), Vector3(0.12, 0.2, zb - za), _look.color("town", "flag_red") if k % 2 == 0 else _look.color("town", "flag_white"))
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = MeshBuilder.make_material(0.8)
	_arm.add_child(node)
