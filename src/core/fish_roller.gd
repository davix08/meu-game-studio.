class_name FishRoller
extends RefCounted
## Which species bites, how heavy it is and what it is worth (2D fish.js).
##
## Rarer fish weigh less; the bait, an active luck bait, deep water and fish
## schools tilt the odds upward. Undiscovered species are favoured. All draws use
## the injected [RandomSource], in the same order as the 2D. Not thread-safe.
##
## Usage:
## [codeblock]
## var roller := FishRoller.new(data, state, RandomSource.new(data.seed_value))
## var sp: GameData.Species = roller.roll_species(false, false)
## var fish: GameState.Catch = roller.roll_catch(sp)
## [/codeblock]

var _data: GameData
var _state: GameState
var _rng: RandomSource


## Builds a roller reading [param data] and the player's [param state], drawing from [param rng].
func _init(data: GameData, state: GameState, rng: RandomSource) -> void:
	_data = data
	_state = state
	_rng = rng


## Highest rarity the player's level allows (level 1 -> Comum ... level 5+ -> Lendário).
func max_rarity(level: int) -> int:
	return mini(level - 1, _data.max_rarity_index())


## True between night_start_hour and night_end_hour (18:00 to 06:00).
func is_night(minutes: float) -> bool:
	var hour: float = fmod(minutes / 60.0, 24.0)
	return hour >= _data.fixed("night_start_hour") or hour < _data.fixed("night_end_hour")


## Picks the species that bites at a spot ([param deep] water, on a fish [param school]).
## The very first catch of a game is always the configured easy species.
func roll_species(deep: bool, school: bool) -> GameData.Species:
	if _state.book.is_empty():
		return _data.species_by_id(_data.fixed_text("first_catch_species"))
	var night: bool = is_night(_state.minutes)
	var top: int = max_rarity(_state.level)
	var bait: GameData.Bait = _data.bait_by_id(_state.bait)
	var luck: bool = _state.luck_left > 0.0
	var rarity_weights: Array[float] = []
	for r: int in range(top + 1):
		if _available(r, night).is_empty():
			rarity_weights.append(0.0)
			continue
		var w: float = _data.tune(_data.rarity_weight_keys[r]) * (1.0 + bait.rare * r)
		if luck and r >= int(_data.fixed("luck_min_rarity")):
			w *= _data.tune("luck_mult")
		if deep:
			w *= 1.0 + _data.tune("deep_bonus") * r
		if school:
			w *= 1.0 + _data.tune("spot_bonus") * r
		rarity_weights.append(w)
	var list: Array[GameData.Species] = _available(pick_weighted(rarity_weights), night)
	var species_weights: Array[float] = []
	for sp: GameData.Species in list:
		species_weights.append(1.0 if _state.book.has(sp.id) else _data.tune("new_bias"))
	return list[pick_weighted(species_weights)]


## Index picked from relative [param weights] (one random draw).
func pick_weighted(weights: Array[float]) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var x: float = _rng.next_float() * total
	for i: int in weights.size():
		x -= weights[i]
		if x < 0.0:
			return i
	return weights.size() - 1


## Rolls a weight (heavier is rarer, by weight_skew) and the sale value that follows.
func roll_catch(sp: GameData.Species) -> GameState.Catch:
	var f: float = pow(_rng.next_float(), _data.tune("weight_skew"))
	var w: float = sp.kg_min + (sp.kg_max - sp.kg_min) * f
	var scale: float = pow(10.0, _data.fixed("weight_decimals"))
	var fish := GameState.Catch.new()
	fish.id = sp.id
	fish.weight = round(w * scale) / scale
	fish.value = fish_value(sp, w)
	return fish


## Sale value of a [param sp] fish weighing [param weight] kg (heavier is worth more, at least 1).
func fish_value(sp: GameData.Species, weight: float) -> int:
	var span: float = sp.kg_max - sp.kg_min
	if span == 0.0:
		span = 1.0
	var f: float = (weight - sp.kg_min) / span
	var mult: float = _data.fixed("value_base_mult") + _data.fixed("value_weight_mult") * f
	return maxi(1, roundi(sp.base_value * mult))


func _available(rarity: int, night: bool) -> Array[GameData.Species]:
	var out: Array[GameData.Species] = []
	for sp: GameData.Species in _data.species:
		if sp.rarity == rarity and (sp.time == "any" or (sp.time == "night") == night):
			out.append(sp)
	return out
