# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
# Touch HUD: left move stick, run button (toggle), right aim stick, debug line.
extends CanvasLayer

const Stick := preload("res://stick.gd")

var left_stick: Node2D
var right_stick: Node2D
var run_on := false
var run_center := Vector2.ZERO
var run_radius := 17.0
var _run_touch := -1
var _overlay: Node2D
var debug: Label


func _ready() -> void:
	left_stick = Stick.new()
	right_stick = Stick.new()
	right_stick.tint = Color(1, 0.92, 0.6)
	add_child(left_stick)
	add_child(right_stick)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	debug = Label.new()
	debug.position = Vector2(6, 4)
	debug.add_theme_font_size_override("font_size", 8)
	debug.add_theme_color_override("font_outline_color", Color.BLACK)
	debug.add_theme_constant_override("outline_size", 2)
	add_child(debug)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	left_stick.home = Vector2(62, s.y - 60)
	left_stick.zone = Rect2(0, s.y * 0.35, s.x * 0.42, s.y * 0.65)
	right_stick.home = Vector2(s.x - 62, s.y - 60)
	right_stick.zone = Rect2(s.x * 0.58, s.y * 0.35, s.x * 0.42, s.y * 0.65)
	run_center = Vector2(132, s.y - 98)
	left_stick.reset()
	right_stick.reset()
	_overlay.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.distance_to(run_center) <= run_radius + 6:
				_run_touch = t.index
				run_on = not run_on
				_overlay.queue_redraw()
			elif not left_stick.try_press(t.index, t.position):
				right_stick.try_press(t.index, t.position)
		else:
			if t.index == _run_touch:
				_run_touch = -1
			left_stick.release(t.index)
			right_stick.release(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		left_stick.drag(d.index, d.position)
		right_stick.drag(d.index, d.position)


func _draw_overlay() -> void:
	var a := 0.75 if run_on else 0.35
	_overlay.draw_circle(run_center, run_radius + 3, Color(0, 0, 0, 0.3))
	_overlay.draw_circle(run_center, run_radius, Color(0.95, 0.55, 0.25, a) if run_on else Color(1, 1, 1, a))
	# little running-shoe arrows
	for i in 2:
		var o := run_center + Vector2(-5 + i * 6, 0)
		_overlay.draw_colored_polygon(PackedVector2Array([o + Vector2(-3, -5), o + Vector2(3, 0), o + Vector2(-3, 5)]), Color(0.1, 0.1, 0.1, 0.8))
