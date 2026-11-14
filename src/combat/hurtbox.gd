class_name Hurtbox
extends Area2D
## Area that can be hurt by a [Hitbox] (the "Damageable" of the reference structure).
##
## Passes damage to its [HealthComponent]. Detection happens on the hitbox side.

## Emitted when a hit removed health.
signal hurt(hitbox: Hitbox, amount: int)

## Health that receives the damage. Injected in the scene or by the owner.
@export var health: HealthComponent


func _ready() -> void:
	monitoring = false
	monitorable = true


## Applies [param hitbox]'s damage. Returns true if any health was removed.
func receive_hit(hitbox: Hitbox) -> bool:
	if health == null:
		return false
	var amount: int = health.take_damage(hitbox.damage)
	if amount > 0:
		hurt.emit(hitbox, amount)
		return true
	return false
