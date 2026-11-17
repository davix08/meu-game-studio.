class_name GearIcon
extends Control
## A gear drawn in code (the settings button of Story 006), so it does not depend on a font glyph.
##
## Usage:
## [codeblock]
## var icon := GearIcon.new()
## button.add_child(icon)
## [/codeblock]

## Fill color of the gear.
var color: Color = Color.WHITE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.3
	var pts := PackedVector2Array()
	for i in 32:
		var a: float = TAU * float(i) / 32.0
		var tooth: bool = (i / 2) % 2 == 0
		pts.append(c + Vector2(cos(a), sin(a)) * (r * 1.25 if tooth else r))
	draw_colored_polygon(pts, color)
	draw_circle(c, r * 0.45, Color(0.16, 0.11, 0.08))
