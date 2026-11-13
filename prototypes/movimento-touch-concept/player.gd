# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
extends CharacterBody2D

const WALK_SPEED := 70.0
const RUN_SPEED := 125.0
const ACCEL := 900.0 # px/s^2 — high = immediate response
const DECEL := 1400.0

var move_input := Vector2.ZERO # set by main from the stick / keyboard, length <= 1
var aim_input := Vector2.ZERO
var running := false

var facing := 2 # 0=E,1=SE,2=S,3=SW,4=W,5=NW,6=N,7=NE
var _phase := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var dir := move_input.limit_length(1.0) # diagonal never faster than straight
	var target := dir * (RUN_SPEED if running else WALK_SPEED)
	var rate := ACCEL if dir.length() > 0.01 else DECEL
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()
	if dir.length() > 0.01:
		facing = wrapi(int(round(dir.angle() / (PI / 4.0))), 0, 8)
		_phase += delta * velocity.length() * 0.18
	else:
		_phase = 0.0
	queue_redraw()


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
	draw_circle(Vector2.ZERO, r.x, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	var moving := velocity.length() > 5.0
	var step := sin(_phase) if moving else 0.0
	var bob := absf(step) * -1.0
	var side := facing in [0, 1, 7, 3, 4, 5]
	var flip := -1.0 if facing in [3, 4, 5] else 1.0
	var up := facing in [5, 6, 7]
	var down := facing in [1, 2, 3]
	# aim indicator (right stick)
	if aim_input.length() > 0.2:
		var a := aim_input.normalized()
		for i in 5:
			draw_rect(Rect2(a * (14 + i * 5) + Vector2(-1, -9), Vector2(2, 2)), Color(1, 1, 1, 0.8 - i * 0.12))
		var tip := a * 42 + Vector2(0, -8)
		draw_colored_polygon(PackedVector2Array([tip + a * 5, tip + a.orthogonal() * 4, tip - a.orthogonal() * 4]), Color(1, 0.95, 0.6, 0.9))
	_ellipse(Vector2(0, 1), Vector2(6, 2.5), Color(0, 0, 0, 0.3))
	# legs
	draw_rect(Rect2(-3, -5 + maxf(step, 0) * -2, 2, 5), Color("2f3a5c"))
	draw_rect(Rect2(1, -5 + maxf(-step, 0) * -2, 2, 5), Color("2f3a5c"))
	# body (shirt + overalls strap)
	draw_rect(Rect2(-4, -12 + bob, 8, 8), Color("c9583a"))
	draw_rect(Rect2(-4, -7 + bob, 8, 3), Color("3e5a8c"))
	# arms swing
	draw_rect(Rect2(-5, -11 + bob + step, 1, 5), Color("e3b58c"))
	draw_rect(Rect2(4, -11 + bob - step, 1, 5), Color("e3b58c"))
	# head
	draw_rect(Rect2(-3, -18 + bob, 6, 6), Color("e3b58c"))
	if down:
		draw_rect(Rect2(-2, -15 + bob, 1, 1), Color("2b1d14"))
		draw_rect(Rect2(1, -15 + bob, 1, 1), Color("2b1d14"))
	elif side and not up:
		draw_rect(Rect2(1.0 * flip, -15 + bob, 1, 1), Color("2b1d14"))
	if up:
		draw_rect(Rect2(-3, -16 + bob, 6, 3), Color("5a3a22")) # hair at back
	# straw hat
	draw_rect(Rect2(-5, -19 + bob, 10, 2), Color("d8b860"))
	draw_rect(Rect2(-3, -21 + bob, 6, 2), Color("e6c870"))
	draw_rect(Rect2(-3, -19 + bob, 6, 1), Color("a8452f"))
