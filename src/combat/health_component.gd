class_name HealthComponent
extends Node
## Hit points for any damageable entity (player or boss).
##
## Pure logic, no physics: [Hurtbox] calls [method take_damage]. Usable without
## a scene tree — call [method reset] after setting [member max_health].

## Emitted whenever current health changes.
signal health_changed(current: int, maximum: int)
## Emitted after damage is applied, with the amount actually removed.
signal damaged(amount: int)
## Emitted once when health reaches zero.
signal died

## Maximum hit points.
@export var max_health: int = 3

## Current hit points.
var current_health: int = 0
## While true, [method take_damage] does nothing (i-frames, intro, dash charms).
var invulnerable: bool = false


func _ready() -> void:
	reset()


## Restores full health without emitting [signal died].
func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Removes up to [param amount] hit points. Returns the amount actually removed.
func take_damage(amount: int) -> int:
	if amount <= 0 or invulnerable or is_dead():
		return 0
	var applied: int = mini(amount, current_health)
	current_health -= applied
	damaged.emit(applied)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return applied


## Adds hit points, capped at [member max_health]. Returns the amount healed.
func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var healed: int = mini(amount, max_health - current_health)
	current_health += healed
	health_changed.emit(current_health, max_health)
	return healed


## True once health has reached zero.
func is_dead() -> bool:
	return current_health <= 0


## Health as 0..1, used for boss phase thresholds.
func fraction() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
