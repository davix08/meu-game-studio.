extends PlayerState
## Crouched: smaller hurtbox, no movement, low shots.


func enter(_previous: StringName) -> void:
	player.set_ducking(true)
	player.velocity.x = 0.0


func exit() -> void:
	player.set_ducking(false)


func physics_update(delta: float) -> void:
	player.update_facing_from_input()
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
	if player.consume_jump_request():
		player.start_jump()
		machine.transition_to(&"Air")
	elif player.wants_dash():
		machine.transition_to(&"Dash")
	elif player.input_vector().y <= Aim.DEADZONE or not player.is_on_floor():
		machine.transition_to(&"Ground")
