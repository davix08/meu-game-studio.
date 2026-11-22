class_name WorldGrid
extends RefCounted
## The logical block grid of the farm by the lake: the single source of truth for collision
## and water. 1 block = 1 meter (1 Godot unit) in the 3D world; x is east, z (the grid's y)
## is south.
##
## A faithful port of buildOutdoor(), T, WALKABLE, solidAt, isWaterAt and hash2 from the 2D
## prototype (prototypes/lakebound/js/world.js and art.js), including the deterministic hash,
## so the map comes out identical to the 2D one. Implements Story 002 (design/game-brief.md,
## MVP feature 9). The interior of the house is not part of this grid.
##
## Story 009: the map grew from 48x34 to 96x68. The original lake map is laid out unchanged with
## its top-left corner at [constant ORIGIN]; the town around it (roads, river, lots, forests) is
## painted afterwards by [TownPlan] through [method set_tile], [method set_solid] and
## [method add_prop].
##
## Usage:
## [codeblock]
## var grid := WorldGrid.new()
## if grid.is_solid(10, 3):
##     print("blocked")
## [/codeblock]

## Block kinds (same numbers as T in the 2D prototype; interior kinds are not ported).
enum Tile { GRASS, DIRT, SAND, SHALLOW, DEEP, DOCK, BRIDGE, FLOWERS }

## 2D prototype pixels per block (TS). Fishing data (cast_range, spot_radius) and the
## [WorldQuery] positions are expressed in these pixels.
const PIXELS_PER_BLOCK: float = 16.0
## Tolerance used by [method box_free] (0.01 px of the 2D, in blocks).
const BOX_EPSILON: float = 0.0006
## Where the old 48x34 lake map sat inside the village map of Story 009 (old saves only).
const ORIGIN: Vector2i = Vector2i(24, 17)

# The farm layout (2026-11-19 map): set from the "farm" group of world_look.json when a grid is
# built with a look; the defaults are the same values.
## Grid width in blocks.
static var WIDTH: int = 60
## Grid height in blocks.
static var HEIGHT: int = 42
## Farmer's house footprint in blocks.
static var HOUSE: Rect2i = Rect2i(16, 4, 5, 4)
## Door block, on the south side of the house.
static var DOOR: Vector2i = Vector2i(18, 7)
## West column of the 2-wide pier.
static var PIER_X: int = 29
## First pier row.
static var PIER_Y0: int = 14
## Last pier row.
static var PIER_Y1: int = 18
## Spawn point in blocks (in front of the house).
static var SPAWN: Vector2 = Vector2(19.5, 9.6)
## Lantern at the end of the pier, in blocks.
static var LANTERN: Vector2 = Vector2(30.75, 18.875)
## Sign by the door, in blocks.
static var SIGN: Vector2 = Vector2(20.25, 8.75)
## The lake area (used to place the scattered trees and rocks around it).
static var LAKE_RECT: Rect2i = Rect2i(17, 14, 27, 14)


## A decoration or solid prop placed by the map rules.
class Placement:
	extends RefCounted
	## "tree", "pine", "bush", "rock", "tuft", "reed" or "lily".
	var kind: StringName = &""
	## Block the prop belongs to.
	var cell: Vector2i = Vector2i.ZERO
	## Position in blocks (x, z).
	var pos: Vector2 = Vector2.ZERO
	## For "lily": true when it has a flower.
	var flag: bool = false
	## Trees and rocks the player can cut or break (inside the farm, not the border forest).
	var choppable: bool = false
	## Expansion area the placement belongs to ("" outside them): its trees go when it opens.
	var zone: String = ""


## Props and decorations, in the order the 2D rules produce them.
var placements: Array[Placement] = []

var _tiles: PackedByteArray = PackedByteArray()
var _under: PackedByteArray = PackedByteArray()
var _solid: PackedByteArray = PackedByteArray()
var _river: PackedByteArray = PackedByteArray()


## Builds the grid. With [param look], the farm layout comes from its "farm" group.
func _init(look: WorldLook = null) -> void:
	if look != null:
		configure(look)
	_river.resize(WIDTH * HEIGHT)
	_river.fill(0)
	_tiles.resize(WIDTH * HEIGHT)
	_tiles.fill(Tile.GRASS)
	_under.resize(WIDTH * HEIGHT)
	_under.fill(Tile.GRASS)
	_solid.resize(WIDTH * HEIGHT)
	_solid.fill(0)
	_build_outdoor()


