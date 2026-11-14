class_name PlayerState
extends Node
## Base class for player states (the "State" of the reference structure).
##
## The node name is the state's id, used by [method PlayerStateMachine.transition_to].

## The player this state controls. Set by the state machine.
var player: Player
## The owning state machine.
var machine: PlayerStateMachine


## Called when the state becomes active.
func enter(_previous: StringName) -> void:
	pass


## Called when the state is left.
func exit() -> void:
	pass


## Called every physics frame while active.
func physics_update(_delta: float) -> void:
	pass


## Whether the player may shoot in this state.
func can_shoot() -> bool:
	return true
