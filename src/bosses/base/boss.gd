class_name Boss
extends Node2D
## Base class for bosses: health, phases and the attack loop.
##
## Subclasses override [method perform_attack] and run each attack as a
## coroutine that returns when the attack finishes.

## Emitted when the boss moves to a new phase.
signal phase_changed(phase_index: int)
## Emitted once when the boss is defeated.
signal defeated

const Layers := preload("res://src/combat/collision_layers.gd")

@export var data: BossData
## Arena floor height in global coordinates (for ground attacks).
@export var floor_y: float = 640.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox

## The player to aim at. Injected by the level.
var target: Node2D
## Node projectiles are spawned into. Injected by the level.
var projectile_parent: Node
var phase_index: int = 0
var fighting: bool = false

var _attack_cursor: int = 0
var _projectile_counter: int = 0


func _ready() -> void:
	hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	hurtbox.collision_mask = 0
	contact_hitbox.collision_layer = Layers.ENEMY_ATTACK
	contact_hitbox.collision_mask = Layers.PLAYER_HURTBOX
	contact_hitbox.damage = data.contact_damage
	contact_hitbox.active = false
	health.max_health = data.max_health
	health.reset()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


## Starts the attack loop.
func start_fight() -> void:
	fighting = true
	contact_hitbox.active = true
	_attack_loop()


## Stops attacking (player died or boss defeated).
func stop_fight() -> void:
	fighting = false
	contact_hitbox.active = false


## Current phase data.
func current_phase() -> BossPhaseData:
	return data.phases[phase_index]


## Index of the phase for [param fraction] of health left, given phases ordered
## by descending [member BossPhaseData.start_health_fraction].
static func phase_for_fraction(fraction: float, thresholds: PackedFloat32Array) -> int:
	var result: int = 0
	for i: int in thresholds.size():
		if fraction <= thresholds[i] + 0.0001:
			result = i
	return result


func _phase_thresholds() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for phase: BossPhaseData in data.phases:
		out.append(phase.start_health_fraction)
	return out


func _attack_loop() -> void:
	while fighting and is_inside_tree():
		var phase := current_phase()
		if not phase.attacks.is_empty():
			var attack_id: String = phase.attacks[_attack_cursor % phase.attacks.size()]
			_attack_cursor += 1
			await perform_attack(attack_id)
		if not fighting or not is_inside_tree():
			return
		await wait(current_phase().attack_cooldown)


## Runs one attack and returns when it is over. Subclasses override this and
## dispatch on [param attack_id] (ids come from [member BossPhaseData.attacks]).
func perform_attack(attack_id: String) -> void:
	push_error("%s: attack '%s' not implemented" % [name, attack_id])
	await wait(0.1)


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.boss_health_changed.emit(current, maximum)
	if data.phases.is_empty():
		return
	var new_phase := phase_for_fraction(health.fraction(), _phase_thresholds())
	if new_phase > phase_index:
		phase_index = new_phase
		_attack_cursor = 0
		_on_phase_entered(phase_index)
		phase_changed.emit(phase_index)
		EventBus.boss_phase_changed.emit(phase_index)


## Hook for subclasses (change look, reposition...).
func _on_phase_entered(_index: int) -> void:
	pass


func _on_died() -> void:
	stop_fight()
	defeated.emit()
	EventBus.boss_defeated.emit()


# --- Helpers for subclasses ------------------------------------------------

## Spawns an enemy projectile. Every Nth one of the phase is parryable.
func spawn_projectile(start: Vector2, velocity: Vector2, radius: float, color: Color, fall_acceleration: float = 0.0) -> Projectile:
	var p := Projectile.new().setup(false, start, velocity * current_phase().projectile_speed_scale,
			data.projectile_damage, radius, color)
	p.fall_acceleration = fall_acceleration
	p.lifetime = 6.0
	p.floor_y = floor_y + radius
	_projectile_counter += 1
	var every: int = current_phase().parryable_every
	if every > 0 and _projectile_counter % every == 0:
		p.make_parryable()
	var parent: Node = projectile_parent if projectile_parent != null else get_parent()
	parent.add_child(p)
	return p


## Global position of the target, or a point ahead of the boss if none.
func target_position() -> Vector2:
	return target.global_position if target != null else global_position + Vector2(-600, 0)


## Waits [param seconds] of game time.
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
