class_name NpcView
extends Node3D
## The neighbors walking around town (Story 013): chibi figures in each neighbor's colors that
## follow the [Routine] by the game clock. They walk the grid (breadth-first path over walkable
## blocks, so they keep to open ground and never cross buildings or water), play a short action
## when they arrive (eat, drink, shop, stroll), go inside to sleep at night and come out in the
## morning. Eating and drinking at the restaurant buy from it through [Town] (Story 014).
##
## Usage:
## [codeblock]
## var npcs := NpcView.new()
## add_child(npcs)
## npcs.setup(look, town_data, state, grid, terrain, town)
## var who: String = npcs.npc_at_screen(camera, touch_pos, 70.0)
## [/codeblock]

## One walking neighbor.
class Walker:
	extends RefCounted
	var id: String = ""
	var offset: float = 0.0
	var node: Node3D
	var pos: Vector2 = Vector2.ZERO
	var path: Array[Vector2i] = []
	var path_i: int = 0
	var step: int = -1
	var act_left: float = 0.0
	var acted: bool = false
	var phase: float = 0.0

var _look: WorldLook
var _town: TownData
var _state: GameState
var _grid: WorldGrid
var _terrain: LakeTerrain
var _rules: Town
var _routine: Routine
var _walkers: Array[Walker] = []
var _speed: float = 2.0
var _act_seconds: float = 4.0
var _bob: float = 0.04
var _step_freq: float = 9.0
var _parents: PackedInt32Array = PackedInt32Array()
var _queue: PackedInt32Array = PackedInt32Array()


## Creates one walker per neighbor, at its saved spot or at its door.
func setup(look: WorldLook, town: TownData, state: GameState, grid: WorldGrid, terrain: LakeTerrain, rules: Town) -> void:
	_look = look
	_town = town
	_state = state
	_grid = grid
	_terrain = terrain
	_rules = rules
	_routine = Routine.new(town)
	_speed = town.num("routine", "walk_speed")
	_act_seconds = town.num("routine", "act_seconds")
	_bob = look.num("npc", "bob")
	_step_freq = look.num("npc", "step_freq")
	_parents.resize(WorldGrid.WIDTH * WorldGrid.HEIGHT)
	_queue.resize(WorldGrid.WIDTH * WorldGrid.HEIGHT)
	for entry: Variant in town.neighbors():
		var n: Dictionary = entry
		var w := Walker.new()
		w.id = str(n["id"])
		w.offset = float(n["offset_minutes"])
		w.node = _model(n)
		add_child(w.node)
		w.pos = TownPlan.lot_door(look, str(n["lot"]))
		var saved: Dictionary = state.npcs.get(w.id, {})
		if saved.has("x") and saved.has("z"):
			w.pos = Vector2(float(saved["x"]), float(saved["z"]))
			w.step = int(saved.get("step", -1))
			w.acted = true
		_walkers.append(w)
		_place(w, 0.0)


## Writes every walker's position and routine step into the state (before saving).
func store() -> void:
	for w: Walker in _walkers:
		_state.npcs[w.id] = {"x": w.pos.x, "z": w.pos.y, "step": w.step}


## Id of the neighbor drawn within [param radius_px] of [param screen_pos], or "".
func npc_at_screen(camera: Camera3D, screen_pos: Vector2, radius_px: float) -> String:
	var best: String = ""
	var best_d: float = radius_px
	for w: Walker in _walkers:
		if not w.node.visible:
			continue
		var p: Vector2 = camera.unproject_position(w.node.position + Vector3.UP * 0.8)
		var d: float = p.distance_to(screen_pos)
		if d < best_d:
			best_d = d
			best = w.id
	return best


## Ground position (x, z) of neighbor [param id].
func position_of(id: String) -> Vector2:
	for w: Walker in _walkers:
		if w.id == id:
			return w.pos
	return Vector2.INF


func _process(delta: float) -> void:
	for w: Walker in _walkers:
		_update(w, delta)


func _update(w: Walker, delta: float) -> void:
	var step: int = _routine.step_at(_state.minutes, w.offset)
	if step != w.step:
		w.step = step
		w.acted = false
		w.act_left = 0.0
		w.path = _find_path(Vector2i(floori(w.pos.x), floori(w.pos.y)), _target_cell(w, _routine.place(step)))
		w.path_i = 0
		w.node.visible = true
	var moving: bool = w.path_i < w.path.size()
	if moving:
		var goal: Vector2 = Vector2(w.path[w.path_i]) + Vector2(0.5, 0.5)
		var to_goal: Vector2 = goal - w.pos
		var dist: float = to_goal.length()
		var move: float = _speed * delta
		if dist <= move:
			w.pos = goal
			w.path_i += 1
		else:
			w.pos += to_goal / dist * move
			w.node.rotation.y = lerp_angle(w.node.rotation.y, atan2(to_goal.x, to_goal.y), minf(1.0, 10.0 * delta))
		w.phase += delta
		_place(w, absf(sin(w.phase * _step_freq)) * _bob)
		return
	var act: String = _routine.act(w.step)
	if act == "dormir":
		w.node.visible = false
		return
	if not w.acted:
		if w.act_left <= 0.0:
			w.act_left = _act_seconds
		w.act_left -= delta
		w.phase += delta
		_place(w, absf(sin(w.phase * 4.0)) * _bob * 2.0)
		if w.act_left <= 0.0:
			w.acted = true
			if act == "comer":
				_rules.npc_meal()
			elif act == "beber":
				_rules.npc_drink()
	else:
		_place(w, 0.0)