## Reads the farm layout (size, house, pier, spawn) from [param look] into the static values.
static func configure(look: WorldLook) -> void:
	WIDTH = look.integer("farm", "width")
	HEIGHT = look.integer("farm", "height")
	var h: Array = look.raw("farm", "house")
	HOUSE = Rect2i(int(h[0]), int(h[1]), int(h[2]), int(h[3]))
	var d: Array = look.raw("farm", "door")
	DOOR = Vector2i(int(d[0]), int(d[1]))
	PIER_X = look.integer("farm", "pier_x")
	PIER_Y0 = look.integer("farm", "pier_y0")
	PIER_Y1 = look.integer("farm", "pier_y1")
	var sp: Array = look.raw("farm", "spawn")
	SPAWN = Vector2(float(sp[0]), float(sp[1]))
	LANTERN = Vector2(float(PIER_X) + 1.75, float(PIER_Y1) + 0.875)
	SIGN = Vector2(float(DOOR.x) + 2.25, float(DOOR.y) + 1.75)
	var c: Array = look.raw("farm", "lake_center")
	var r: Array = look.raw("farm", "lake_radius")
	LAKE_RECT = Rect2i(int(float(c[0]) - float(r[0])), int(float(c[1]) - float(r[1])), int(float(r[0]) * 2.0), int(float(r[1]) * 2.0))
	_lake_c = Vector2(float(c[0]), float(c[1]))
	_lake_r = Vector2(float(r[0]), float(r[1]))
	_lake_deep = look.num("farm", "lake_deep")
	_lake_noise = look.num("farm", "lake_noise")
	_border = look.integer("farm", "border")
	_tree_chance = look.num("farm", "tree_chance")
	_rock_chance = look.num("farm", "rock_chance")


static var _lake_c: Vector2 = Vector2(30.0, 21.0)
static var _lake_r: Vector2 = Vector2(13.0, 6.5)
static var _lake_deep: float = 0.55
static var _lake_noise: float = 0.08
static var _border: int = 3
static var _tree_chance: float = 0.05
static var _rock_chance: float = 0.025


## Deterministic hash of integer coordinates to [0, 1) (hash2 of the 2D prototype). Used for
## map decoration only, never for gameplay randomness.
static func hash2(x: int, y: int, salt: int = 0) -> float:
	var mask: int = 0xFFFFFFFF
	var h: int = (x * 374761393 + y * 668265263 + salt * 982451653) & mask
	h = ((h ^ (h >> 13)) * 1274126177) & mask
	h = h ^ (h >> 16)
	return float(h) / 4294967296.0


## True for shallow and deep water kinds.
static func is_water_tile(tile: int) -> bool:
	return tile == Tile.SHALLOW or tile == Tile.DEEP


## The tile kind at a block, or -1 outside the map.
func tile_at(cx: int, cy: int) -> int:
	if cx < 0 or cy < 0 or cx >= WIDTH or cy >= HEIGHT:
		return -1
	return _tiles[cy * WIDTH + cx]


## The ground kind below a dock or bridge block (what was there before the planks); for
## every other block, the same as [method tile_at].
func tile_under(cx: int, cy: int) -> int:
	var tile: int = tile_at(cx, cy)
	if tile == Tile.DOCK or tile == Tile.BRIDGE:
		return _under[cy * WIDTH + cx]
	return tile


## True when the block cannot be walked on: outside the map, water, or a solid prop.
func is_solid(cx: int, cy: int) -> bool:
	var tile: int = tile_at(cx, cy)
	return tile < 0 or is_water_tile(tile) or _solid[cy * WIDTH + cx] == 1


## True when the block is shallow or deep water (docks and bridges are not water).
func is_water(cx: int, cy: int) -> bool:
	return is_water_tile(tile_at(cx, cy))


## True when the block is deep water.
func is_deep(cx: int, cy: int) -> bool:
	return tile_at(cx, cy) == Tile.DEEP


## True when a box centered on ([param x], [param z]) with the given half extents (all in
## blocks) touches no solid block. This is the 2D boxFree with the feet box centered.
func box_free(x: float, z: float, half_width: float, half_depth: float) -> bool:
	var cx0: int = floori(x - half_width)
	var cx1: int = floori(x + half_width - BOX_EPSILON)
	var cy0: int = floori(z - half_depth)
	var cy1: int = floori(z + half_depth - BOX_EPSILON)
	for cy in range(cy0, cy1 + 1):
		for cx in range(cx0, cx1 + 1):
			if is_solid(cx, cy):
				return false
	return true


