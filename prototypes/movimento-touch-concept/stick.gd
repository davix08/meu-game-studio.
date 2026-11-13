# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
# Virtual analog stick. A touch that starts inside `zone` grabs it; the base
# jumps to the touch point (dynamic) and returns home on release.
extends Node2D

var home := Vector2.ZERO
var zone := Rect2()
var radius := 34.0
var dead_zone := 0.18 # fraction of radius
var dynamic := true
var tint := Color(1, 1, 1)

var value := Vector2.ZERO # length 0..1, dead zone removed and rescaled
var touch_index := -1
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


func reset() -> void:
	touch_index = -1
	_base = home
	_knob = home
	value = Vector2.ZERO
	queue_redraw()


func try_press(index: int, pos: Vector2) -> bool:
	if touch_index != -1 or not zone.has_point(pos):
		return false
	touch_index = index
	_base = pos if dynamic else home
	_drag(pos)
	return true


func drag(index: int, pos: Vector2) -> void:
	if index == touch_index:
		_drag(pos)


func release(index: int) -> void:
	if index == touch_index:
		reset()


func _drag(pos: Vector2) -> void:
	var off := (pos - _base).limit_length(radius)
	_knob = _base + off
	var n := off.length() / radius
	if n < dead_zone:
		value = Vector2.ZERO
	else:
		value = off.normalized() * ((n - dead_zone) / (1.0 - dead_zone))
	queue_redraw()


func _draw() -> void:
	var active := touch_index != -1
	var a := 0.55 if active else 0.3
	draw_circle(_base, radius + 4, Color(0, 0, 0, a * 0.5))
	draw_arc(_base, radius, 0, TAU, 32, Color(tint, a), 2.0)
	draw_arc(_base, radius * dead_zone, 0, TAU, 16, Color(tint, a * 0.5), 1.0)
	draw_circle(_knob, 13, Color(tint, a + 0.2))
	draw_circle(_knob + Vector2(-3, -3), 4, Color(1, 1, 1, a))
