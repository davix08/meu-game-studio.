class_name TownPlan
extends RefCounted
## Lays the town around the lake on the [WorldGrid] (Story 009, plus the river and piers of
## Story 005): the river that comes down from the north-east into the lake, dirt roads with
## bridges where they cross water, the plaza, one lot per future building (cleared, blocked, with
## a path from its door to the road), forests and big boulders along the river, the L-shaped
## pier arm and a small extra pier. Everything is read from the "town" group of world_look.json.
##
## Static helpers answer where a lot is, where its door is and where the farm plots are, for the
## buildings, the farm view, the neighbors' routes and the interactions.
##
## Usage:
## [codeblock]
## var grid := WorldGrid.new()
## TownPlan.plan(grid, look)       # before LakeEstate.plan and the terrain
## var door: Vector2 = TownPlan.lot_door(look, "armazem")
## [/codeblock]

## Door side codes used in the lots data (5th number).
enum Side { SOUTH, NORTH, EAST, WEST }

const GROUP: String = "town"


## Paints the town on [param grid].
static func plan(grid: WorldGrid, look: WorldLook) -> void:
	_plan_river(grid, look)
	for r: Variant in _array(look, "roads"):
		var rect: Rect2i = _rect(r)
		grid.clear_area(rect)
		# Where the road crosses water, the bridge is one straight rectangle: the whole road width,
		# from one block before the first water block to one block after the last (2026-11-19).
		var along_x: bool = rect.size.x >= rect.size.y
		var lo: int = 1 << 30
		var hi: int = -1
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if grid.is_water(x, y):
					lo = mini(lo, x if along_x else y)
					hi = maxi(hi, x if along_x else y)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var k: int = x if along_x else y
				if hi >= 0 and k >= lo - 1 and k <= hi + 1:
					grid.set_tile(x, y, WorldGrid.Tile.BRIDGE)
				elif grid.tile_at(x, y) >= 0 and grid.tile_at(x, y) != WorldGrid.Tile.DOCK and grid.tile_at(x, y) != WorldGrid.Tile.BRIDGE:
					grid.set_tile(x, y, WorldGrid.Tile.DIRT)
	var plaza: Rect2i = _rect(_array(look, "plaza"))
	grid.clear_area(plaza)
	grid.paint_dirt(plaza)
	for id: String in lot_ids(look):
		var rect: Rect2i = lot_rect(look, id)
		grid.clear_area(rect.grow(1))
		grid.block_area(rect)
		_door_path(grid, look, id)
	_plan_forests(grid, look)
	if look.has(GROUP, "city_gate"):
		grid.block_area(_rect(_array(look, "city_gate")))
	for b: Variant in _array(look, "boulders"):
		var cell := Vector2i(int(b[0]), int(b[1]))
		if not grid.is_water(cell.x, cell.y):
			grid.add_prop(&"boulder", cell, Vector2(cell.x + 0.5, cell.y + 0.5), true)


## Opens the inside of the fields lot once it is built (only the fence ring stays solid, with a
## gate at the door), or closes it again. Called by the world when the lot state changes.
static func apply_lot_state(grid: WorldGrid, look: WorldLook, id: String, built: bool) -> void:
	if id != "campos":
		return
	var rect: Rect2i = lot_rect(look, id)
	grid.block_area(rect)
	if not built:
		return
	var gate: Vector2i = door_cell(look, id)
	for y in range(rect.position.y + 1, rect.end.y - 1):
		for x in range(rect.position.x + 1, rect.end.x - 1):
			grid.set_solid(x, y, false)
	var inside: Vector2i = gate - _side_step(lot_side(look, id))
	grid.set_solid(inside.x, inside.y, false)


## True when the map has a lot called [param id].
static func has_lot(look: WorldLook, id: String) -> bool:
	return (look.raw(GROUP, "lots") as Dictionary).has(id)


## Ids of the lots, in data order.
static func lot_ids(look: WorldLook) -> Array[String]:
	var out: Array[String] = []
	var lots: Dictionary = look.raw(GROUP, "lots")
	for id: Variant in lots:
		out.append(str(id))
	return out


## The cell rectangle of lot [param id].
static func lot_rect(look: WorldLook, id: String) -> Rect2i:
	var e: Array = (look.raw(GROUP, "lots") as Dictionary)[id]
	return Rect2i(int(e[0]), int(e[1]), int(e[2]), int(e[3]))


## The side of the lot where the door is.
static func lot_side(look: WorldLook, id: String) -> Side:
	var e: Array = (look.raw(GROUP, "lots") as Dictionary)[id]
	return int(e[4]) as Side


## The walkable cell right in front of the door of lot [param id].
static func door_cell(look: WorldLook, id: String) -> Vector2i:
	var r: Rect2i = lot_rect(look, id)
	match lot_side(look, id):
		Side.NORTH:
			return Vector2i(r.position.x + r.size.x / 2, r.position.y - 1)
		Side.EAST:
			return Vector2i(r.end.x, r.position.y + r.size.y / 2)
		Side.WEST:
			return Vector2i(r.position.x - 1, r.position.y + r.size.y / 2)
	return Vector2i(r.position.x + r.size.x / 2, r.end.y)


