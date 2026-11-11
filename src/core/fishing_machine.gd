class_name FishingMachine
extends RefCounted
## The fishing state machine (2D fishing.js): cast -> wait (nibbles) -> bite
## (react in time) -> fight on the bar -> caught, or the fish escapes.
##
## Advances only by [method step] at a fixed dt. Asks the world only through the
## injected [WorldQuery]. Holds no drawing code: the bar, bobber and splashes are
## drawn by story 003 from the public read-only fields and the signals below.
## Not thread-safe.
##
## Usage:
## [codeblock]
## var fishing := FishingMachine.new(data, state, rng, world_query, roller, progression)
## if fishing.cast_at(target) == FishingMachine.CastResult.CAST:
##     pass  # start the bobber animation
## # every fixed step; hold = PUXAR held, press = PUXAR went down this step
## fishing.step(1.0 / 60.0, hold, press)
## [/codeblock]

## The phase changed to [param new_phase].
signal phase_changed(new_phase: Phase)
## A nibble during the wait (bobber twitch; no reaction needed).
signal nibbled
## A fish took the bait; PUXAR must be pressed within [member react_window] seconds.
signal fish_bit(bitten: GameData.Species)
## The fish was hooked and the fight on the bar began.
signal fight_started
## The fight was won; the catch goes into the bag after catch_hold seconds.
signal fish_landed(fish: GameState.Catch)
## The cast ended without a catch, for [param reason].
signal fishing_ended(reason: EndReason)

## Phases of a cast.
enum Phase { IDLE, CAST, WAIT, BITE, FIGHT, CAUGHT }

## Result of [method cast_at] and [method cast_blocker].
enum CastResult {
	CAST, ## The cast started (from cast_blocker: casting is allowed).
	BUSY, ## A cast is already in progress.
	INDOORS, ## Not on the outdoor map.
	BAG_FULL, ## The bag holds bag_size fish.
	NO_ENERGY, ## Energy below cast_cost.
	OUT_OF_RANGE, ## The target is beyond the rod's range.
	NOT_WATER, ## The target is not water.
}

## Why a cast ended without a catch.
enum EndReason {
	PULLED_EARLY, ## PUXAR during the wait.
	TOO_SLOW, ## The bite's reaction window ran out.
	LINE_SLACK, ## Progress fell to zero in the fight.
	CANCELLED, ## The player reeled in (cancel()).
	DAY_ENDED, ## Sleep started a new day.
}

