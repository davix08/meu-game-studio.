extends PlayerState
## Fast horizontal burst, no gravity, no shooting.

var _time_left: float = 0.0


func enter(_previous: StringName) -> void:
	_time_left = player.stats.dash_duration
	player.update_facing_from_input()
	player.velocity = Vector2(player.facing * player.stats.dash_speed, 0.0)


func exit() -> void:
	player.dash_cooldown_timer = player.stats.dash_cooldown
	player.velocity.x = player.facing * player.stats.move_speed


func physics_update(delta: float) -> void:
	_time_left -= delta
	player.velocity.y = 0.0
	player.move_and_slide()
	if _time_left <= 0.0:
		machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")


func can_shoot() -> bool:
	return false