## Center of the door cell, in meters (x, z).
static func lot_door(look: WorldLook, id: String) -> Vector2:
	return Vector2(door_cell(look, id)) + Vector2(0.5, 0.5)


## The farm plots: (x start, z, x end) of each bed line. The first ones are the old garden beds
## (Story 004); the fields lot adds the rest. [param with_fields] includes the fields lot beds.
static func plot_lines(look: WorldLook, with_fields: bool) -> Array[Vector3]:
	var out: Array[Vector3] = EstateMeshes.garden_beds(look)
	if not with_fields:
		return out
	var r: Rect2i = lot_rect(look, "campos")
	var cols: int = look.integer(GROUP, "field_plot_cols")
	var rows: int = look.integer(GROUP, "field_plot_rows")
	var length: float = look.num(GROUP, "field_plot_length")
	var col_w: float = float(r.size.x - 2) / float(cols)
	var row_h: float = float(r.size.y - 2) / float(rows)
	for row in rows:
		for col in cols:
			var x0: float = float(r.position.x + 1) + float(col) * col_w + (col_w - length) * 0.5
			var z: float = float(r.position.y + 1) + (float(row) + 0.5) * row_h
			out.append(Vector3(x0, z, x0 + length))
	return out


## Where the player stands to work plot line [param line]: the west end for the old garden
## (the garden is fenced), the middle for the open fields.
static func plot_anchor(look: WorldLook, line: Vector3, garden: bool) -> Vector2:
	if garden:
		return Vector2(line.x - look.num(GROUP, "garden_plots_west_gap"), line.y)
	return Vector2((line.x + line.z) * 0.5, line.y)


static func _plan_river(grid: WorldGrid, look: WorldLook) -> void:
	var points: Array = _array(look, "river")
	var radius: float = look.num(GROUP, "river_radius")
	for y in WorldGrid.HEIGHT:
		for x in WorldGrid.WIDTH:
			var p := Vector2(x + 0.5, y + 0.5)
			var best: float = INF
			for i in points.size() - 1:
				var a := Vector2(float(points[i][0]), float(points[i][1]))
				var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
				best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
			if best < radius and not grid.is_water(x, y) and not WorldGrid.HOUSE.has_point(Vector2i(x, y)):
				grid.clear_area(Rect2i(x, y, 1, 1))
				grid.set_tile(x, y, WorldGrid.Tile.SHALLOW)
				grid.mark_river(x, y)
			elif best < radius + 1.0 and grid.tile_at(x, y) == WorldGrid.Tile.GRASS:
				grid.set_tile(x, y, WorldGrid.Tile.SAND)
			if best < radius:
				grid.mark_river(x, y)


static func _plan_forests(grid: WorldGrid, look: WorldLook) -> void:
	for f: Variant in _array(look, "forests"):
		var rect: Rect2i = _rect(f)
		var density: float = float(f[4])
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var t: int = grid.tile_at(x, y)
				if (t != WorldGrid.Tile.GRASS and t != WorldGrid.Tile.FLOWERS) or grid.has_solid_flag(x, y):
					continue
				if _near_kind(grid, x, y, WorldGrid.Tile.DIRT) or _near_kind(grid, x, y, WorldGrid.Tile.BRIDGE):
					continue
				if WorldGrid.hash2(x, y, 61) < 1.0 - density:
					continue
				var kind: StringName = &"pine" if WorldGrid.hash2(x, y, 62) > 0.45 else &"tree"
				grid.add_prop(kind, Vector2i(x, y), Vector2(x + 0.5, y + 0.875), true)


static func _door_path(grid: WorldGrid, look: WorldLook, id: String) -> void:
	var cell: Vector2i = door_cell(look, id)
	var step: Vector2i = _side_step(lot_side(look, id))
	for i in 12:
		if grid.tile_at(cell.x, cell.y) == WorldGrid.Tile.DIRT and i > 0:
			return
		if grid.tile_at(cell.x, cell.y) < 0 or grid.is_water(cell.x, cell.y):
			return
		grid.clear_area(Rect2i(cell.x, cell.y, 1, 1))
		grid.set_tile(cell.x, cell.y, WorldGrid.Tile.DIRT)
		cell += step


static func _side_step(side: Side) -> Vector2i:
	match side:
		Side.NORTH:
			return Vector2i(0, -1)
		Side.EAST:
			return Vector2i(1, 0)
		Side.WEST:
			return Vector2i(-1, 0)
	return Vector2i(0, 1)


static func _near_kind(grid: WorldGrid, x: int, y: int, kind: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if grid.tile_at(x + dx, y + dy) == kind:
				return true
	return false


static func _array(look: WorldLook, key: String) -> Array:
	return look.raw(GROUP, key)


static func _rect(v: Variant) -> Rect2i:
	var a: Array = v
	return Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))
