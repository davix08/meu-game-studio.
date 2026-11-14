extends PlayerState
## Out of health: the spirit floats upward. Terminal state.


func enter(_previous: StringName) -> void:
	player.velocity = Vector2.ZERO
	player.hurtbox.set_deferred("monitorable", false)


func physics_update(delta: float) -> void:
	player.position.y -= 90.0 * delta
	player.visual.modulate.a = maxf(0.0, player.visual.modulate.a - 0.6 * delta)


func can_shoot() -> bool:
	return false
