class_name PlayerWeapon
extends Node2D
## Spawns the player's shots, EX shots and super beam (the "PlayerWeapon").
##
## Owns the fire-rate timer. The [Player] tells it where to aim and when.

## Emitted when one of our attacks deals damage (feeds the super meter).
signal damage_dealt(amount: int)

const Layers := preload("res://src/combat/collision_layers.gd")

@export var data: WeaponData
## Node new projectiles are added to (the level). Defaults to the scene root.
var projectile_parent: Node

var _cooldown: float = 0.0
var _shot_count: int = 0


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


## Fires a normal shot if the fire-rate allows. Returns true if fired.
func try_fire(origin: Vector2, direction: Vector2) -> bool:
	if _cooldown > 0.0 or data == null:
		return false
	_cooldown = data.fire_interval
	_shot_count += 1
	# Deterministic small spread: alternate offsets instead of random.
	var side: float = 1.0 if _shot_count % 2 == 0 else -1.0
	var offset: Vector2 = direction.orthogonal() * side * data.spread_pixels
	var p := Projectile.new().setup(true, origin + offset, direction * data.projectile_speed,
			data.damage, data.projectile_radius, data.color)
	p.lifetime = data.projectile_lifetime
	_spawn(p)
	return true


## Fires the EX shot (caller has already spent the card).
func fire_ex(origin: Vector2, direction: Vector2) -> void:
	var p := Projectile.new().setup(true, origin, direction * data.ex_speed,
			data.ex_damage, data.ex_radius, data.ex_color)
	p.lifetime = 2.0
	_spawn(p)


## Fires the super beam (caller has already spent the meter).
func fire_super(origin: Vector2, direction: Vector2) -> void:
	var beam := Hitbox.new()
	beam.damage = data.super_tick_damage
	beam.rehit_interval = data.super_tick_interval
	beam.collision_layer = Layers.PLAYER_ATTACK
	beam.collision_mask = Layers.ENEMY_HURTBOX
	var rect := RectangleShape2D.new()
	rect.size = Vector2(data.super_length, data.super_width)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(data.super_length * 0.5, 0.0)
	beam.add_child(shape)
	var visual := ColorRect.new()
	visual.color = data.super_color
	visual.size = rect.size
	visual.position = Vector2(0.0, -data.super_width * 0.5)
	beam.add_child(visual)
	beam.global_position = origin
	beam.rotation = direction.angle()
	beam.hit_landed.connect(func(_h: Hurtbox, amount: int) -> void: damage_dealt.emit(amount))
	_spawn(beam)
	var tween := beam.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, data.super_duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(beam.queue_free)


func _spawn(node: Node2D) -> void:
	if node is Projectile:
		(node as Projectile).hit_landed.connect(func(_h: Hurtbox, amount: int) -> void: damage_dealt.emit(amount))
	var parent: Node = projectile_parent if projectile_parent != null else get_tree().current_scene
	parent.add_child(node)
