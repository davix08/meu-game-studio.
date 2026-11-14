extends PlayerState
## Short knockback after taking damage. Input is ignored.

var _time_left: float = 0.0


func enter(_previous: StringName) -> void:
	_time_left = player.stats.hit_stun_time
	player.velocity = Vector2(-player.facing * player.stats.hit_knockback.x, player.stats.hit_knockback.y)


func physics_update(delta: float) -> void:
	_time_left -= delta
	player.apply_gravity(delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")


func can_shoot() -> bool:
	return false
