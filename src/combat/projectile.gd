class_name Projectile
extends Hitbox
## Moving hitbox for shots from the player or a boss.
##
## Built entirely in code (no scene needed): create, call [method setup], add to
## the tree. Parryable projectiles are drawn in the parry color and can be
## parried by the player in the air.

const Layers := preload("res://src/combat/collision_layers.gd")

## Color used for parryable attacks, everywhere in the game.
const PARRY_COLOR := Color(1.0, 0.78, 0.25)

## Units per second.
var velocity: Vector2 = Vector2.ZERO
## Downward acceleration (0 = straight line).
var fall_acceleration: float = 0.0
## Seconds before the projectile frees itself.
var lifetime: float = 3.0
## Can be parried by the player.
var parryable: bool = false
## Fill color.
var color: Color = Color.WHITE
## Collision and draw radius.
var radius: float = 10.0
## Free when hitting the floor (y >= floor_y). INF disables.
var floor_y: float = INF

var _age: float = 0.0


## Configures the projectile. [param from_player] picks the collision team.
func setup(from_player: bool, start: Vector2, vel: Vector2, dmg: int, rad: float, col: Color) -> Projectile:
	global_position = start
	velocity = vel
	damage = dmg
	radius = rad
	color = col
	one_shot = true
	if from_player:
		collision_layer = Layers.PLAYER_ATTACK
		collision_mask = Layers.ENEMY_HURTBOX
	else:
		collision_layer = Layers.ENEMY_ATTACK
		collision_mask = Layers.PLAYER_HURTBOX
	return self


## Marks the projectile as parryable and recolors it.
func make_parryable() -> Projectile:
	parryable = true
	color = PARRY_COLOR
	return self


func _ready() -> void:
	super._ready()
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col_shape := CollisionShape2D.new()
	col_shape.shape = shape
	add_child(col_shape)


func _physics_process(delta: float) -> void:
	velocity.y += fall_acceleration * delta
	global_position += velocity * delta
	_age += delta
	if _age >= lifetime or global_position.y >= floor_y:
		queue_free()
		return
	super._physics_process(delta)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.5, color.lightened(0.5))


## Called by the player on a successful parry.
func parry() -> void:
	active = false
	queue_free()


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	queue_free()
