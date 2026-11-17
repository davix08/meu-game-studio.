class_name UiKit
extends RefCounted
## Shared look of the interface (Stories 006 and 007): a [Theme] in the warm cream-and-wood style
## of the reference (rounded panels, green buttons, big touch targets) plus small builders for
## labels, buttons and rows. Sizes and colors come from the "ui" group of world_look.json.
##
## Usage:
## [codeblock]
## root.theme = UiKit.make_theme(look)
## var button: Button = UiKit.button(look, "Comprar", func() -> void: buy())
## [/codeblock]


## The theme for every screen and button.
static func make_theme(look: WorldLook) -> Theme:
	var theme := Theme.new()
	theme.default_font_size = look.integer("ui", "font_size")
	theme.set_stylebox(&"panel", &"PanelContainer", panel_style(look))
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var key: String = {"normal": "button_fill", "hover": "button_hover", "pressed": "button_pressed", "disabled": "button_disabled", "focus": "button_hover"}[state]
		var box := StyleBoxFlat.new()
		box.bg_color = look.color("ui", key)
		box.set_corner_radius_all(look.integer("ui", "corner_radius") - 6)
		box.set_border_width_all(2)
		box.border_color = look.color("ui", "button_border")
		box.set_content_margin_all(10.0)
		if state == "focus":
			box.draw_center = false
		theme.set_stylebox(StringName(state), &"Button", box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(StringName(color_name), &"Button", look.color("ui", "button_text"))
	theme.set_color(&"font_disabled_color", &"Button", look.color("ui", "panel_fill"))
	theme.set_color(&"font_color", &"Label", look.color("ui", "ink"))
	return theme


## The panel box of the screens.
static func panel_style(look: WorldLook) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = look.color("ui", "panel_fill")
	box.border_color = look.color("ui", "panel_border")
	box.set_border_width_all(look.integer("ui", "panel_border_width"))
	box.set_corner_radius_all(look.integer("ui", "corner_radius"))
	box.set_content_margin_all(float(look.integer("ui", "pad")))
	return box


## A flat colored box (rows, tabs, pills).
static func flat(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(8.0)
	return box


## A label of [param size] (0 = theme default) and optional [param color].
static func label(text: String, size: int = 0, color: Color = Color.TRANSPARENT) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if size > 0:
		l.add_theme_font_size_override(&"font_size", size)
	if color.a > 0.0:
		l.add_theme_color_override(&"font_color", color)
	return l


## A button that calls [param action]; [param enabled] false greys it out.
static func button(look: WorldLook, text: String, action: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0.0, look.num("ui", "button_height"))
	b.disabled = not enabled
	b.pressed.connect(action)
	return b


## A row panel holding [param children] side by side; the first child expands.
static func row(look: WorldLook, children: Array, alt: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", flat(look.color("ui", "row_alt" if alt else "row_fill"), 10))
	panel.custom_minimum_size = Vector2(0.0, look.num("ui", "row_height"))
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	panel.add_child(box)
	# Text takes the free width; icons, faces and buttons keep their size.
	var has_label: bool = false
	for child: Variant in children:
		has_label = has_label or child is Label
	for i in children.size():
		var c: Control = children[i]
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if c is Label or (not has_label and i == 0):
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(c)
	return panel
