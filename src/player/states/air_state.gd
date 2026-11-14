extends PlayerState
## Jumping or falling. Pressing jump again in the air attempts a parry.


func enter(_previous: StringName) -> void:
	player.parry_used = false


func physics_update(delta: float) -> void:
	player.coyote_timer = maxf(0.0, player.coyote_timer - delta)
	player.apply_horizontal_input()
	player.apply_gravity(delta)
	if Input.is_action_just_released(&"jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.stats.jump_cut_multiplier
	if Input.is_action_just_pressed(&"jump"):
		if player.coyote_timer > 0.0:
			player.jump_buffer_timer = 0.0
			player.coyote_timer = 0.0
			player.start_jump()
		elif not player.parry_used:
			player.start_parry_window()
	player.update_parry(delta)
	player.move_and_slide()
	if player.wants_dash() and player.air_dash_available:
		player.air_dash_available = false
		machine.transition_to(&"Dash")
	elif player.is_on_floor() and player.velocity.y >= 0.0:
		machine.transition_to(&"Ground")