## Like [method box_free], but water blocks count as free (swimming, 2026-11-22). Solid props,
## buildings and the map edge still block.
func box_free_swim(x: float, z: float, half_width: float, half_depth: float) -> bool:
	var cx0: int = floori(x - half_width)
	var cx1: int = floori(x + half_width - BOX_EPSILON)
	var cy0: int = floori(z - half_depth)
	var cy1: int = floori(z + half_depth - BOX_EPSILON)
	for cy in range(cy0, cy1 + 1):
		for cx in range(cx0, cx1 + 1):
			if tile_at(cx, cy) < 0 or _solid[cy * WIDTH + cx] == 1:
				return false
	return true


## Removes every placement (trees, bushes, rocks, tufts...) and solid flag inside [param rect]
## and turns flower blocks into plain grass, so a building can stand there (Story 004). The
## house footprint and the sign by the door are never touched.
func clear_area(rect: Rect2i) -> void:
	for i in range(placements.size() - 1, -1, -1):
		if rect.has_point(placements[i].cell):
			placements.remove_at(i)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT or HOUSE.has_point(Vector2i(x, y)):
				continue
			if x == DOOR.x + 2 and y == DOOR.y + 1:
				continue
			_solid[y * WIDTH + x] = 0
			if _tiles[y * WIDTH + x] == Tile.FLOWERS:
				_tiles[y * WIDTH + x] = Tile.GRASS


