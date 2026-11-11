class_name Hud
extends CanvasLayer
## Minimal HUD for the 3D skeleton: the region name at the top-left and an FPS counter at the
## top-right. The full HUD (level, coins, energy, clock, buttons) comes in later stories.
## Text sizes are in base-resolution pixels (1280x720, canvas_items stretch).
##
## Story 002 (design/game-brief.md, MVP feature 9).
##
## Usage:
## [codeblock]
## var hud := Hud.new()
## add_child(hud)
## hud.setup(look)
## [/codeblock]

var _fps_label: Label
var _refresh: float = 0.5
var _elapsed: float = 0.0


## Builds the labels from [param look].
func setup(look: WorldLook) -> void:
	_refresh = look.num("hud", "fps_refresh_seconds")
	var region: Label = _make_pill(look, look.text("hud", "region_name"), look.integer("hud", "region_font_size"))
	region.get_parent().set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, look.integer("hud", "margin"))
	_fps_label = _make_pill(look, "FPS 0", look.integer("hud", "fps_font_size"))
	var fps_panel: Control = _fps_label.get_parent()
	fps_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, look.integer("hud", "margin"))
	fps_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _refresh and _fps_label != null:
		_elapsed = 0.0
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()


## A rounded translucent panel holding one label; returns the label (its parent is the panel).
func _make_pill(look: WorldLook, text: String, font_size: int) -> Label:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = look.color("hud", "panel_color")
	style.set_corner_radius_all(look.integer("hud", "corner_radius"))
	style.set_content_margin_all(float(look.integer("hud", "padding")))
	panel.add_theme_stylebox_override(&"panel", style)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", look.color("hud", "text_color"))
	panel.add_child(label)
	add_child(panel)
	return label
