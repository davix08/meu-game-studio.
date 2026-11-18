class_name FishingHud
extends Control
## Fishing interface drawn over the 3D view (a full-screen Control inside the Hud CanvasLayer):
## the bite banner, the fight bars (progress, green zone, indicator, mood, TRANCO!), short toasts,
## the capture card (new species, new record, name, rarity, weight, value; closes on tap) and the
## big PUXAR button ([PullButton]). Story 006 moved energy, bag and Rest to [TopBar] and
## [ActionBar]. It only displays and emits signals: it never changes game state.
##
## Reads the [FishingMachine] public fields and [GameState]; all texts come from texts_pt.json;
## sizes, colors and positions from the "fishing" group of world_look.json (1280x720 base).
##
## Story 003 (design/game-brief.md, MVP feature 10).
##
## Usage:
## [codeblock]
## var fishing_hud := FishingHud.new()
## hud.add_child(fishing_hud)
## fishing_hud.setup(look, data, state)
## fishing_hud.bind(machine)
## [/codeblock]


## Where the Portuguese texts live.
const TEXTS_PATH: String = "res://src/data/texts_pt.json"

## The PUXAR button.
var pull: PullButton
## True while the capture card is on screen.
var card_open: bool = false

var _look: WorldLook
var _data: GameData
var _state: GameState
var _machine: FishingMachine
var _texts: Dictionary = {}
var _style: StyleBoxFlat
var _catcher: Control
var _clock: float = 0.0
var _toast_text: String = ""
var _toast_left: float = 0.0
var _tranco_left: float = 0.0
var _prev_zone: float = 0.0
var _card_time: float = 0.0
var _card_fish: GameState.Catch
var _card_new: bool = false
var _card_record: bool = false
var _card_armed: bool = false
var _restore_frame: int = 0


## Builds the button, the Rest button and the card catcher; loads the texts.
func setup(look: WorldLook, data: GameData, state: GameState) -> void:
	_look = look
	_data = data
	_state = state
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	_texts = parsed
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(look.integer("hud", "corner_radius"))
	_style.set_border_width_all(int(_n("ui_panel_border")))
	pull = PullButton.new()
	add_child(pull)
	pull.setup(look)
	_catcher = Control.new()
	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.visible = false
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)


## Connects to the machine (read for drawing) and to the signals that raise toasts and the card.
func bind(machine: FishingMachine) -> void:
	_machine = machine
	machine.fishing_ended.connect(_on_fishing_ended)
	_state.fish_caught.connect(_on_fish_caught)
	_state.level_up.connect(_on_level_up)


## Shows a short message: [param key] is a key of texts_pt.json.
func show_toast(key: String) -> void:
	_toast_text = _t(key)
	_toast_left = _n("toast_seconds")


## Call after every fixed [method FishingMachine.step] while fighting: detects the green zone
## darting (it moves much faster than its wander speed) to flash TRANCO!.
func on_fight_step(dt: float) -> void:
	if _machine.phase_time > dt:
		var base: float = _data.tune("zone_speed") + _data.tune("zone_speed_hard") * _machine.species.difficulty
		var speed: float = absf(_machine.zone_center - _prev_zone) / dt
		if speed > base * (1.0 + _data.fixed("dart_speed_mult")) * 0.5:
			_tranco_left = _data.fixed("dart_time")
	_prev_zone = _machine.zone_center


func _process(delta: float) -> void:
	if _machine == null:
		return
	_clock += delta
	if _restore_frame > 0 and Engine.get_process_frames() >= _restore_frame:
		_restore_frame = 0
		pull.reset()
		pull.visible = true
	_toast_left = maxf(0.0, _toast_left - delta)
	_tranco_left = maxf(0.0, _tranco_left - delta)
	if card_open:
		_card_time += delta
	match _machine.phase:
		FishingMachine.Phase.IDLE:
			pull.label = _t("pull_cast")
		FishingMachine.Phase.CAST, FishingMachine.Phase.WAIT:
			pull.label = _t("pull_reel")
		FishingMachine.Phase.BITE:
			pull.label = _t("pull_bite")
		_:
			pull.label = _t("pull_fight")
	queue_redraw()


func _draw() -> void:
	if _machine == null:
		return
	var cx: float = size.x * 0.5
	_draw_mini()
	match _machine.phase:
		FishingMachine.Phase.BITE:
			_draw_bite(cx)
		FishingMachine.Phase.WAIT:
			_text(cx, _n("hint_y"), _t("wait_hint"), int(_n("hint_font")), _c("ui_cream"))
		FishingMachine.Phase.FIGHT, FishingMachine.Phase.CAUGHT:
			_draw_fight(cx)
		FishingMachine.Phase.IDLE:
			if _state.stats_caught == 0 and not card_open:
				var key: String = "hint_no_energy" if _state.energy < _data.tune("cast_cost") else "hint_start"
				if not _state.has_rod():
					key = "hint_no_rod"
				_text(cx, _n("hint_y"), _t(key), int(_n("hint_font")), _c("ui_cream"))
	if card_open:
		_draw_card()
	if _toast_left > 0.0:
		var w: float = _n("toast_width")
		var h: float = _n("toast_height")
		_panel(Rect2(cx - w * 0.5, _n("toast_y") - h * 0.5, w, h), _c("toast_fill"), Color(0, 0, 0, 0))
		_text(cx, _n("toast_y") + _n("toast_font") * _n("text_baseline"), _toast_text, int(_n("toast_font")), _c("ui_white"))


