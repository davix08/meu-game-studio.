class_name IconButton
extends Button
## A square cream button with a brown border and a drawn icon, like the owner's bottom-bar
## picture (2026-11-22): shop, book, bag and rod. A small name sits under the icon. Colors:
## "ui.bar_*" in world_look.json.
##
## Usage:
## [codeblock]
## var b := IconButton.new()
## b.setup(look, IconButton.Icon.SHOP, "Loja")
## [/codeblock]

enum Icon { SHOP, BOOK, BAG, ROD }

var icon_kind: Icon = Icon.SHOP
## Draws the rod icon crossed out (rod put away).
var off: bool = false
var _look: WorldLook
var _label: String = ""


## Sets the look, the icon and the small name.
func setup(look: WorldLook, kind: Icon, label_text: String) -> void:
	_look = look
	icon_kind = kind
	_label = label_text
	focus_mode = Control.FOCUS_NONE
	var size_px: float = look.num("ui", "bar_button")
	custom_minimum_size = Vector2(size_px, size_px)
	for st: String in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = UiKit.flat(look.color("ui", "bar_fill") if st != "pressed" else look.color("ui", "bar_fill").darkened(0.12), int(look.num("ui", "bar_radius")))
		style.set_border_width_all(4)
		style.border_color = look.color("ui", "bar_border")
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
		add_theme_stylebox_override(StringName(st), style)


## Changes the name under the icon.
func set_label(text_value: String) -> void:
	_label = text_value
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	var s: float = size.x / 76.0
	var brown: Color = _look.color("ui", "bar_border")
	match icon_kind:
		Icon.SHOP:
			# Little shop: wall, door, striped awning.
			draw_rect(Rect2(c + Vector2(-17, -2) * s, Vector2(34, 20) * s), Color("#e9c48a"))
			draw_rect(Rect2(c + Vector2(-5, 4) * s, Vector2(10, 14) * s), brown)
			for k in 5:
				var col: Color = Color("#d84a3a") if k % 2 == 0 else Color("#fff4e0")
				draw_colored_polygon(PackedVector2Array([c + Vector2(-20 + k * 8, -14) * s, c + Vector2(-12 + k * 8, -14) * s, c + Vector2(-12 + k * 8, -3) * s, c + Vector2(-20 + k * 8, -3) * s]), col)
			draw_rect(Rect2(c + Vector2(-20, -17) * s, Vector2(40, 4) * s), brown)
		Icon.BOOK:
			draw_rect(Rect2(c + Vector2(-18, -15) * s, Vector2(36, 30) * s), Color("#8a4a2a"))
			draw_rect(Rect2(c + Vector2(-15, -12) * s, Vector2(14, 24) * s), Color("#fff4e0"))
			draw_rect(Rect2(c + Vector2(1, -12) * s, Vector2(14, 24) * s), Color("#fff4e0"))
			for k in 3:
				draw_line(c + Vector2(-12, -6 + k * 6) * s, c + Vector2(-4, -6 + k * 6) * s, Color("#b89a7a"), 2.0 * s)
				draw_line(c + Vector2(4, -6 + k * 6) * s, c + Vector2(12, -6 + k * 6) * s, Color("#b89a7a"), 2.0 * s)
			draw_circle(c + Vector2(8, 6) * s, 4.0 * s, Color("#4aa0d8"))
		Icon.BAG:
			draw_arc(c + Vector2(0, -8) * s, 8.0 * s, PI, TAU, 10, brown, 3.0 * s)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -8) * s, c + Vector2(16, -8) * s, c + Vector2(19, 16) * s, c + Vector2(-19, 16) * s]), Color("#c8843a"))
			draw_rect(Rect2(c + Vector2(-10, 0) * s, Vector2(20, 9) * s), Color("#a86a2a"))
			draw_circle(c + Vector2(0, 4) * s, 2.5 * s, Color("#f0d060"))
		Icon.ROD:
			draw_line(c + Vector2(-16, 16) * s, c + Vector2(14, -16) * s, Color("#8a5a32"), 4.0 * s)
			draw_line(c + Vector2(14, -16) * s, c + Vector2(16, 6) * s, Color("#555555"), 1.5 * s)
			draw_circle(c + Vector2(16, 8) * s, 4.5 * s, Color("#e04a3a"))
			draw_circle(c + Vector2(-10, 10) * s, 4.0 * s, Color("#555555"))
			if off:
				draw_line(c + Vector2(-18, -18) * s, c + Vector2(18, 18) * s, Color("#c0392b"), 4.0 * s)
	if _label != "":
		var font: Font = ThemeDB.fallback_font
		var fs: int = int(_look.num("ui", "bar_label_size"))
		draw_string(font, Vector2(0, size.y - 7.0 * s), _label, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, brown)
