extends PlayerState
## Idle and running on the floor.


func enter(_previous: StringName) -> void:
	player.air_dash_available = true


func physics_update(delta: float) -> void:
	player.apply_horizontal_input()
	player.apply_gravity(delta)
	player.move_and_slide()
	if player.consume_jump_request():
		player.start_jump()
		machine.transition_to(&"Air")
	elif player.wants_dash():
		machine.transition_to(&"Dash")
	elif not player.is_on_floor():
		player.coyote_timer = player.stats.coyote_time
		machine.transition_to(&"Air")
	elif player.input_vector().y > Aim.DEADZONE and not player.is_aim_locked():
		machine.transition_to(&"Duck")
