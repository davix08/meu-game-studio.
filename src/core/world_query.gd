class_name WorldQuery
extends RefCounted
## The only questions fishing asks the world. The 3D world (story 002) extends this
## class and overrides the three methods; the base answers "no" everywhere, which
## keeps [FishingMachine] usable without any scene.
##
## Positions are world units (Vector3). Must be callable from the simulation thread.
##
## Usage:
## [codeblock]
## class LakeQuery extends WorldQuery:
##     func is_water(pos: Vector3) -> bool:
##         return pos.x > 10.0
## var fishing := FishingMachine.new(data, state, rng, LakeQuery.new(), roller, progression)
## [/codeblock]


## True when [param pos] is water the bobber can land on.
func is_water(_pos: Vector3) -> bool:
	return false


## True when [param pos] is deep water (better odds for rare fish).
func is_deep(_pos: Vector3) -> bool:
	return false


## True when [param pos] is within spot_radius of a bubbling fish school (shorter wait, better odds).
func in_school(_pos: Vector3) -> bool:
	return false
