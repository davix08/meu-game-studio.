extends Control
## Title screen: start the fight and toggle options. UI is built in code.

const ARENA_SCENE := "res://src/levels/arena_vesper_gate.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var title := Label.new()
	title.text = "ERRANTE DE VESPER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Os semideuses de Vesper caíram. Só restaram seus guardiões."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	box.add_child(subtitle)

	var start := _button("Lutar: Vigia Petrificado")
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file(ARENA_SCENE))
	box.add_child(start)

	var auto_fire := CheckButton.new()
	auto_fire.text = "Tiro automático"
	auto_fire.button_pressed = GameSettings.auto_fire
	auto_fire.add_theme_font_size_override("font_size", 30)
	auto_fire.toggled.connect(func(on: bool) -> void: GameSettings.auto_fire = on)
	box.add_child(auto_fire)

	var touch := CheckButton.new()
	touch.text = "Controles na tela (forçar)"
	touch.button_pressed = GameSettings.force_touch_controls
	touch.add_theme_font_size_override("font_size", 30)
	touch.toggled.connect(func(on: bool) -> void: GameSettings.force_touch_controls = on)
	box.add_child(touch)

	start.grab_focus()


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(520, 96)
	b.add_theme_font_size_override("font_size", 36)
	return b
