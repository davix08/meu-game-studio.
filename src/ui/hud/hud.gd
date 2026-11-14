class_name Hud
extends CanvasLayer
## In-fight HUD: hit points, super meter cards, announcer text, pause button,
## pause menu and defeat menu. Listens to [EventBus]; never reads gameplay nodes.

## Player chose "try again" in a menu.
signal retry_pressed
## Player chose "back to title" in a menu.
signal quit_pressed

@onready var touch_controls: TouchControls = $TouchControls

var _hp_label: Label
var _meter: MeterCards
var _announcer: Label
var _pause_button: Button
var _menu_root: CenterContainer
var _menu_box: VBoxContainer


## Draws the super meter as a row of cards that fill up.
class MeterCards:
	extends Control
	var cards: float = 0.0
	var max_cards: int = 5

	func _draw() -> void:
		var w := 22.0
		var h := 32.0
		for i: int in max_cards:
			var r := Rect2(i * (w + 6.0), 0.0, w, h)
			draw_rect(r, Color(1, 1, 1, 0.18))
			var fill := clampf(cards - float(i), 0.0, 1.0)
			if fill > 0.0:
				var col := Color(0.55, 0.8, 1.0) if fill < 1.0 else Color(1.0, 0.95, 0.7)
				draw_rect(Rect2(r.position.x, r.position.y + h * (1.0 - fill), w, h * fill), col)
			draw_rect(r, Color(1, 1, 1, 0.6), false, 2.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_status()
	_build_announcer()
	_build_pause_button()
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.super_meter_changed.connect(_on_meter_changed)


func _build_status() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(24, 20)
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 30)
	_hp_label.text = "VIDA 3"
	box.add_child(_hp_label)
	_meter = MeterCards.new()
	_meter.custom_minimum_size = Vector2(5 * 28.0, 32.0)
	box.add_child(_meter)


func _build_announcer() -> void:
	_announcer = Label.new()
	_announcer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_announcer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_announcer.add_theme_font_size_override("font_size", 96)
	_announcer.add_theme_color_override("font_outline_color", Color.BLACK)
	_announcer.add_theme_constant_override("outline_size", 12)
	_announcer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_announcer)


func _build_pause_button() -> void:
	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(96, 96)
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -120.0
	_pause_button.offset_top = 16.0
	_pause_button.offset_right = -24.0
	_pause_button.offset_bottom = 112.0
	_pause_button.add_theme_font_size_override("font_size", 36)
	_pause_button.pressed.connect(func() -> void: EventBus.pause_requested.emit())
	add_child(_pause_button)


## Shows big centered text ("" hides it).
func announce(text: String) -> void:
	_announcer.text = text


## Pause menu: continue, retry, quit.
func show_pause_menu() -> void:
	_open_menu("PAUSADO")
	_add_menu_button("Continuar", _resume)
	_add_menu_button("Tentar de novo", func() -> void: retry_pressed.emit())
	_add_menu_button("Menu inicial", func() -> void: quit_pressed.emit())


## Defeat menu with how far the player got through the boss.
func show_defeat_menu(progress: float, boss_name: String) -> void:
	_open_menu("Derrotado por %s" % boss_name)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = progress
	bar.show_percentage = true
	bar.custom_minimum_size = Vector2(420, 32)
	_menu_box.add_child(bar)
	_add_menu_button("Tentar de novo", func() -> void: retry_pressed.emit())
	_add_menu_button("Menu inicial", func() -> void: quit_pressed.emit())


func _open_menu(title: String) -> void:
	_close_menu()
	touch_controls.set_enabled(false)
	_pause_button.visible = false
	_menu_root = CenterContainer.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	_menu_root.add_child(panel)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 16)
	panel.add_child(_menu_box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	_menu_box.add_child(label)
	add_child(_menu_root)


func _add_menu_button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 88)
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(action)
	_menu_box.add_child(b)
	if _menu_box.get_child_count() == 2:
		b.grab_focus()


func _close_menu() -> void:
	if _menu_root != null:
		_menu_root.queue_free()
		_menu_root = null
	touch_controls.set_enabled(true)
	_pause_button.visible = true


func _resume() -> void:
	_close_menu()
	get_tree().paused = false


func _on_health_changed(current: int, _maximum: int) -> void:
	_hp_label.text = "VIDA %d" % current
	_hp_label.modulate = Color(1, 0.5, 0.5) if current <= 1 else Color.WHITE


func _on_meter_changed(cards: float, max_cards: int) -> void:
	_meter.cards = cards
	_meter.max_cards = max_cards
	_meter.queue_redraw()
