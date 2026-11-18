class_name FollowCamera
extends Camera3D
## Orthographic isometric camera looking down at the world at a fixed pitch (35.264 degrees =
## true isometric) and yaw (45 degrees), that follows a target with exponential smoothing and
## keeps its focus point inside the map bounds. Because the view is orthographic, [member
## Camera3D.size] (visible height in meters) sets the zoom and distance only has to be large
## enough that the whole scene fits between near and far. Size, distance, pitch, yaw, near,
## far, smoothing and bounds margins come from world_look.json (group "camera"). The yaw is
## also what LakeMain uses to rotate the movement input, so "up on screen" stays "up on screen".
##
## Story 002 (design/game-brief.md, MVP feature 9). Process this node AFTER the target moves
## (add it to the tree after the node that moves the target).
##
## Usage:
## [codeblock]
## var camera := FollowCamera.new()
## add_child(camera)
## camera.setup(look, fisherman)
## [/codeblock]

var _target: Node3D
var _offset: Vector3 = Vector3.ZERO
var _smoothing: float = 1.0
var _focus: Vector3 = Vector3.ZERO
var _min_focus: Vector2 = Vector2.ZERO
var _max_focus: Vector2 = Vector2.ZERO


## Configures the camera from [param look] and snaps it to [param target].
func setup(look: WorldLook, target: Node3D) -> void:
	_target = target
	_smoothing = look.num("camera", "follow_smoothing")
	rotation = Vector3(-deg_to_rad(look.num("camera", "pitch_degrees")), deg_to_rad(look.num("camera", "yaw_degrees")), 0.0)
	_offset = basis * Vector3(0.0, 0.0, look.num("camera", "distance"))
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = look.num("camera", "size")
	near = look.num("camera", "near")
	far = look.num("camera", "far")
	_min_focus = Vector2(look.num("camera", "margin_west"), look.num("camera", "margin_north"))
	_max_focus = Vector2(float(WorldGrid.WIDTH) - look.num("camera", "margin_east"), float(WorldGrid.HEIGHT) - look.num("camera", "margin_south"))
	_focus = _clamped_target()
	position = _focus + _offset
	current = true


func _process(delta: float) -> void:
	_focus = _focus.lerp(_clamped_target(), 1.0 - exp(-_smoothing * delta))
	position = _focus + _offset


func _clamped_target() -> Vector3:
	var pos: Vector3 = _target.position
	return Vector3(clampf(pos.x, _min_focus.x, _max_focus.x), pos.y, clampf(pos.z, _min_focus.y, _max_focus.y))
