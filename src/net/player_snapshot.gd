class_name PlayerSnapshot
extends RefCounted
## What one player sends the others ~10 times a second (design/gdd/coop-lan.md): where
## they stand, where they face, their fishing pose and their rod. Packed as a small Array
## so it crosses the network compactly and can be checked field by field on arrival.
##
## Usage:
## [codeblock]
## var snap := PlayerSnapshot.new()
## snap.pos = fisherman.ground_pos
## var wire: Array = snap.to_wire()
## var back: PlayerSnapshot = PlayerSnapshot.from_wire(wire)  # null when malformed
## [/codeblock]

## Fields in the wire array, in order.
const FIELDS: int = 6

## Ground position in blocks (x east, y south).
var pos: Vector2 = Vector2.ZERO
## Facing, radians around Y.
var yaw: float = 0.0
## Fisherman.Pose value.
var pose: int = 0
## Rod throw progress 0..1 (for the CAST pose).
var cast_progress: float = 0.0
## The player holds a rod.
var has_rod: bool = false
## Rod color, "#rrggbb" ("" with no rod).
var rod_color: String = ""


## The array sent over the network.
func to_wire() -> Array:
	return [pos.x, pos.y, yaw, pose, cast_progress, rod_color if has_rod else ""]


## Rebuilds a snapshot from [param wire], or null when it is not a valid snapshot
## (wrong size or types): a bad packet is dropped, never trusted.
static func from_wire(wire: Variant) -> PlayerSnapshot:
	if not (wire is Array) or (wire as Array).size() != FIELDS:
		return null
	var a: Array = wire
	for i: int in 5:
		if not (a[i] is float or a[i] is int):
			return null
	if not (a[5] is String):
		return null
	var s := PlayerSnapshot.new()
	s.pos = Vector2(float(a[0]), float(a[1]))
	s.yaw = float(a[2])
	s.pose = clampi(int(a[3]), 0, Fisherman.Pose.size() - 1)
	s.cast_progress = clampf(float(a[4]), 0.0, 1.0)
	s.rod_color = str(a[5])
	s.has_rod = s.rod_color != ""
	if s.has_rod and not Color.html_is_valid(s.rod_color):
		return null
	return s
