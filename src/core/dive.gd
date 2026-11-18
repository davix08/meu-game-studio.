class_name Dive
extends RefCounted
## One harpoon dive (design/gdd/diving.md): oxygen runs down while the diver swims; the
## harpoon hits the first fish along the aim within range; surfacing keeps the haul,
## running out of air keeps only part of it. Pure logic over a flat arena in blocks
## (x right, y down), so it is testable without the 3D view.
##
## Usage:
## [codeblock]
## var dive := Dive.new(data, state, roller, rng)
## if dive.start() == Dive.StartResult.OK:
##     dive.step(delta, move_dir)
##     dive.shoot(aim_dir)
##     var kept: Array[GameState.Catch] = dive.surface()
## [/codeblock]

## The dive ended: [param reason], and the fish kept.
signal ended(reason: EndReason, kept: Array[GameState.Catch])
## The harpoon hit [param fish].
signal speared(fish: DiveFish)
## The harpoon was fired (hit or miss) from [param from] along [param dir].
signal fired(from: Vector2, dir: Vector2, hit: bool)

enum StartResult { OK, NO_ENERGY, BAG_FULL }
enum EndReason { SURFACED, OUT_OF_AIR }

## A fish swimming in the arena.
class DiveFish:
	extends RefCounted
	## The rolled catch (species, weight, length, value).
	var fish: GameState.Catch
	## Position in blocks.
	var pos: Vector2 = Vector2.ZERO
	## Velocity in blocks per second.
	var vel: Vector2 = Vector2.ZERO

## Seconds of air left.
var oxygen: float = 0.0
## Seconds of air at the start.
var oxygen_max: float = 0.0
## The diver's position in blocks (arena coordinates).
var diver: Vector2 = Vector2.ZERO
## Last non-zero swim direction (where the harpoon points).
var facing: Vector2 = Vector2.RIGHT
## Fish still swimming.
var fish: Array[DiveFish] = []
## Fish speared this dive, in order.
var haul: Array[GameState.Catch] = []
## Arena size in blocks.
var arena: Vector2 = Vector2.ZERO
## True between start() and the end.
var active: bool = false

var _data: GameData
var _state: GameState
var _roller: FishRoller
var _rng: RandomSource
var _cfg: Dictionary
var _reload_left: float = 0.0


func _init(data: GameData, state: GameState, roller: FishRoller, rng: RandomSource) -> void:
	_data = data
	_state = state
	_roller = roller
	_rng = rng
	_cfg = data.dive


## Starts a dive: spends energy, fills the air, spawns the fish. Nothing changes on failure.
func start() -> StartResult:
	if _state.energy < float(_cfg["energy_cost"]):
		return StartResult.NO_ENERGY
	if _state.bag.size() >= int(_data.tune("bag_size")):
		return StartResult.BAG_FULL
	_state.energy -= float(_cfg["energy_cost"])
	arena = Vector2(float(_cfg["arena"]["w"]), float(_cfg["arena"]["h"]))
	oxygen_max = float(_cfg["oxygen_seconds"])
	oxygen = oxygen_max
	diver = Vector2(1.5, arena.y * 0.5)
	facing = Vector2.RIGHT
	haul.clear()
	fish.clear()
	_reload_left = 0.0
	for i: int in int(_cfg["fish_count"]):
		fish.append(_spawn())
	active = true
	return StartResult.OK


## Advances [param dt] seconds: air runs down, the diver swims along [param move]
## (any length; normalized), fish wander and bounce off the arena walls.
func step(dt: float, move: Vector2) -> void:
	if not active:
		return
	_reload_left = maxf(0.0, _reload_left - dt)
	if move.length_squared() > 0.0001:
		facing = move.normalized()
		diver += facing * float(_cfg["swim_speed"]) * dt
		diver = diver.clamp(Vector2(0.5, 0.5), arena - Vector2(0.5, 0.5))
	for f: DiveFish in fish:
		f.pos += f.vel * dt
		if f.pos.x < 0.5 or f.pos.x > arena.x - 0.5:
			f.vel.x = -f.vel.x
		if f.pos.y < 0.5 or f.pos.y > arena.y - 0.5:
			f.vel.y = -f.vel.y
		f.pos = f.pos.clamp(Vector2(0.5, 0.5), arena - Vector2(0.5, 0.5))
	oxygen = maxf(0.0, oxygen - dt)
	if oxygen <= 0.0:
		_end(EndReason.OUT_OF_AIR)


## True when the harpoon is loaded.
func can_shoot() -> bool:
	return active and _reload_left <= 0.0


## Fires the harpoon along [param dir] (the facing when zero). Hits the nearest fish
## whose center is within harpoon_hit_radius of the shot line and harpoon_range ahead.
## Returns the fish hit, or null (miss or reloading).
func shoot(dir: Vector2 = Vector2.ZERO) -> DiveFish:
	if not can_shoot():
		return null
	var aim: Vector2 = dir.normalized() if dir.length_squared() > 0.0001 else facing
	_reload_left = float(_cfg["harpoon_reload"])
	var best: DiveFish = null
	var best_along: float = INF
	for f: DiveFish in fish:
		var to: Vector2 = f.pos - diver
		var along: float = to.dot(aim)
		if along < 0.0 or along > float(_cfg["harpoon_range"]):
			continue
		var off: float = absf(to.cross(aim))
		if off <= float(_cfg["harpoon_hit_radius"]) and along < best_along:
			best = f
			best_along = along
	fired.emit(diver, aim, best != null)
	if best != null:
		fish.erase(best)
		haul.append(best.fish)
		speared.emit(best)
	return best


## Swims up with the whole haul. Returns the fish kept.
func surface() -> Array[GameState.Catch]:
	return _end(EndReason.SURFACED)


## Fish kept when a dive ends for [param reason] with [param count] fish speared:
## all when surfacing; when out of air, the first ceil(count * (1 - loss_fraction)).
static func kept_count(reason: EndReason, count: int, loss_fraction: float) -> int:
	if reason == EndReason.SURFACED:
		return count
	return ceili(float(count) * (1.0 - loss_fraction))


func _end(reason: EndReason) -> Array[GameState.Catch]:
	if not active:
		return []
	active = false
	var kept: Array[GameState.Catch] = []
	var keep: int = kept_count(reason, haul.size(), float(_cfg["loss_fraction"]))
	var room: int = int(_data.tune("bag_size")) - _state.bag.size()
	for i: int in mini(keep, room):
		kept.append(haul[i])
	ended.emit(reason, kept)
	return kept


func _spawn() -> DiveFish:
	var f := DiveFish.new()
	f.fish = _roller.roll_catch(_pick_species())
	f.pos = Vector2(3.0 + _rng.next_float() * (arena.x - 4.0), 1.0 + _rng.next_float() * (arena.y - 2.0))
	var angle: float = _rng.next_float() * TAU
	var speed: float = lerpf(float(_cfg["fish_speed_min"]), float(_cfg["fish_speed_max"]), _rng.next_float())
	f.vel = Vector2(cos(angle), sin(angle)) * speed
	return f


## A dive species, weighted by rarity like the rod (rarity_weight_keys), capped by level.
func _pick_species() -> GameData.Species:
	var top: int = _roller.max_rarity(_state.level)
	var pool: Array[GameData.Species] = []
	var weights: Array[float] = []
	for id: Variant in _cfg["species"]:
		var sp: GameData.Species = _data.species_by_id(str(id))
		if sp.rarity <= top:
			pool.append(sp)
			weights.append(_data.tune(_data.rarity_weight_keys[sp.rarity]))
	return pool[_roller.pick_weighted(weights)]