## Marks every block of [param rect] as solid (a building or fence footprint). Water stays
## water, so [method is_water] and [method is_deep] are unchanged.
func block_area(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT:
				_solid[y * WIDTH + x] = 1


## Sets the tile kind of a block (docks and bridges remember the ground below). For [TownPlan].
func set_tile(x: int, y: int, tile: int) -> void:
	_set_tile(x, y, tile)


## Marks a block solid or free. For [TownPlan].
func set_solid(x: int, y: int, solid: bool) -> void:
	if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT:
		_solid[y * WIDTH + x] = 1 if solid else 0


## Adds a prop placement; [param solid] also blocks its block. For [TownPlan].
func add_prop(kind: StringName, cell: Vector2i, pos: Vector2, solid: bool) -> void:
	if solid:
		set_solid(cell.x, cell.y, true)
	_add_placement(kind, cell, pos)


## Marks a block as river (the water shader adds the current there).
func mark_river(x: int, y: int) -> void:
	if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT:
		_river[y * WIDTH + x] = 1


## True when the block is river water.
func is_river(cx: int, cy: int) -> bool:
	if cx < 0 or cy < 0 or cx >= WIDTH or cy >= HEIGHT:
		return false
	return _river[cy * WIDTH + cx] == 1


## True when a block has a solid prop or building (not counting water).
func has_solid_flag(cx: int, cy: int) -> bool:
	if cx < 0 or cy < 0 or cx >= WIDTH or cy >= HEIGHT:
		return true
	return _solid[cy * WIDTH + cx] == 1


## Paints the non-water blocks of [param rect] as dirt path.
func paint_dirt(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_paint_path(x, y)


func _set_tile(x: int, y: int, tile: int) -> void:
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return
	var i: int = y * WIDTH + x
	if (tile == Tile.DOCK or tile == Tile.BRIDGE) and _tiles[i] != Tile.DOCK and _tiles[i] != Tile.BRIDGE:
		_under[i] = _tiles[i]
	_tiles[i] = tile


func _lake_value(x: float, y: float) -> float:
	var d: float = pow((x - _lake_c.x) / _lake_r.x, 2.0) + pow((y - _lake_c.y) / _lake_r.y, 2.0)
	return d + _lake_noise * sin(x * 0.55) + _lake_noise * 0.8 * cos(y * 0.8 + 1.0)


func _paint_path(x: int, y: int) -> void:
	if not is_water(x, y):
		_set_tile(x, y, Tile.DIRT)


func _is_clear(x: int, y: int) -> bool:
	if absi(x - DOOR.x) <= 3 and y >= HOUSE.position.y - 1 and y <= DOOR.y + 3:
		return false
	if absi(x - int(SPAWN.x)) <= 1 and absi(y - int(SPAWN.y)) <= 1:
		return false
	return true


func _add_placement(kind: StringName, cell: Vector2i, pos: Vector2, flag: bool = false) -> void:
	var placement := Placement.new()
	placement.kind = kind
	placement.cell = cell
	placement.pos = pos
	placement.flag = flag
	placements.append(placement)


## Adds a solid prop standing at the given pixel offsets inside block [param cell].
func _add_solid_prop(kind: StringName, cell: Vector2i, offset_y_px: float) -> void:
	_solid[cell.y * WIDTH + cell.x] = 1
	_add_placement(kind, cell, Vector2(cell.x + 0.5, cell.y + offset_y_px / PIXELS_PER_BLOCK))


func _build_outdoor() -> void:
	# Lake: an oval with a little noise in the middle of the farm.
	for y in HEIGHT:
		for x in WIDTH:
			var d: float = _lake_value(x + 0.5, y + 0.5)
			if d < 1.0:
				_set_tile(x, y, Tile.DEEP if d < _lake_deep else Tile.SHALLOW)

	# Sand beaches next to water.
	for y in HEIGHT:
		for x in WIDTH:
			if tile_at(x, y) != Tile.GRASS:
				continue
			var near_water: bool = false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if is_water(x + dx, y + dy):
						near_water = true
			if near_water and hash2(x, y, 1) > 0.35:
				_set_tile(x, y, Tile.SAND)

	# Shallow ring along every shore.
	for y in HEIGHT:
		for x in WIDTH:
			if tile_at(x, y) != Tile.DEEP:
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var t: int = tile_at(x + dx, y + dy)
					if t >= 0 and not is_water_tile(t):
						_set_tile(x, y, Tile.SHALLOW)

	# Pier (2 wide) going south from the north shore into the lake.
	for y in range(PIER_Y0, PIER_Y1 + 1):
		for x in range(PIER_X, PIER_X + 2):
			_set_tile(x, y, Tile.DOCK)

	# Flowers.
	for y in HEIGHT:
		for x in WIDTH:
			if tile_at(x, y) == Tile.GRASS and hash2(x, y, 2) > 0.9:
				_set_tile(x, y, Tile.FLOWERS)

	# House (solid) and the sign by the door (solid).
	for y in range(HOUSE.position.y, HOUSE.end.y):
		for x in range(HOUSE.position.x, HOUSE.end.x):
			_set_tile(x, y, Tile.GRASS)
			_solid[y * WIDTH + x] = 1
	_solid[(DOOR.y + 1) * WIDTH + DOOR.x + 2] = 1

	# Border forest (solid, cannot be cut) and scattered trees and rocks inside the farm, which
	# the player can cut or break for wood and stone.
	for y in HEIGHT:
		for x in WIDTH:
			var t: int = tile_at(x, y)
			if t != Tile.GRASS and t != Tile.FLOWERS:
				continue
			if _solid[y * WIDTH + x] == 1 or not _is_clear(x, y):
				continue
			var cell := Vector2i(x, y)
			var h: float = hash2(x, y, 3)
			var border: bool = x < _border or y < _border or x >= WIDTH - _border or y >= HEIGHT - _border
			if border:
				if h > 0.12:
					var kind: StringName = &"pine" if hash2(x, y, 4) > 0.55 else &"tree"
					_add_solid_prop(kind, cell, 14.0)
				continue
			if h > 1.0 - _tree_chance:
				var tree: StringName = &"pine" if hash2(x, y, 4) > 0.55 else &"tree"
				_add_solid_prop(tree, cell, 14.0)
				placements[placements.size() - 1].choppable = true
			elif h > 1.0 - _tree_chance - _rock_chance:
				_add_solid_prop(&"rock", cell, 13.0)
				placements[placements.size() - 1].choppable = true

	# Decoration: grass tufts, reeds and lily pads.
	for y in HEIGHT:
		for x in WIDTH:
			var t: int = tile_at(x, y)
			var h: float = hash2(x, y, 5)
			var cell := Vector2i(x, y)
			if t == Tile.GRASS and _solid[y * WIDTH + x] == 0 and h > 0.55:
				var px: float = 3.0 + fmod(h * 97.0, 10.0)
				var py: float = 6.0 + fmod(h * 31.0, 8.0)
				_add_placement(&"tuft", cell, Vector2(x + px / PIXELS_PER_BLOCK, y + py / PIXELS_PER_BLOCK))
			if t == Tile.SHALLOW:
				var near_land: bool = false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var n: int = tile_at(x + dx, y + dy)
						if n >= 0 and not is_water_tile(n) and n != Tile.DOCK and n != Tile.BRIDGE:
							near_land = true
				if near_land and h > 0.72:
					var rx: float = 4.0 + fmod(h * 53.0, 8.0)
					_add_placement(&"reed", cell, Vector2(x + rx / PIXELS_PER_BLOCK, y + 12.0 / PIXELS_PER_BLOCK))
				elif h > 0.9:
					var lx: float = 4.0 + fmod(h * 71.0, 8.0)
					var ly: float = 4.0 + fmod(h * 13.0, 8.0)
					_add_placement(&"lily", cell, Vector2(x + lx / PIXELS_PER_BLOCK, y + ly / PIXELS_PER_BLOCK), h > 0.96)
