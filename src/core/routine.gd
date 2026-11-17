class_name Routine
extends RefCounted
## The neighbors' day (Story 013): a list of (hour, place, act) steps from town.json. Each
## neighbor follows it shifted by its own offset in minutes. Pure logic: the 3D walkers in
## [NpcView] ask which step is current and go there. Not thread-safe (read-only after init).
##
## Usage:
## [codeblock]
## var routine := Routine.new(town_data)
## var i: int = routine.step_at(state.minutes, 25.0)
## print(routine.place(i), " ", routine.act(i))   # "restaurante comer"
## [/codeblock]

var _steps: Array = []


## Reads the steps from [param town].
func _init(town: TownData) -> void:
	_steps = town.list("routine", "steps")


## Index of the step running at game [param minutes] for a neighbor shifted by
## [param offset_minutes]. Before the first step of the morning it is still the last one (asleep).
func step_at(minutes: float, offset_minutes: float) -> int:
	var hour: float = (minutes - offset_minutes) / 60.0
	var found: int = _steps.size() - 1
	for i in _steps.size():
		if hour >= float((_steps[i] as Dictionary)["hour"]):
			found = i
	return found


## Place of step [param i]: "home", "restaurante", "loja", "praca" or "roupas".
func place(i: int) -> String:
	return str((_steps[i] as Dictionary)["place"])


## Action of step [param i]: "acordar", "comer", "comprar", "passear", "beber" or "dormir".
func act(i: int) -> String:
	return str((_steps[i] as Dictionary)["act"])