## The bag and book counters under the top bar (the energy bar moved to [TopBar], Story 006).
func _draw_mini() -> void:
	var bag_line: String = _t("bag_book") % [_state.bag.size(), int(_data.tune("bag_size")), _state.discovered(), _data.species.size()]
	_text(_n("mini_x"), _n("mini_y") + _n("mini_bag_gap"), bag_line, int(_n("mini_bag_font")), _c("ui_cream"), HORIZONTAL_ALIGNMENT_LEFT)


func _draw_bite(cx: float) -> void:
	var pulse: float = 1.0 + sin(_clock * _n("bite_pulse_freq")) * _n("bite_pulse")
	var w: float = _n("bite_width")
	var h: float = _n("bite_height")
	draw_set_transform(Vector2(cx, _n("bite_y")), 0.0, Vector2(pulse, pulse))
	_panel(Rect2(-w * 0.5, -h * 0.5, w, h), _c("bite_fill"), _c("bite_border"))
	_text(0.0, _n("bite_font") * _n("text_baseline"), _t("bite_banner"), int(_n("bite_font")), _c("ui_white"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fight(cx: float) -> void:
	var caught: bool = _machine.phase == FishingMachine.Phase.CAUGHT
	var w: float = _n("bar_width")
	var h: float = _n("bar_height")
	var x: float = cx - w * 0.5
	var y: float = _n("bar_top")
	var pad: float = _n("panel_pad")
	var rarity_color: Color = Color.html(_data.rarity_colors[_machine.species.rarity])
	_panel(Rect2(x - pad, y - _n("panel_above"), w + pad * 2.0, _n("panel_height")), _c("ui_panel_fill"), Color(0, 0, 0, 0))
	var title: String = _t("caught") if caught else _t("fight_hint")
	_text(cx, y - _n("title_above"), title, int(_n("title_font")), rarity_color if caught else _c("ui_cream"))
	# Progress bar.
	var ph: float = _n("progress_height")
	var py: float = y - _n("progress_above")
	var progress: float = 1.0 if caught else maxf(0.0, _machine.progress)
	draw_rect(Rect2(x, py, w, ph), _c("ui_ink"))
	var fill: Color = _c("progress_low")
	if progress > _n("progress_high_from"):
		fill = _c("progress_high")
	elif progress > _n("progress_mid_from"):
		fill = _c("progress_mid")
	draw_rect(Rect2(x + 2.0, py + 2.0, (w - 4.0) * progress, ph - 4.0), fill)
	_text(cx, py + ph - 4.0, "%d%%" % int(progress * 100.0), int(_n("progress_font")), _c("ui_white"))
	# Bar with the green zone.
	var border: float = _n("bar_border")
	draw_rect(Rect2(x - border, y - border, w + border * 2.0, h + border * 2.0), _c("ui_ink"))
	draw_rect(Rect2(x, y, w, h), _c("bar_bg"))
	var zone_x: float = x + (_machine.zone_center - _machine.zone_width * 0.5) * w
	var zone_w: float = _machine.zone_width * w
	draw_rect(Rect2(zone_x, y + border, zone_w, h - border * 2.0), _c("zone_in_color") if _machine.in_zone else _c("zone_color"))
	draw_rect(Rect2(zone_x, y + border, zone_w, _n("zone_highlight_height")), _c("zone_highlight"))
	# Indicator: a hook marker.
	var ix: float = x + _machine.indicator * w
	var iw: float = _n("ind_width")
	var over: float = _n("ind_over")
	var ib: float = _n("ind_border")
	var cap_w: float = _n("ind_cap_width")
	var cap_h: float = _n("ind_cap_height")
	draw_rect(Rect2(ix - iw * 0.5 - ib, y - over - ib, iw + ib * 2.0, h + over * 2.0 + ib * 2.0), _c("ui_ink"))
	draw_rect(Rect2(ix - iw * 0.5, y - over, iw, h + over * 2.0), _c("ind_color") if _machine.in_zone else _c("ind_out_color"))
	draw_rect(Rect2(ix - cap_w * 0.5 - ib, y - over - cap_h - ib, cap_w + ib * 2.0, cap_h + ib), _c("ui_ink"))
	draw_rect(Rect2(ix - cap_w * 0.5, y - over - cap_h, cap_w, cap_h - ib), _c("ind_cap_color"))
	if not caught:
		var moods: Array = _texts["mood"]
		var mood: String = _t("mood_fmt") % str(moods[_machine.species.rarity])
		var mood_color: Color = rarity_color
		if _machine.overweight:
			mood = _t("line_heavy")
			mood_color = _c("tranco_color")
		_text(x, y + h + _n("mood_below"), mood, int(_n("mood_font")), mood_color, HORIZONTAL_ALIGNMENT_LEFT)
		if _tranco_left > 0.0:
			_text(x + w, y + h + _n("mood_below"), _t("tranco"), int(_n("tranco_font")), _c("tranco_color"), HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_card() -> void:
	var species: GameData.Species = _data.species_by_id(_card_fish.id)
	var rarity_color: Color = Color.html(_data.rarity_colors[species.rarity])
	var k: float = minf(1.0, _card_time / _n("card_open_seconds"))
	var s: float = lerpf(_n("card_scale_from"), 1.0, k)
	var w: float = _n("card_width")
	var h: float = _n("card_height")
	var top: float = -h * 0.5
	draw_set_transform(size * 0.5, 0.0, Vector2(s, s))
	_panel(Rect2(-w * 0.5, top, w, h), _c("card_fill"), rarity_color)
	var title_key: String = "card_new" if _card_new else ("card_record" if _card_record else "card_caught")
	_text(0.0, top + _n("card_title_y"), _t(title_key), int(_n("card_title_font")), _c("card_new_color") if _card_new else _c("ui_cream"))
	_text(0.0, top + _n("card_name_y"), species.name, int(_n("card_name_font")), _c("ui_white"))
	_text(0.0, top + _n("card_rarity_y"), _data.rarity_names[species.rarity].to_upper(), int(_n("card_rarity_font")), rarity_color)
	_text(0.0, top + _n("card_stats_y"), _t("card_stats") % [_weight_text(_card_fish.weight), _length_text(_card_fish.length), _card_fish.value], int(_n("card_stats_font")), _c("ui_cream"))
	var entry: GameState.BookEntry = _state.book[_card_fish.id]
	_text(0.0, top + _n("card_book_y"), _t("card_book") % [entry.count, _weight_text(entry.best), _length_text(entry.longest)], int(_n("card_book_font")), _c("ui_muted"))
	if _card_time > _n("card_continue_delay"):
		_text(0.0, top + _n("card_continue_y"), _t("card_continue"), int(_n("card_continue_font")), _c("card_continue_color"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _length_text(cm: float) -> String:
	return Texts.length_text(cm, _data.fixed("meters_from_cm"))


func _weight_text(kg: float) -> String:
	return _t("weight_fmt") % String.num(kg, int(_data.fixed("weight_decimals"))).replace(".", ",")


func _on_fishing_ended(reason: FishingMachine.EndReason) -> void:
	show_toast("end_" + FishingMachine.EndReason.keys()[reason].to_lower())


func _on_fish_caught(fish: GameState.Catch, is_new: bool, is_record: bool) -> void:
	_card_fish = fish
	_card_new = is_new
	_card_record = is_record
	_card_time = 0.0
	card_open = true
	_card_armed = false
	_restore_frame = 0
	_catcher.visible = true
	pull.reset()
	pull.visible = false


func _on_level_up(new_level: int, _reward: int) -> void:
	# The full level-up screen is Story 007's ([Screens.open_level_up]); this is the short banner.
	show_toast("level_up")
	_toast_text = _t("level_up") % _data.level_names[new_level - 1].to_upper()


func _on_catcher_input(event: InputEvent) -> void:
	# Closes on RELEASE of a press that began on the card (both press and release are consumed);
	# the PUXAR and Rest buttons come back one frame later, so the same touch cannot reach them.
	var pressed: bool = false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	else:
		return
	_catcher.accept_event()
	if pressed:
		_card_armed = _card_time > _n("card_continue_delay")
	elif _card_armed:
		_card_armed = false
		card_open = false
		_catcher.visible = false
		_restore_frame = Engine.get_process_frames() + 1


## A text from texts_pt.json.
func _t(key: String) -> String:
	return str(_texts[key])


func _n(key: String) -> float:
	return _look.num("fishing", key)


func _c(key: String) -> Color:
	return _look.color("fishing", key)


## Draws [param text] with an outline; [param x] is its center, left or right edge by [param align].
func _text(x: float, baseline: float, text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var box: float = _n("text_box_width")
	var left: float = x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		left = x - box * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		left = x - box
	var font: Font = ThemeDB.fallback_font
	draw_string_outline(font, Vector2(left, baseline), text, align, box, font_size, int(_n("text_outline")), _c("text_outline_color"))
	draw_string(font, Vector2(left, baseline), text, align, box, font_size, color)


func _panel(rect: Rect2, fill: Color, border: Color) -> void:
	_style.bg_color = fill
	_style.border_color = border
	draw_style_box(_style, rect)
