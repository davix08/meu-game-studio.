class_name GameClock
extends RefCounted
## The clock (2D time.js): game minutes advance by fixed steps, faster while
## resting; the luck bait runs down; at day_end the player sleeps automatically.
## Light and tint for the hour are rendering and live in the 3D world, not here.
## Not thread-safe.
##
## Usage:
## [codeblock]
## var clock := GameClock.new(data, state)
## clock.step(1.0 / 60.0)            # every fixed step
## var label: String = clock.clock_text(state.minutes) + " " + clock.period_name(state.minutes)
## [/codeblock]

var _data: GameData
var _state: GameState


## Builds the clock over [param data] and [param state].
func _init(data: GameData, state: GameState) -> void:
	_data = data
	_state = state


## One fixed step of [param dt] real seconds.
func step(dt: float) -> void:
	var mult: float = _data.tune("rest_time_mult") if _state.resting else 1.0
	var game_minutes: float = _data.tune("minutes_per_second") * dt * mult
	_state.minutes += game_minutes
	if _state.luck_left > 0.0:
		_state.luck_left = maxf(0.0, _state.luck_left - game_minutes)
	if _state.minutes >= _data.tune("day_end"):
		sleep_new_day(true)


## Ends the day: next morning at day_start, full energy, no resting.
## Emits [signal GameState.day_started]; fishing cancels itself on it, and the
## world moves the player to the spawn. [param auto]: the clock forced it.
func sleep_new_day(auto: bool) -> void:
	_state.day += 1
	_state.minutes = _data.tune("day_start")
	_state.energy = _data.fixed("energy_max")
	_state.resting = false
	_state.day_started.emit(_state.day, auto)


## Name of the period ("Madrugada", "Manhã", "Tarde", "Noite") at [param minutes].
func period_name(minutes: float) -> String:
	var hour: float = fmod(minutes / 60.0, 24.0)
	var found: String = _data.period_names[0]
	for i: int in _data.period_hours.size():
		if hour >= _data.period_hours[i]:
			found = _data.period_names[i]
	return found


## "HH:MM" for [param minutes], wrapping past midnight.
func clock_text(minutes: float) -> String:
	var hours: int = int(floor(minutes / 60.0)) % 24
	var mins: int = int(floor(fmod(minutes, 60.0)))
	return "%02d:%02d" % [hours, mins]
