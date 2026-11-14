class_name Aim
extends RefCounted
## Turns raw directional input into one of eight shooting directions.

## Input magnitude under which a stick axis counts as neutral.
const DEADZONE := 0.35


## Returns a normalized aim direction.
## [param input]: movement input (-1..1 per axis, y down is positive).
## [param facing]: -1 or 1. [param grounded]: on floor. [param locked]: aim-lock held.
static func direction(input: Vector2, facing: int, grounded: bool, locked: bool) -> Vector2:
	var x: int = _axis(input.x)
	var y: int = _axis(input.y)
	if grounded and y > 0 and not locked:
		# Down on the ground without aim-lock means duck: shoot forward, low.
		return Vector2(facing, 0)
	if x == 0 and y == 0:
		return Vector2(facing, 0)
	if grounded and y > 0 and x == 0:
		# Never shoot straight into the floor.
		x = facing
	return Vector2(x, y).normalized()


static func _axis(v: float) -> int:
	if v > DEADZONE:
		return 1
	if v < -DEADZONE:
		return -1
	return 0
