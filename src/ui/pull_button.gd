class_name PullButton
extends Control
## The big PUXAR button at the bottom-right, drawn in code: a round button with a rod and a bobber
## (like references/lakebound-3d-look.png). One pointer (a finger or the mouse) at a time.
## [member held] is true while pressed; [method take_press] returns true once per press so the
## fixed-step logic never misses a quick tap. Its [member label] changes with the fishing phase
## (cast / reel in / pull).
##
## Story 003 (design/game-brief.md, MVP feature 10). Sizes and colors: "fishing" group of world_look.json.
##
## Usage:
## [codeblock]
## var pull := PullButton.new()
## hud.add_child(pull)
## pull.setup(look)
## var hold: bool = pull.held
## [/codeblock]

const _NO_POINTER: int = -1
const _MOUSE_POINTER: int = -2

## True while the button is pressed.
var held: bool = false
## Text under the picture.
var label: String = "":
	set(value):
		if value != label:
			label = value
			queue_redraw()

var _radius: float = 84.0
var _pad: float = 6.0
var _color: Color
var _pressed_color: Color
var _ring_color: Color
var _ring_width: float = 4.0
var _rod_color: Color
var _rod_width: float = 5.0
var _line_color: Color
var _bobber_red: Color
var _bobber_white: Color
var _font_size: int = 22
var _text_color: Color
var _pointer: int = _NO_POINTER
var _latched: bool = false


## Reads sizes and colors from [param look] and anchors the button to the bottom-right corner.
func setup(look: WorldLook) -> void:
	_radius = look.num("fishing", "pull_radius")
	_pad = look.num("fishing", "pull_pad")
	_color = look.color("fishing", "pull_color")
	_pressed_color = look.color("fishing", "pull_pressed_color")
	_ring_color = look.color("fishing", "pull_ring_color")
	_ring_width = look.num("fishing", "pull_ring_width")
	_rod_color = look.color("fishing", "pull_rod_color")
	_rod_width = look.num("fishing", "pull_rod_width")
	_line_color = look.color("fishing", "pull_line_color")
	_bobber_red = look.color("fishing", "pull_bobber_red")
	_bobber_white = look.color("fishing", "pull_bobber_white")
	_font_size = int(look.num("fishing", "pull_font"))
	_text_color = look.color("fishing", "pull_text_color")
	var margin: float = look.num("fishing", "pull_margin")
	var side: float = (_radius + _pad) * 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -margin - side
	offset_right = -margin
	offset_top = -margin - side
	offset_bottom = -margin
	queue_redraw()


## True once per press (then false until the next press).
func take_press() -> bool:
	var pressed: bool = _latched
	_latched = false
	return pressed


## Releases the button (call when it gets hidden while pressed).
func reset() -> void:
	held = false
	_latched = false
	_pointer = _NO_POINTER
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and _pointer == _NO_POINTER:
			_press(touch.index)
		elif not touch.pressed and touch.index == _pointer:
			_release()
		accept_event()
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed and _pointer == _NO_POINTER:
				_press(_MOUSE_POINTER)
			elif not click.pressed and _pointer == _MOUSE_POINTER:
				_release()
			accept_event()


func _press(pointer: int) -> void:
	_pointer = pointer
	held = true
	_latched = true
	queue_redraw()


func _release() -> void:
	_pointer = _NO_POINTER
	held = false
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	draw_circle(c, _radius, _pressed_color if held else _color)
	draw_arc(c, _radius, 0.0, TAU, 48, _ring_color, _ring_width, true)
	# Rod from the lower left to the upper right, a line hanging from its tip to a bobber.
	var butt: Vector2 = c + Vector2(-0.5, 0.2) * _radius
	var tip: Vector2 = c + Vector2(0.3, -0.5) * _radius
	var bobber: Vector2 = c + Vector2(0.5, -0.05) * _radius
	draw_line(butt, tip, _rod_color, _rod_width, true)
	draw_line(tip, bobber, _line_color, 1.5, true)
	var r: float = _radius * 0.11
	draw_circle(bobber, r, _bobber_white)
	draw_circle(bobber + Vector2(0.0, -r * 0.3), r * 0.75, _bobber_red)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, c.y + _radius * 0.72), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, _text_color)
