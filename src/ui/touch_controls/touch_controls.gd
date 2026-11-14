class_name TouchControls
extends Control
## On-screen controls for phones: a floating joystick on the left half and
## action buttons on the right. Multi-touch; drives the normal input actions
## through Input.action_press(), so gameplay code never knows about touch.
##
## Godot 4.7 also ships a VirtualJoystick node; this custom version is kept so
## the joystick snaps to 8 directions (needed for 8-way aim) and so it can be
## tested without the editor.

const InputActions := preload("res://src/autoload/input_actions.gd")

## Joystick base radius in pixels (base resolution 1280x720).
@export var stick_radius: float = 110.0
## Fraction of stick_radius under which the stick is neutral.
@export var stick_deadzone: float = 0.25
## Fraction of the screen width, from the left, that starts the joystick.
@export var stick_zone_width: float = 0.45
@export var button_radius: float = 62.0
@export var opacity: float = 0.45


class TouchButton:
	var action: StringName
	var label: String
	var center: Vector2
	var radius: float
	var touch_index: int = -1
	## Hidden buttons ignore touches (e.g. SHOOT while auto-fire is on).
	var visible: bool = true

	func _init(p_action: StringName, p_label: String) -> void:
		action = p_action
		label = p_label


var _buttons: Array[TouchButton] = []
var _stick_index: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_vector: Vector2 = Vector2.ZERO
var _pressed_dirs: Dictionary = {}
var _enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_buttons = [
		TouchButton.new(InputActions.JUMP, "PULO"),
		TouchButton.new(InputActions.DASH, "DASH"),
		TouchButton.new(InputActions.SPECIAL, "EX"),
		TouchButton.new(InputActions.LOCK_AIM, "MIRA"),
		TouchButton.new(InputActions.SHOOT, "TIRO"),
	]
	visible = GameSettings.wants_touch_controls()
	get_viewport().size_changed.connect(_layout)
	_layout()


## Enables or disables the controls, releasing everything held.
func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_release_all()


func _layout() -> void:
	var size_px: Vector2 = get_viewport_rect().size
	var r := button_radius
	var right := size_px.x - r - 40.0
	var bottom := size_px.y - r - 40.0
	var spacing := r * 2.0 + 24.0
	_buttons[0].center = Vector2(right, bottom)                      # PULO
	_buttons[1].center = Vector2(right - spacing, bottom + 10.0)     # DASH
	_buttons[2].center = Vector2(right, bottom - spacing)            # EX
	_buttons[3].center = Vector2(right - spacing, bottom - spacing + 20.0)  # MIRA
	_buttons[4].center = Vector2(right - spacing * 2.0, bottom + 10.0)      # TIRO
	for b: TouchButton in _buttons:
		b.radius = r * (1.2 if b.action == InputActions.JUMP else 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	_buttons[4].visible = not GameSettings.auto_fire


func _input(event: InputEvent) -> void:
	if not visible or not _enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_touch_down(touch.index, touch.position)
		else:
			_on_touch_up(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _stick_index:
			_update_stick(drag.position)


func _on_touch_down(index: int, pos: Vector2) -> void:
	for b: TouchButton in _buttons:
		if b.visible and b.touch_index == -1 and pos.distance_to(b.center) <= b.radius * 1.15:
			b.touch_index = index
			Input.action_press(b.action)
			queue_redraw()
			return
	if _stick_index == -1 and pos.x <= get_viewport_rect().size.x * stick_zone_width:
		_stick_index = index
		_stick_origin = pos
		_update_stick(pos)


func _on_touch_up(index: int) -> void:
	if index == _stick_index:
		_stick_index = -1
		_stick_vector = Vector2.ZERO
		_apply_directions(Vector2.ZERO)
		queue_redraw()
		return
	for b: TouchButton in _buttons:
		if b.touch_index == index:
			b.touch_index = -1
			Input.action_release(b.action)
			queue_redraw()


func _update_stick(pos: Vector2) -> void:
	var offset := pos - _stick_origin
	if offset.length() > stick_radius:
		# Drag the base along so the stick never feels stuck at the edge.
		_stick_origin = pos - offset.limit_length(stick_radius)
		offset = pos - _stick_origin
	_stick_vector = offset / stick_radius
	_apply_directions(snap_to_8_directions(_stick_vector, stick_deadzone))
	queue_redraw()


## Snaps a stick vector (length 0..1) to one of 8 unit directions, or zero
## inside the deadzone. Pure function, used by tests.
static func snap_to_8_directions(v: Vector2, deadzone: float) -> Vector2:
	if v.length() < deadzone:
		return Vector2.ZERO
	var angle: float = snappedf(v.angle(), PI / 4.0)
	var d := Vector2.from_angle(angle)
	return Vector2(roundf(d.x), roundf(d.y))


func _apply_directions(dir: Vector2) -> void:
	_set_action(InputActions.MOVE_LEFT, dir.x < 0.0)
	_set_action(InputActions.MOVE_RIGHT, dir.x > 0.0)
	_set_action(InputActions.MOVE_UP, dir.y < 0.0)
	_set_action(InputActions.MOVE_DOWN, dir.y > 0.0)


func _set_action(action: StringName, pressed: bool) -> void:
	var was: bool = _pressed_dirs.get(action, false)
	if pressed == was:
		return
	_pressed_dirs[action] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_all() -> void:
	_stick_index = -1
	_stick_vector = Vector2.ZERO
	_apply_directions(Vector2.ZERO)
	for b: TouchButton in _buttons:
		if b.touch_index != -1:
			b.touch_index = -1
			Input.action_release(b.action)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var base := Color(1, 1, 1, opacity * 0.5)
	var knob := Color(1, 1, 1, opacity)
	if _stick_index != -1:
		draw_circle(_stick_origin, stick_radius, base)
		draw_circle(_stick_origin + _stick_vector * stick_radius, stick_radius * 0.45, knob)
	else:
		# Hint where the joystick lives.
		var hint := Vector2(stick_radius + 60.0, get_viewport_rect().size.y - stick_radius - 60.0)
		draw_arc(hint, stick_radius, 0.0, TAU, 48, base, 3.0)
	for b: TouchButton in _buttons:
		if not b.visible:
			continue
		var held := b.touch_index != -1
		draw_circle(b.center, b.radius, Color(1, 1, 1, opacity * (0.9 if held else 0.35)))
		draw_arc(b.center, b.radius, 0.0, TAU, 40, Color(1, 1, 1, opacity), 3.0)
		draw_string(font, b.center + Vector2(-b.radius, 9.0), b.label,
				HORIZONTAL_ALIGNMENT_CENTER, b.radius * 2.0, 26, Color(1, 1, 1, 0.9))
