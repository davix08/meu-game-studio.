class_name PlayerStateMachine
extends Node
## Runs one [PlayerState] child at a time (the "PlayerStateManager").

## Emitted after every transition.
signal state_changed(from: StringName, to: StringName)

## Name of the child state to start in.
@export var initial_state: StringName = &"Ground"

var current: PlayerState
var _states: Dictionary = {}


## Wires every child state to [param player] and enters the initial state.
func setup(player: Player) -> void:
	for child: Node in get_children():
		var state := child as PlayerState
		if state == null:
			continue
		state.player = player
		state.machine = self
		_states[StringName(child.name)] = state
	current = _states[initial_state]
	current.enter(&"")


## Switches to the state named [param state_name].
func transition_to(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("Unknown player state: %s" % state_name)
		return
	var from: StringName = StringName(current.name)
	if from == state_name:
		return
	current.exit()
	current = _states[state_name]
	current.enter(from)
	state_changed.emit(from, state_name)


## Name of the active state.
func current_name() -> StringName:
	return StringName(current.name) if current != null else &""


func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)