func _target_cell(w: Walker, place: String) -> Vector2i:
	match place:
		"home":
			return TownPlan.door_cell(_look, str(_town.neighbor(w.id)["lot"]))
		"restaurante":
			if _state.is_built("restaurante"):
				return TownPlan.door_cell(_look, "restaurante") + Vector2i(0, 2 + _slot(w))
		"roupas":
			if _state.is_built("roupas"):
				return TownPlan.door_cell(_look, "roupas")
		"loja":
			var shop: Rect2i = EstateMeshes.cell_rect(_look, "shop")
			return Vector2i(shop.end.x, shop.position.y + 1 + _slot(w))
	return TownPlan.door_cell(_look, "prefeitura") + Vector2i(_slot(w) * 2, 1)


func _slot(w: Walker) -> int:
	for i in _walkers.size():
		if _walkers[i] == w:
			return i - 1
	return 0


## Breadth-first path over walkable blocks from [param from] to [param to] (both included except
## the start). Empty when there is no way or they are the same block.
func _find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if from == to or _grid.is_solid(to.x, to.y):
		return out
	var width: int = WorldGrid.WIDTH
	_parents.fill(-1)
	var start: int = from.y * width + from.x
	var goal: int = to.y * width + to.x
	if start < 0 or start >= _parents.size():
		return out
	_parents[start] = start
	_queue[0] = start
	var head: int = 0
	var tail: int = 1
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < tail:
		var cur: int = _queue[head]
		head += 1
		if cur == goal:
			break
		var cx: int = cur % width
		var cy: int = cur / width
		for d: Vector2i in dirs:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if nx < 0 or ny < 0 or nx >= width or ny >= WorldGrid.HEIGHT:
				continue
			var n: int = ny * width + nx
			if _parents[n] != -1 or _grid.is_solid(nx, ny):
				continue
			_parents[n] = cur
			_queue[tail] = n
			tail += 1
	if _parents[goal] == -1:
		return out
	var back: int = goal
	while back != start:
		out.push_front(Vector2i(back % width, back / width))
		back = _parents[back]
	return out


func _place(w: Walker, bob: float) -> void:
	w.node.position = Vector3(w.pos.x, _terrain.ground_height_at(w.pos.x, w.pos.y) + bob, w.pos.y)


## A small figure in the neighbor's colors: legs, body, arms, round head, hair and a hat.
func _model(n: Dictionary) -> Node3D:
	var skin: Color = Color.html(str(n["skin"]))
	var hair: Color = Color.html(str(n["hair"]))
	var hat: Color = Color.html(str(n["hat"]))
	var shirt: Color = Color.html(str(n["shirt"]))
	var pants: Color = Color.html(str(n["pants"]))
	var eye: Color = _look.color("colors", "eye")
	var mb := MeshBuilder.new()
	for side: float in [-1.0, 1.0]:
		mb.add_box(Vector3(side * 0.1, 0.2, 0.0), Vector3(0.15, 0.4, 0.17), pants)
		mb.add_box(Vector3(side * 0.1, 0.04, 0.04), Vector3(0.16, 0.08, 0.24), _look.color("colors", "boots"))
		mb.add_box(Vector3(side * 0.27, 0.62, 0.0), Vector3(0.11, 0.3, 0.12), shirt)
		mb.add_ellipsoid(Vector3(side * 0.27, 0.45, 0.0), Vector3(0.065, 0.065, 0.065), skin, skin, 6, 4, true)
		mb.add_ellipsoid(Vector3(side * 0.08, 1.03, 0.2), Vector3(0.03, 0.04, 0.02), eye, eye, 5, 3, true)
	mb.add_box(Vector3(0.0, 0.62, 0.0), Vector3(0.42, 0.42, 0.28), shirt)
	mb.add_ellipsoid(Vector3(0.0, 1.0, 0.0), Vector3(0.24, 0.22, 0.22), skin, skin, 10, 7, true)
	mb.add_ellipsoid(Vector3(0.0, 1.08, -0.09), Vector3(0.25, 0.19, 0.22), hair, hair, 8, 5, true)
	mb.add_cone(Vector3(0.0, 1.16, 0.0), 0.33, 0.3, 0.03, hat.darkened(0.15), hat, 14, true, true)
	mb.add_ellipsoid(Vector3(0.0, 1.19, 0.0), Vector3(0.2, 0.13, 0.2), hat.darkened(0.15), hat, 10, 5, true)
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = MeshBuilder.make_material(_look.num("player", "roughness"))
	node.scale = Vector3.ONE * _look.num("npc", "scale")
	return node
