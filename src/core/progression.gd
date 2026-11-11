class_name Progression
extends RefCounted
## Levels (2D levels.js): discovering species raises the level; each level opens a
## rarity and shop entries and pays a coin reward. Emits [signal GameState.level_up].
## Not thread-safe.
##
## Usage:
## [codeblock]
## var progression := Progression.new(data, state)
## state.level_up.connect(func(level: int, reward: int) -> void: print(level, reward))
## progression.check_level_up()
## [/codeblock]

var _data: GameData
var _state: GameState


## Builds the level system over [param data] and [param state].
func _init(data: GameData, state: GameState) -> void:
	_data = data
	_state = state


## Species that must be discovered to reach [param level] (config need2..need6).
func level_need(level: int) -> int:
	return int(_data.tune("need%d" % level))


## Raises the level as many times as the book allows, paying each level's reward.
func check_level_up() -> void:
	while _state.level < _data.max_level() and _state.discovered() >= level_need(_state.level + 1):
		_state.level += 1
		var reward: int = int(_data.tune("reward%d" % _state.level))
		_state.coins += reward
		_state.level_up.emit(_state.level, reward)
