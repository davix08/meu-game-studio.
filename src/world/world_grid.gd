class_name WorldGrid
extends RefCounted
## The logical 48x34 block grid of Lago Esmeralda: the single source of truth for collision
## and water. 1 block = 1 meter (1 Godot unit) in the 3D world; x is east, z (the grid's y)
## is south.
##
## A faithful port of buildOutdoor(), T, WALKABLE, solidAt, isWaterAt and hash2 from the 2D
## prototype (prototypes/lakebound/js/world.js and art.js), including the deterministic hash,
## so the map comes out identical to the 2D one. Implements Story 002 (design/game-brief.md,
## MVP feature 9). The interior of the house is not part of this grid.
##
## Usage:
## [codeblock]
## var grid := WorldGrid.new()
## if grid.is_solid(10, 3):
##     print("blocked")
## [/codeblock]

## Block kinds (same numbers as T in the 2D prototype; interior kinds are not ported).
enum Tile { GRASS, DIRT, SAND, SHALLOW, DEEP, DOCK, BRIDGE, FLOWERS }

## Grid width in blocks.
const WIDTH: int = 48
## Grid height in blocks.
const HEIGHT: int = 34
## 2D prototype pixels per block (TS). Fishing data (cast_range, spot_radius) and the
## [WorldQuery] positions are expressed in these pixels.
const PIXELS_PER_BLOCK: float = 16.0
## Tolerance used by [method box_free] (0.01 px of the 2D, in blocks).
const BOX_EPSILON: float = 0.0006

## Fishing house footprint in blocks (OUT.house).
const HOUSE: Rect2i = Rect2i(6, 2, 5, 4)
## Door block (OUT.door), on the south side of the house.
const DOOR: Vector2i = Vector2i(8, 5)
## West column of the 2-wide pier (OUT.pier.x).
const PIER_X: int = 21
## First pier row (OUT.pier.y0).
const PIER_Y0: int = 8
## Last pier row (OUT.pier.y1).
const PIER_Y1: int = 13
## Island block (OUT.island).
const ISLAND: Vector2i = Vector2i(34, 19)
## Islet block (OUT.islet).
const ISLET: Vector2i = Vector2i(17, 15)
## Spawn point in blocks (OUT.spawn is 9*16+8, 7*16+10 px).
const SPAWN: Vector2 = Vector2(9.5, 7.625)
## Lantern at the end of the pier, in blocks (x 22.75, z 13.875).
const LANTERN: Vector2 = Vector2(22.75, 13.875)
## Sign by the door, in blocks.
const SIGN: Vector2 = Vector2(10.25, 6.75)


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


## Props and decorations, in the order the 2D rules produce them.
var placements: Array[Placement] = []

var _tiles: PackedByteArray = PackedByteArray()
var _under: PackedByteArray = PackedByteArray()
var _solid: PackedByteArray = PackedByteArray()


func _init() -> void:
	_tiles.resize(WIDTH * HEIGHT)
	_tiles.fill(Tile.GRASS)
	_under.resize(WIDTH * HEIGHT)
	_under.fill(Tile.GRASS)
	_solid.resize(WIDTH * HEIGHT)
	_solid.fill(0)
	_build_outdoor()


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


func _set_tile(x: int, y: int, tile: int) -> void:
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return
	var i: int = y * WIDTH + x
	if (tile == Tile.DOCK or tile == Tile.BRIDGE) and _tiles[i] != Tile.DOCK and _tiles[i] != Tile.BRIDGE:
		_under[i] = _tiles[i]
	_tiles[i] = tile


func _lake_value(x: float, y: float) -> float:
	var d: float = pow((x - 25.0) / 15.0, 2.0) + pow((y - 19.5) / 10.0, 2.0)
	d += 0.09 * sin(x * 0.55) + 0.07 * cos(y * 0.8 + 1.0)
	var cove: float = pow((x - 37.0) / 7.0, 2.0) + pow((y - 25.0) / 5.0, 2.0) + 0.05 * sin(y)
	return minf(d, cove)


func _stamp_island(center: Vector2i, radius: float) -> void:
	for y in range(center.y - 4, center.y + 5):
		for x in range(center.x - 4, center.x + 5):
			var d: float = Vector2(x - center.x, y - center.y).length()
			if d < radius:
				_set_tile(x, y, Tile.GRASS if d < radius - 1.0 else Tile.SAND)
			elif d < radius + 1.2 and tile_at(x, y) == Tile.DEEP:
				_set_tile(x, y, Tile.SHALLOW)


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
	# Lake: elliptical with noise, plus the east cove.
	for y in HEIGHT:
		for x in WIDTH:
			var d: float = _lake_value(x + 0.5, y + 0.5)
			if d < 1.0:
				_set_tile(x, y, Tile.DEEP if d < 0.62 else Tile.SHALLOW)
	_stamp_island(ISLAND, 2.9)
	_stamp_island(ISLET, 1.7)

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

	# Dirt path: house door -> pier, and a branch to the island bridge.
	for y in range(DOOR.y + 1, 8):
		_paint_path(DOOR.x, y)
	for x in range(DOOR.x, PIER_X + 1):
		_paint_path(x, 7)
	for y in range(7, 31):
		_paint_path(43, y)
	for x in range(PIER_X, 44):
		_paint_path(x, 6)

	# Pier (2 wide) going south into the lake.
	for y in range(PIER_Y0, PIER_Y1 + 1):
		for x in range(PIER_X, PIER_X + 2):
			_set_tile(x, y, Tile.DOCK)

	# Bridge to the island, from the east shore.
	for x in range(ISLAND.x + 2, 46):
		var t: int = tile_at(x, ISLAND.y)
		if is_water_tile(t) or t == Tile.SAND:
			_set_tile(x, ISLAND.y, Tile.BRIDGE)
		else:
			break

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

	# Trees, pines, bushes and rocks (all solid).
	for y in HEIGHT:
		for x in WIDTH:
			var t: int = tile_at(x, y)
			if t != Tile.GRASS and t != Tile.FLOWERS:
				continue
			if _solid[y * WIDTH + x] == 1 or not _is_clear(x, y):
				continue
			var near_path: bool = false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var n: int = tile_at(x + dx, y + dy)
					if n == Tile.DIRT or n == Tile.BRIDGE or n == Tile.DOCK:
						near_path = true
			var border: bool = x < 2 or y < 1 or x > 45 or y > 31
			var h: float = hash2(x, y, 3)
			var cell := Vector2i(x, y)
			if (border and h > 0.12) or (not near_path and h > 0.9):
				var kind: StringName = &"pine" if hash2(x, y, 4) > 0.55 else &"tree"
				_add_solid_prop(kind, cell, 14.0)
			elif not near_path and h > 0.86:
				_add_solid_prop(&"bush", cell, 13.0)
			elif not near_path and h > 0.84:
				_add_solid_prop(&"rock", cell, 13.0)

	# A tree on each island and a rock beside the big one.
	_add_solid_prop(&"tree", Vector2i(ISLAND.x, ISLAND.y - 1), 14.0)
	_add_solid_prop(&"tree", ISLET, 14.0)
	_add_solid_prop(&"rock", Vector2i(ISLAND.x - 1, ISLAND.y + 1), 13.0)

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