## Current phase.
var phase: Phase = Phase.IDLE
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Where the cast started (the player's position).
var origin: Vector3 = Vector3.ZERO
## Where the bobber lands.
var target: Vector3 = Vector3.ZERO
## Bobber flight 0..1 during [constant Phase.CAST].
var cast_progress: float = 0.0
## The bobber landed on a fish school.
var on_school: bool = false
## The bobber landed in deep water.
var on_deep: bool = false
## Seconds the wait lasts before the bite.
var wait_time: float = 0.0
## Seconds left of the current nibble (> 0 while the bobber twitches).
var nibble_left: float = 0.0
## The species that bit (valid from BITE on).
var species: GameData.Species = null
## Seconds allowed to react to the bite.
var react_window: float = 0.0
## Green zone width on the 0..1 bar.
var zone_width: float = 0.0
## Green zone center on the bar.
var zone_center: float = 0.0
## Indicator position on the bar, 0..1.
var indicator: float = 0.0
## Indicator velocity, bar per second.
var indicator_velocity: float = 0.0
## Catch progress, 0..1; 1 catches, 0 escapes.
var progress: float = 0.0
## The indicator is inside the green zone this step.
var in_zone: bool = false
## The landed fish (valid in CAUGHT).
var landed: GameState.Catch = null

var _data: GameData
var _state: GameState
var _rng: RandomSource
var _world: WorldQuery
var _roller: FishRoller
var _progression: Progression
var _nibble_at: float = 0.0
var _zone_target: float = 0.0
var _zone_timer: float = 0.0
var _dart_left: float = 0.0


## Builds the machine. It cancels itself when [signal GameState.day_started] fires.
func _init(data: GameData, state: GameState, rng: RandomSource, world: WorldQuery,
		roller: FishRoller, progression: Progression) -> void:
	_data = data
	_state = state
	_rng = rng
	_world = world
	_roller = roller
	_progression = progression
	_state.day_started.connect(_on_day_started)


## True when no cast is in progress.
func is_idle() -> bool:
	return phase == Phase.IDLE


## Why a cast is impossible right now, or [constant CastResult.CAST] when it is possible.
func cast_blocker() -> CastResult:
	if _state.map != GameState.MAP_OUTDOOR:
		return CastResult.INDOORS
	if phase != Phase.IDLE:
		return CastResult.BUSY
	if _state.bag.size() >= int(_data.tune("bag_size")):
		return CastResult.BAG_FULL
	if _state.energy < _data.tune("cast_cost"):
		return CastResult.NO_ENERGY
	return CastResult.CAST


## Casts from the player's position to [param at] if it is water within the rod's
## range (horizontal distance). Spends cast_cost energy and stops resting.
func cast_at(at: Vector3) -> CastResult:
	var blocked: CastResult = cast_blocker()
	if blocked != CastResult.CAST:
		return blocked
	var from: Vector3 = _state.position
	var distance: float = Vector2(at.x - from.x, at.z - from.z).length()
	if distance > _data.rod_by_id(_state.rod).cast_range:
		return CastResult.OUT_OF_RANGE
	if not _world.is_water(at):
		return CastResult.NOT_WATER
	_state.resting = false
	_state.energy = maxf(0.0, _state.energy - _data.tune("cast_cost"))
	origin = from
	target = at
	cast_progress = 0.0
	_set_phase(Phase.CAST)
	return CastResult.CAST


## Reels in: ends any cast in progress with [constant EndReason.CANCELLED].
func cancel() -> void:
	if phase != Phase.IDLE:
		_end(EndReason.CANCELLED)


## One fixed step of [param dt] seconds. [param hold]: PUXAR is held;
## [param press]: PUXAR went down during this step.
func step(dt: float, hold: bool, press: bool) -> void:
	phase_time += dt
	match phase:
		Phase.CAST:
			cast_progress = minf(1.0, phase_time / _data.tune("cast_time"))
			if cast_progress >= 1.0:
				_begin_wait()
		Phase.WAIT:
			_wait_step(dt, press)
		Phase.BITE:
			if press or hold:
				_start_fight()
			elif phase_time >= react_window:
				_end(EndReason.TOO_SLOW)
		Phase.FIGHT:
			_fight_step(dt, hold)
		Phase.CAUGHT:
			if phase_time >= _data.tune("catch_hold"):
				_finish_catch()


func _begin_wait() -> void:
	on_school = _world.in_school(target)
	on_deep = _world.is_deep(target)
	var wait_min: float = _data.tune("wait_min")
	var base: float = wait_min + _rng.next_float() * (_data.tune("wait_max") - wait_min)
	var school_mult: float = _data.tune("spot_wait") if on_school else 1.0
	wait_time = base * _data.bait_by_id(_state.bait).wait * school_mult
	_nibble_at = wait_time * (_data.fixed("nibble_first_min") + _rng.next_float() * _data.fixed("nibble_first_span"))
	nibble_left = 0.0
	_set_phase(Phase.WAIT)


func _wait_step(dt: float, press: bool) -> void:
	if press:
		_end(EndReason.PULLED_EARLY)
		return
	if phase_time > _nibble_at and nibble_left <= 0.0 and phase_time < wait_time - _data.fixed("nibble_end_margin"):
		nibble_left = _data.fixed("nibble_duration")
		_nibble_at = phase_time + _data.fixed("nibble_gap_min") + _rng.next_float() * _data.fixed("nibble_gap_span")
		nibbled.emit()
	if nibble_left > 0.0:
		nibble_left -= dt
	if phase_time >= wait_time:
		species = _roller.roll_species(on_deep, on_school)
		react_window = _data.tune("react_window") - species.difficulty * _data.tune("react_hard")
		_set_phase(Phase.BITE)
		fish_bit.emit(species)


func _start_fight() -> void:
	var d: float = species.difficulty
	zone_width = maxf(_data.tune("zone_min"), _data.tune("zone_base") + _data.rod_by_id(_state.rod).zone - d * _data.tune("zone_shrink"))
	zone_center = _data.fixed("zone_start")
	_zone_target = zone_center
	_zone_timer = _data.fixed("zone_first_move")
	_dart_left = 0.0
	indicator = _data.fixed("indicator_start")
	indicator_velocity = 0.0
	progress = _data.tune("progress_start")
	in_zone = false
	_set_phase(Phase.FIGHT)
	fight_started.emit()


func _fight_step(dt: float, hold: bool) -> void:
	var d: float = species.difficulty
	var rod: GameData.Rod = _data.rod_by_id(_state.rod)
	# Indicator physics: PUXAR pushes up, releasing lets it fall; the bar ends bounce it.
	var accel: float = _data.tune("pull_accel") if hold else -_data.tune("fall_accel")
	var max_vel: float = _data.tune("max_vel")
	var bounce: float = _data.fixed("wall_bounce")
	indicator_velocity = clampf(indicator_velocity + accel * dt, -max_vel, max_vel)
	indicator += indicator_velocity * dt
	if indicator < 0.0:
		indicator = 0.0
		indicator_velocity = absf(indicator_velocity) * bounce
	if indicator > 1.0:
		indicator = 1.0
		indicator_velocity = -absf(indicator_velocity) * bounce
	# Zone movement: it wanders to a new target now and then, and darts for hard fish.
	_zone_timer -= dt
	var half: float = zone_width / 2.0
	if _zone_timer <= 0.0:
		_zone_target = half + _rng.next_float() * (1.0 - zone_width)
		var hold_time: float = _data.fixed("zone_hold_base") - d * _data.fixed("zone_hold_hard")
		_zone_timer = hold_time * (_data.fixed("zone_hold_rand_min") + _rng.next_float())
	if _rng.next_float() < _data.tune("dart_chance") * d * d * dt:
		_zone_target = half + _rng.next_float() * (1.0 - zone_width)
		_dart_left = _data.fixed("dart_time")
	var speed: float = _data.tune("zone_speed") + _data.tune("zone_speed_hard") * d
	if _dart_left > 0.0:
		speed *= _data.fixed("dart_speed_mult")
		_dart_left -= dt
	var dz: float = _zone_target - zone_center
	zone_center += signf(dz) * minf(absf(dz), speed * dt)
	# Progress: grows inside the zone, drains outside.
	in_zone = absf(indicator - zone_center) <= half
	if in_zone:
		progress += _data.tune("progress_gain") * rod.power * (1.0 - d * _data.fixed("gain_hard_penalty")) * dt
	else:
		progress -= (_data.tune("progress_loss") + _data.tune("progress_loss_hard") * d) * dt
	if progress >= 1.0:
		landed = _roller.roll_catch(species)
		_set_phase(Phase.CAUGHT)
		fish_landed.emit(landed)
	elif progress <= 0.0:
		_end(EndReason.LINE_SLACK)


func _finish_catch() -> void:
	var fish: GameState.Catch = landed
	_state.bag.append(fish)
	var prev: GameState.BookEntry = _state.book.get(fish.id, null)
	var is_new: bool = prev == null
	var is_record: bool = prev != null and fish.weight > prev.best
	var entry := GameState.BookEntry.new()
	entry.count = (0 if is_new else prev.count) + 1
	entry.best = fish.weight if is_new else maxf(prev.best, fish.weight)
	_state.book[fish.id] = entry
	_state.stats_caught += 1
	_reset()
	_state.fish_caught.emit(fish, is_new, is_record)
	_progression.check_level_up()


func _end(reason: EndReason) -> void:
	_reset()
	fishing_ended.emit(reason)


func _reset() -> void:
	species = null
	landed = null
	_set_phase(Phase.IDLE)


func _set_phase(next: Phase) -> void:
	phase = next
	phase_time = 0.0
	phase_changed.emit(phase)


func _on_day_started(_day: int, _auto: bool) -> void:
	if phase != Phase.IDLE:
		_end(EndReason.DAY_ENDED)
