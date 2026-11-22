class_name ActionBar
extends Control
## The HUD buttons (Story 006): since 2026-11-22 a bottom bar of square icon buttons (Loja,
## Livro, Mochila, Vara) centered between the joystick and the big fishing button, plus the context button that appears near a building, a plot, an
## animal home or a neighbor ("Plantar", "Armazém", "Falar: Dona Ana"...). It only emits signals.
##
## Usage:
## [codeblock]
## var bar := ActionBar.new()
## hud.add_child(bar)
## bar.setup(look)
## bar.bag_pressed.connect(open_bag)
## bar.show_context("Plantar")
## [/codeblock]

signal bag_pressed
signal rest_pressed
signal book_pressed
signal shop_pressed
## The rod button was tapped (put the rod away or take it out).
signal rod_pressed
## The context button was tapped.
signal context_pressed

var _look: WorldLook
var _rest: Button
var _rod_icon: IconButton
var _context: Button


## Creates the buttons at the bottom-right corner.
func setup(look: WorldLook) -> void:
	_look = look
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m: float = look.num("fishing", "pull_margin")
	var pull: float = (look.num("fishing", "pull_radius") + look.num("fishing", "pull_pad")) * 2.0
	var d: float = look.num("ui", "round_button") * 2.0
	var gap: float = look.num("ui", "action_gap")
	_rest = _round(Texts.get_text("btn_rest"), Vector2(m + pull + gap + d, m + d * 2.0 + gap), rest_pressed)
	# Resting moved into the house (sofa and bed, 2026-11-22): the rod button takes its place.
	_rest.visible = false
	# The bottom bar of square icon buttons (2026-11-22, the owner's picture): shop, book, bag,
	# rod, centered at the bottom between the joystick and the big fishing button.
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", int(look.num("ui", "bar_gap")))
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -look.num("ui", "bar_margin")
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bar)
	_bar_button(bar, IconButton.Icon.SHOP, Texts.get_text("btn_shop"), shop_pressed)
	_bar_button(bar, IconButton.Icon.BOOK, Texts.get_text("btn_book"), book_pressed)
	_bar_button(bar, IconButton.Icon.BAG, Texts.get_text("btn_bag"), bag_pressed)
	_rod_icon = _bar_button(bar, IconButton.Icon.ROD, Texts.get_text("btn_rod_stow"), rod_pressed)
	_context = Button.new()
	_context.focus_mode = Control.FOCUS_NONE
	_context.add_theme_font_size_override(&"font_size", 24)
	var style: StyleBoxFlat = UiKit.flat(look.color("ui", "context_fill"), int(look.num("ui", "context_height") * 0.5))
	style.set_border_width_all(3)
	style.border_color = Color.WHITE
	for state: String in ["normal", "hover", "pressed"]:
		_context.add_theme_stylebox_override(StringName(state), style)
	var cw: float = look.num("ui", "context_width")
	var ch: float = look.num("ui", "context_height")
	_place(_context, Vector2(m + cw, m + pull + gap * 2.0 + d + ch), Vector2(cw, ch))
	_context.pressed.connect(context_pressed.emit)
	_context.visible = false
	add_child(_context)


## Shows the rest button as "Parar" while resting.
func set_resting(on: bool) -> void:
	_rest.text = Texts.get_text("btn_rest_stop") if on else Texts.get_text("btn_rest")


## Shows the rod button as "Guardar" while the rod is in the hand, "Pegar vara" otherwise.
func set_rod(out: bool) -> void:
	_rod_icon.set_label(Texts.get_text("btn_rod_stow") if out else Texts.get_text("btn_rod_take"))
	_rod_icon.off = not out
	_rod_icon.queue_redraw()


func _bar_button(bar: HBoxContainer, kind: IconButton.Icon, label_text: String, signal_to_emit: Signal) -> IconButton:
	var b := IconButton.new()
	b.setup(_look, kind, label_text)
	b.pressed.connect(signal_to_emit.emit)
	bar.add_child(b)
	return b


## Shows the context button with [param text], or hides it when [param text] is empty.
func show_context(text: String) -> void:
	_context.visible = text != ""
	_context.text = text


func _round(text: String, from_corner: Vector2, signal_to_emit: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override(&"font_size", 15)
	var r: int = int(_look.num("ui", "round_button"))
	for state: String in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = UiKit.flat(_look.color("ui", "pill_fill") if state != "pressed" else _look.color("ui", "button_pressed"), r)
		style.set_border_width_all(3)
		style.border_color = _look.color("ui", "pill_text")
		b.add_theme_stylebox_override(StringName(state), style)
	b.add_theme_color_override(&"font_color", _look.color("ui", "pill_text"))
	_place(b, from_corner, Vector2(r * 2, r * 2))
	b.pressed.connect(signal_to_emit.emit)
	add_child(b)
	return b


## Anchors [param control] to the bottom-right corner; [param from_corner] is the distance of its
## top-left corner from the bottom-right corner of the screen.
func _place(control: Control, from_corner: Vector2, control_size: Vector2) -> void:
	control.anchor_left = 1.0
	control.anchor_right = 1.0
	control.anchor_top = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = -from_corner.x
	control.offset_top = -from_corner.y
	control.offset_right = -from_corner.x + control_size.x
	control.offset_bottom = -from_corner.y + control_size.y
