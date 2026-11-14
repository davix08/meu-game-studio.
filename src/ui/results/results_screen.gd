extends Control
## Results after a victory: time, health, parries and a grade.

const ARENA_SCENE := "res://src/levels/arena_vesper_gate.tscn"
const TITLE_SCENE := "res://src/ui/title/title_screen.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var r: Dictionary = GameSettings.last_result
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var time: float = r.get("time", 0.0)
	var health: int = r.get("health", 0)
	var max_health: int = r.get("max_health", 3)
	var parries: int = r.get("parries", 0)
	var cards: int = r.get("super_cards", 0)
	var grade := ResultsGrade.letter(ResultsGrade.score(time, health, max_health, parries, cards))

	_add_label(box, "%s DERROTADO" % String(r.get("boss", "Chefe")).to_upper(), 54, Color(0.95, 0.85, 0.55))
	_add_label(box, "Tempo: %d:%02d" % [int(time) / 60, int(time) % 60], 32)
	_add_label(box, "Vida: %d / %d" % [health, max_health], 32)
	_add_label(box, "Parries: %d" % parries, 32)
	_add_label(box, "Cartas de super: %d" % cards, 32)
	_add_label(box, "NOTA: %s" % grade, 64, Color(1, 0.95, 0.7))

	var again := Button.new()
	again.text = "Lutar de novo"
	again.custom_minimum_size = Vector2(420, 88)
	again.add_theme_font_size_override("font_size", 32)
	again.pressed.connect(func() -> void: get_tree().change_scene_to_file(ARENA_SCENE))
	box.add_child(again)
	var menu := Button.new()
	menu.text = "Menu inicial"
	menu.custom_minimum_size = Vector2(420, 88)
	menu.add_theme_font_size_override("font_size", 32)
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))
	box.add_child(menu)
	again.grab_focus()


func _add_label(parent: Node, text: String, font_size: int, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
