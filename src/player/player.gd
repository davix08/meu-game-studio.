class_name Player
extends CharacterBody2D
## The playable knight: movement, shooting, parry and super meter.
##
## Movement rules live in [PlayerState] children of the [PlayerStateMachine];
## this script holds shared helpers and the systems that run in every state
## (shooting, timers, invulnerability).

const Layers := preload("res://src/combat/collision_layers.gd")

@export var stats: PlayerStats
## Disabled during the intro and after the fight ends.
@export var controls_enabled: bool = false

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var parry_area: Area2D = $ParryArea
@onready var weapon: PlayerWeapon = $Weapon
@onready var visual: PlayerVisual = $Visual
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

## -1 = left, 1 = right.
var facing: int = 1
var super_meter: SuperMeter
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var air_dash_available: bool = true
var parry_used: bool = false
var is_ducking: bool = false
var parry_count: int = 0

var _parry_timer: float = 0.0
var _invuln_timer: float = 0.0
var _standing_hurtbox_size: Vector2
var _standing_hurtbox_pos: Vector2


func _ready() -> void:
	collision_layer = Layers.PLAYER_BODY
	collision_mask = Layers.WORLD
	hurtbox.collision_layer = Layers.PLAYER_HURTBOX
	hurtbox.collision_mask = 0
	parry_area.collision_layer = 0
	parry_area.collision_mask = Layers.ENEMY_ATTACK
	parry_area.monitoring = true

	health.max_health = stats.max_health
	health.reset()
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.health_changed.connect(func(c: int, m: int) -> void: EventBus.player_health_changed.emit(c, m))

	super_meter = SuperMeter.new(stats.max_cards, stats.cards_per_damage, stats.cards_per_parry)
	weapon.damage_dealt.connect(_on_damage_dealt)

	var rect := hurtbox_shape.shape as RectangleShape2D
	_standing_hurtbox_size = rect.size
	_standing_hurtbox_pos = hurtbox_shape.position

	state_machine.setup(self)
	EventBus.player_health_changed.emit(health.current_health, health.max_health)
	_emit_meter()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if not controls_enabled and state_machine.current_name() != &"Dead":
		# Still fall and settle while controls are off (intro / victory).
		apply_gravity(delta)
		velocity.x = 0.0
		move_and_slide()
		visual.update_pose(self)
		return
	if Input.is_action_just_pressed(&"jump"):
		jump_buffer_timer = stats.jump_buffer_time
	state_machine.physics_update(delta)
	_handle_shooting()
	visual.update_pose(self)


# --- Input helpers -------------------------------------------------------

## Raw movement input, -1..1 per axis (y positive = down).
func input_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## True while aim-lock is held (stand still and aim in 8 directions).
func is_aim_locked() -> bool:
	return Input.is_action_pressed(&"lock_aim")


## Returns true once per buffered jump press.
func consume_jump_request() -> bool:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		return true
	return false


## True when dash was pressed and the cooldown allows it.
func wants_dash() -> bool:
	return Input.is_action_just_pressed(&"dash") and dash_cooldown_timer <= 0.0


# --- Movement helpers (used by states) -----------------------------------

func update_facing_from_input() -> void:
	var x: float = input_vector().x
	if x > Aim.DEADZONE:
		facing = 1
	elif x < -Aim.DEADZONE:
		facing = -1


func apply_horizontal_input() -> void:
	update_facing_from_input()
	if is_aim_locked():
		velocity.x = 0.0
		return
	var x: float = input_vector().x
	var dir: float = signf(x) if absf(x) > Aim.DEADZONE else 0.0
	velocity.x = dir * stats.move_speed


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * delta, stats.max_fall_speed)


func start_jump() -> void:
	velocity.y = stats.jump_velocity
	coyote_timer = 0.0


func set_ducking(value: bool) -> void:
	is_ducking = value
	var rect := hurtbox_shape.shape as RectangleShape2D
	if value:
		rect.size = Vector2(_standing_hurtbox_size.x * 1.2, _standing_hurtbox_size.y * 0.5)
		hurtbox_shape.position = _standing_hurtbox_pos + Vector2(0.0, _standing_hurtbox_size.y * 0.25)
	else:
		rect.size = _standing_hurtbox_size
		hurtbox_shape.position = _standing_hurtbox_pos


# --- Parry -----------------------------------------------------------------

func start_parry_window() -> void:
	_parry_timer = stats.parry_window
	parry_used = true
	visual.flash_parry()


## Checks for a parryable attack while the parry window is open.
func update_parry(delta: float) -> void:
	if _parry_timer <= 0.0:
		return
	_parry_timer -= delta
	for area: Area2D in parry_area.get_overlapping_areas():
		var projectile := area as Projectile
		if projectile != null and projectile.parryable:
			_perform_parry(projectile)
			return


func _perform_parry(projectile: Projectile) -> void:
	projectile.parry()
	_parry_timer = 0.0
	parry_used = false  # Chained parries are allowed.
	air_dash_available = true
	velocity.y = stats.parry_bounce_velocity
	parry_count += 1
	super_meter.add_parry()
	_emit_meter()
	_grant_invulnerability(stats.parry_invulnerability)
	EventBus.player_parried.emit()


# --- Shooting --------------------------------------------------------------

func aim_direction() -> Vector2:
	return Aim.direction(input_vector(), facing, is_on_floor(), is_aim_locked())


func muzzle_position(direction: Vector2) -> Vector2:
	var center := global_position + Vector2(0.0, -46.0 if not is_ducking else -22.0)
	return center + direction * 40.0


func _handle_shooting() -> void:
	if not state_machine.current.can_shoot():
		return
	var dir := aim_direction()
	if Input.is_action_just_pressed(&"special"):
		if super_meter.is_full() and super_meter.spend(stats.max_cards):
			weapon.fire_super(muzzle_position(dir), dir)
			_grant_invulnerability(0.8)
		elif super_meter.spend(1):
			weapon.fire_ex(muzzle_position(dir), dir)
		_emit_meter()
		return
	if GameSettings.auto_fire or Input.is_action_pressed(&"shoot"):
		weapon.try_fire(muzzle_position(dir), dir)


func _on_damage_dealt(amount: int) -> void:
	super_meter.add_damage(amount)
	_emit_meter()


func _emit_meter() -> void:
	EventBus.super_meter_changed.emit(super_meter.value, super_meter.max_cards)


# --- Damage ----------------------------------------------------------------

func _grant_invulnerability(seconds: float) -> void:
	_invuln_timer = maxf(_invuln_timer, seconds)
	health.invulnerable = true


func _tick_timers(delta: float) -> void:
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		visual.set_blinking(true)
		if _invuln_timer <= 0.0:
			health.invulnerable = false
			visual.set_blinking(false)


func _on_damaged(_amount: int) -> void:
	_grant_invulnerability(stats.invulnerability_time)
	visual.flash_hit()
	if not health.is_dead():
		state_machine.transition_to(&"Hit")


func _on_died() -> void:
	controls_enabled = false
	_invuln_timer = 0.0
	visual.set_blinking(false)
	state_machine.transition_to(&"Dead")
	EventBus.player_died.emit()
