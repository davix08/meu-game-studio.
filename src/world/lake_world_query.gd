class_name LakeWorldQuery
extends WorldQuery
## Answers the fishing questions ([WorldQuery]) from the logical [WorldGrid].
##
## SCALE CHOICE (Story 002): Story 001 defined WorldQuery positions and the ranges
## (cast_range, spot_radius) in 2D PIXEL units (1 block = 16 px). The 3D world is
## 1 block = 1 meter. This class therefore takes positions in 2D pixel units: x and z are
## divided by [constant WorldGrid.PIXELS_PER_BLOCK] to find the block; y is ignored. The 3D
## scene must convert with [method to_query_pos] before talking to the FishingMachine.
##
## Fish schools (Story 003) are answered by the injected [WaterLife].
##
## Usage:
## [codeblock]
## var query := LakeWorldQuery.new(grid)
## var cast_target: Vector3 = LakeWorldQuery.to_query_pos(bobber_world_pos)
## [/codeblock]

var _grid: WorldGrid
var _life: WaterLife


func _init(grid: WorldGrid) -> void:
	_grid = grid


## Converts a 3D world position (meters) to query space (2D pixel units). Pass y = 0 for ground
## points so distances against the player's query position stay on the ground plane.
static func to_query_pos(world_pos: Vector3) -> Vector3:
	return world_pos * WorldGrid.PIXELS_PER_BLOCK


## True when [param pos] (2D pixel units) is over shallow or deep water.
func is_water(pos: Vector3) -> bool:
	return _grid.is_water(_block_x(pos), _block_z(pos))


## True when [param pos] (2D pixel units) is over deep water.
func is_deep(pos: Vector3) -> bool:
	return _grid.is_deep(_block_x(pos), _block_z(pos))


## Gives the query the swimming fish and schools that answer [method in_school].
func set_water_life(life: WaterLife) -> void:
	_life = life


## True when [param pos] (2D pixel units) is inside a bubbling fish school.
func in_school(pos: Vector3) -> bool:
	return _life != null and _life.in_school(pos)


func _block_x(pos: Vector3) -> int:
	return floori(pos.x / WorldGrid.PIXELS_PER_BLOCK)


func _block_z(pos: Vector3) -> int:
	return floori(pos.z / WorldGrid.PIXELS_PER_BLOCK)
