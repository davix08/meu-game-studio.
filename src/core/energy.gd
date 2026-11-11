class_name Energy
extends RefCounted
## Resting restores energy (2D energy.js). Casting spends it in [FishingMachine],
## snacks in [Economy]; running drain belongs to the 3D movement (story 002).
## Not thread-safe.
##
## Usage:
## [codeblock]
## var energy := Energy.new(data, state, fishing)
## energy.toggle_rest()
## energy.step(1.0 / 60.0)  # every fixed step
## [/codeblock]

## Resting ended by itself because energy reached the maximum.
signal rest_finished

## Outcome of [method toggle_rest].
enum Result {
	STARTED, ## Now resting.
	STOPPED, ## Was resting, now not.
	BUSY_FISHING, ## A cast is in progress.
	ENERGY_FULL, ## Nothing to restore.
}

var _data: GameData
var _state: GameState
var _fishing: FishingMachine


## Builds the energy system; [param fishing] is asked whether a cast is in progress.
func _init(data: GameData, state: GameState, fishing: FishingMachine) -> void:
	_data = data
	_state = state
	_fishing = fishing


## One fixed step of [param dt] seconds: regenerates while resting.
func step(dt: float) -> void:
	if not _state.resting:
		return
	var energy_max: float = _data.fixed("energy_max")
	_state.energy = minf(energy_max, _state.energy + _data.tune("rest_regen") * dt)
	if _state.energy >= energy_max:
		_state.resting = false
		rest_finished.emit()


## Starts or stops resting.
func toggle_rest() -> Result:
	if _state.resting:
		_state.resting = false
		return Result.STOPPED
	if not _fishing.is_idle():
		return Result.BUSY_FISHING
	if _state.energy >= _data.fixed("energy_max"):
		return Result.ENERGY_FULL
	_state.resting = true
	return Result.STARTED
