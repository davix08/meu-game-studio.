class_name DiveHud
extends Control
## The dive's on-screen controls (design/gdd/diving.md): the oxygen bar (turns red when
## low), the fish speared so far, the ARPÃO button and the Subir button. Display only:
## it emits [signal shoot_pressed] and [signal surface_pressed]; the main scene acts.
##
## Usage:
## [codeblock]
## hud.setup(look)
## hud.show_dive(dive)   # every frame while diving
## [/codeblock]

## The harpoon button was pressed.
signal shoot_pressed
## The surface button was pressed.
signal surface_pressed

## Air fraction below which the bar turns red and pulses.
const LOW_AIR: float = 0.25

var _look: WorldLook
var _air: float = 1.0
var _clock: float = 0.0
var _count: Label
var _shoot: Button


## Builds the buttons and labels.
func setup(look: WorldLook) -> void:
	_look = look
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count = UiKit.label("", 28, Color(0.95, 0.98, 1.0))
	_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	_count.position = Vector2(24.0, 96.0)
	_count.add_theme_color_override(&"font_outline_color", Color(0.05, 0.1, 0.15))
	_count.add_theme_constant_override(&"outline_size", 8)
	add_child(_count)
	_shoot = UiKit.button(look, Texts.get_text("dive_shoot"), shoot_pressed.emit)
	_shoot.add_theme_font_size_override(&"font_size", 34)
	_shoot.custom_minimum_size = Vector2(220.0, 150.0)
	_shoot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_shoot.position = Vector2(-260.0, -190.0)
	add_child(_shoot)
	var up: Button = UiKit.button(look, Texts.get_text("dive_surface"), surface_pressed.emit)
	up.custom_minimum_size = Vector2(220.0, 0.0)
	up.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	up.position = Vector2(-260.0, -300.0)
	add_child(up)
	visible = false


## Shows [param dive]'s air, haul and harpoon state.
func show_dive(dive: Dive, delta: float) -> void:
	_clock += delta
	_air = dive.oxygen / dive.oxygen_max if dive.oxygen_max > 0.0 else 0.0
	_count.text = Texts.fmt("dive_haul", [dive.haul.size()])
	_shoot.disabled = not dive.can_shoot()
	queue_redraw()


func _draw() -> void:
	var w: float = 520.0
	var h: float = 30.0
	var x: float = (size.x - w) * 0.5
	var y: float = 104.0
	draw_rect(Rect2(x - 4.0, y - 4.0, w + 8.0, h + 8.0), Color(0.05, 0.1, 0.15, 0.85))
	var low: bool = _air < LOW_AIR
	var fill := Color(0.35, 0.8, 1.0)
	if low:
		fill = Color(1.0, 0.35, 0.3).lerp(Color(1.0, 0.7, 0.6), 0.5 + 0.5 * sin(_clock * 8.0))
	draw_rect(Rect2(x, y, w * _air, h), fill)
	var font: Font = get_theme_default_font()
	var text: String = Texts.fmt("dive_air", [ceili(_air * 100.0)])
	draw_string(font, Vector2(x, y - 12.0), text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color.WHITE)
