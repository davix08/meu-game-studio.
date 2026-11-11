class_name VirtualStick
extends Control
## Our own on-screen joystick, drawn in code at the bottom-left corner: a translucent circle with
## four arrows and a round knob. Works with touch (InputEventScreenTouch / ScreenDrag) and, as a
## fallback for the PC, with the mouse. Only one finger (or the mouse) drives it at a time.
##
## DEVIATION from the Story 002 criterion "VirtualJoystick": the Godot 4.7 VirtualJoystick node
## is not documented in docs/engine-reference/, so its API was not guessed. Replace this class
## with the node when its API is verified.
##
## [member value] is the stick as a Vector2 (x east, y south): zero inside the dead zone,
## otherwise a direction whose length goes from 0 to 1 (1 when pushed to the rim).
##
## Story 002 (design/game-brief.md, MVP feature 9).
##
## Usage:
## [codeblock]
## var stick := VirtualStick.new()
## hud.add_child(stick)
## stick.setup(look)
## var move: Vector2 = stick.value
## [/codeblock]

## Current stick value (length 0..1, zero inside the dead zone).
var value: Vector2 = Vector2.ZERO

const _NO_POINTER: int = -1
const _MOUSE_POINTER: int = -2

var _radius: float = 100.0
var _knob_radius: float = 40.0
var _deadzone: float = 0.15
var _ring_width: float = 4.0
var _base_color: Color
var _ring_color: Color
var _arrow_color: Color
var _knob_color: Color
var _knob_ring_color: Color
var _pointer: int = _NO_POINTER
var _knob_offset: Vector2 = Vector2.ZERO


## Reads sizes and colors from [param look] and anchors the stick to the bottom-left corner.
func setup(look: WorldLook) -> void:
	_radius = look.num("joystick", "radius")
	_knob_radius = look.num("joystick", "knob_radius")
	_deadzone = look.num("joystick", "deadzone")
	_ring_width = look.num("joystick", "ring_width")
	_base_color = look.color("joystick", "base_color")
	_ring_color = look.color("joystick", "ring_color")
	_arrow_color = look.color("joystick", "arrow_color")
	_knob_color = look.color("joystick", "knob_color")
	_knob_ring_color = look.color("joystick", "knob_ring_color")
	var margin: float = look.num("joystick", "margin")
	var side: float = (_radius + look.num("joystick", "pad")) * 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = margin
	offset_right = margin + side
	offset_top = -margin - side
	offset_bottom = -margin
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_begin(touch.index, touch.position)
		elif touch.index == _pointer:
			_end()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _pointer:
			_update(drag.position)
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed:
				_begin(_MOUSE_POINTER, click.position)
			elif _pointer == _MOUSE_POINTER:
				_end()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _pointer == _MOUSE_POINTER:
			_update(motion.position)


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, _radius, _base_color)
	draw_arc(center, _radius, 0.0, TAU, 48, _ring_color, _ring_width)
	for k in 4:
		var dir: Vector2 = Vector2.UP.rotated(float(k) * PI * 0.5)
		var tip: Vector2 = center + dir * _radius * 0.82
		var base: Vector2 = center + dir * _radius * 0.66
		var side: Vector2 = dir.rotated(PI * 0.5) * _radius * 0.09
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), _arrow_color)
	var knob: Vector2 = center + _knob_offset
	draw_circle(knob, _knob_radius, _knob_color)
	draw_arc(knob, _knob_radius, 0.0, TAU, 32, _knob_ring_color, _ring_width)


## Starts a drag when a new pointer lands on the stick and none is active.
func _begin(pointer: int, pos: Vector2) -> void:
	if _pointer != _NO_POINTER:
		return
	if (pos - size * 0.5).length() > size.x * 0.5:
		return
	_pointer = pointer
	_update(pos)


func _update(pos: Vector2) -> void:
	var offset: Vector2 = pos - size * 0.5
	var amount: float = minf(offset.length() / _radius, 1.0)
	_knob_offset = offset.limit_length(_radius)
	if amount < _deadzone:
		value = Vector2.ZERO
	else:
		value = offset.normalized() * minf((amount - _deadzone) / (1.0 - _deadzone), 1.0)
	queue_redraw()


func _end() -> void:
	_pointer = _NO_POINTER
	_knob_offset = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()
