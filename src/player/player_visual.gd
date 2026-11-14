class_name PlayerVisual
extends Node2D
## Placeholder art for the player, drawn with primitives until real sprites exist.
##
## An original wandering knight: hooded cloak, round helm with a visor slit, and
## a glowing lance. Replace with an AnimatedSprite2D later; keep the same API.

const CLOAK := Color(0.32, 0.27, 0.42)
const ARMOR := Color(0.78, 0.76, 0.7)
const VISOR := Color(0.95, 0.85, 0.45)
const LANCE := Color(0.75, 0.9, 1.0)

var _facing: int = 1
var _ducking: bool = false
var _aim: Vector2 = Vector2.RIGHT
var _run_phase: float = 0.0
var _blinking: bool = false
var _blink_time: float = 0.0
var _flash_material: ShaderMaterial


func _ready() -> void:
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = preload("res://src/shaders/hit_flash.gdshader")
	material = _flash_material


## Reads the player state each frame and redraws.
func update_pose(player: Player) -> void:
	_facing = player.facing
	_ducking = player.is_ducking
	_aim = player.aim_direction()
	if absf(player.velocity.x) > 1.0 and player.is_on_floor():
		_run_phase += get_physics_process_delta_time() * 14.0
	queue_redraw()


func set_blinking(value: bool) -> void:
	_blinking = value
	if not value:
		modulate.a = 1.0


func _process(delta: float) -> void:
	if _blinking:
		_blink_time += delta
		modulate.a = 0.35 if int(_blink_time * 16.0) % 2 == 0 else 1.0


## White flash when hit (uses the hit-flash shader).
func flash_hit() -> void:
	_flash(Color(1, 1, 1), 0.12)


## Gold flash when a parry is attempted.
func flash_parry() -> void:
	_flash(Projectile.PARRY_COLOR, 0.1)


func _flash(color: Color, seconds: float) -> void:
	_flash_material.set_shader_parameter("flash_color", color)
	_flash_material.set_shader_parameter("flash_amount", 1.0)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _flash_material.set_shader_parameter("flash_amount", v),
			1.0, 0.0, seconds)


func _draw() -> void:
	var height: float = 40.0 if _ducking else 78.0
	var bob: float = sin(_run_phase) * 3.0
	var top: float = -height + bob
	# Cloak (body).
	var cloak := PackedVector2Array([
		Vector2(-22, 0), Vector2(22, 0), Vector2(14, top + 22), Vector2(-14, top + 22)])
	draw_colored_polygon(cloak, CLOAK)
	# Helm.
	var head := Vector2(2 * _facing, top + 14)
	draw_circle(head, 16.0, ARMOR)
	draw_rect(Rect2(head + Vector2(-2 + 4 * _facing, -3), Vector2(10 * _facing, 5)).abs(), VISOR)
	# Plume.
	draw_line(head + Vector2(0, -16), head + Vector2(-14 * _facing, -26), CLOAK.lightened(0.3), 4.0)
	# Lance pointing along the aim.
	var hand := Vector2(0, top + 34)
	draw_line(hand, hand + _aim * 40.0, LANCE, 4.0)
	draw_circle(hand + _aim * 40.0, 4.0, LANCE.lightened(0.4))
