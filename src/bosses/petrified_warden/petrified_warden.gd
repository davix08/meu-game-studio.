extends Boss
## Vigia Petrificado — the first boss. An ancient stone sentinel that guards the
## gate of the fallen city of Vesper. Original design for this project.
##
## Attacks (ids used in assets/data/bosses/petrified_warden.tres):
## - stone_volley: lobs arcing stones at the player.
## - ground_wave: sends a shockwave along the floor (jump over it).
## - shard_rain: shards fall from the ceiling across the arena.
## - slam: leaps toward the player and slams, sending waves both ways.

const STONE := Color(0.55, 0.52, 0.5)
const RUNE := Color(0.45, 0.85, 0.95)

@export_group("Attack tuning")
@export var volley_count: int = 3
@export var volley_interval: float = 0.35
@export var volley_flight_time: float = 1.1
@export var wave_speed: float = 520.0
@export var rain_count: int = 7
@export var rain_speed: float = 520.0
@export var arena_left: float = 80.0
@export var arena_right: float = 1200.0
@export var slam_rise_time: float = 0.45
@export var slam_fall_time: float = 0.2

@onready var visual: Node2D = $Visual

var _home_position: Vector2


func _ready() -> void:
	super._ready()
	_home_position = global_position


func perform_attack(attack_id: String) -> void:
	match attack_id:
		"stone_volley":
			await _stone_volley()
		"ground_wave":
			await _ground_wave()
		"shard_rain":
			await _shard_rain()
		"slam":
			await _slam()
		_:
			await super.perform_attack(attack_id)


func _on_phase_entered(index: int) -> void:
	visual.modulate = current_phase().tint
	visual.set("cracks", index)
	visual.queue_redraw()


func _hand_position() -> Vector2:
	return global_position + Vector2(-70, -190)


func _stone_volley() -> void:
	await _telegraph(0.35)
	for i: int in volley_count:
		if not fighting:
			return
		# Ballistic arc that lands on the player's current position.
		var start := _hand_position()
		var goal := target_position() + Vector2(0, -20)
		var t: float = volley_flight_time
		var g: float = 1400.0
		var vel := Vector2((goal.x - start.x) / t, (goal.y - start.y - 0.5 * g * t * t) / t)
		spawn_projectile(start, vel / current_phase().projectile_speed_scale, 18.0, STONE, g)
		await wait(volley_interval)


func _ground_wave() -> void:
	await _telegraph(0.5)
	_spawn_wave(-1.0)
	await wait(0.6)


func _spawn_wave(direction: float) -> void:
	var start := Vector2(global_position.x + direction * 60.0, floor_y - 16.0)
	var p := spawn_projectile(start, Vector2(direction * wave_speed, 0.0), 22.0, RUNE)
	p.floor_y = INF


func _shard_rain() -> void:
	await _telegraph(0.4)
	var width := arena_right - arena_left
	for i: int in rain_count:
		if not fighting:
			return
		# Evenly spread, offset each cast so it is learnable, not random.
		var x := arena_left + width * (float(i) + 0.5) / float(rain_count)
		if i % 2 == 1:
			x += width / float(rain_count) * 0.25
		spawn_projectile(Vector2(x, -30.0), Vector2(0.0, rain_speed), 14.0, RUNE.darkened(0.2))
		await wait(0.12)
	await wait(0.6)


func _slam() -> void:
	await _telegraph(0.3)
	var land_x := clampf(target_position().x, arena_left + 120.0, arena_right - 120.0)
	var up := create_tween()
	up.tween_property(self, "global_position", Vector2(land_x, _home_position.y - 360.0), slam_rise_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await up.finished
	await wait(0.25)
	var down := create_tween()
	down.tween_property(self, "global_position", Vector2(land_x, _home_position.y), slam_fall_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await down.finished
	_spawn_wave(-1.0)
	_spawn_wave(1.0)
	await wait(0.7)
	var back := create_tween()
	back.tween_property(self, "global_position", _home_position, 0.6)
	await back.finished


## Visual warning before an attack (runes glow), so every attack is readable.
func _telegraph(seconds: float) -> void:
	visual.set("glow", 1.0)
	visual.queue_redraw()
	await wait(seconds)
	visual.set("glow", 0.0)
	visual.queue_redraw()
