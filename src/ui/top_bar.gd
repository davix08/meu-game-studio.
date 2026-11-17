class_name TopBar
extends Control
## The top of the HUD, in the style of references/lakebound-3d-look.png (Story 006): level star
## with the species bar to the next level (e.g. 3/5), coins, energy bar with percentage, the sun
## or moon with day, time and period, and the gear that opens the settings. An optional FPS
## counter sits under the gear. Values come from [GameState] and [GameClock]; it redraws on the
## state signals and every few frames for the clock. It never changes game state.
##
## Usage:
## [codeblock]
## var bar := TopBar.new()
## hud.add_child(bar)
## bar.setup(look, data, state, clock, progression)
## bar.settings_pressed.connect(open_settings)
## [/codeblock]

## The gear was tapped.
signal settings_pressed

var _look: WorldLook
var _data: GameData
var _state: GameState
var _clock: GameClock
var _progression: Progression
var _gear: Button
var _fps: Label
var _refresh: float = 0.0


## Builds the gear and the FPS label and connects to the state.
func setup(look: WorldLook, data: GameData, state: GameState, clock: GameClock, progression: Progression) -> void:
	_look = look
	_data = data
	_state = state
	_clock = clock
	_progression = progression
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0.0, look.num("ui", "top_height") + look.num("ui", "top_margin"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side: float = look.num("ui", "top_height")
	_gear = Button.new()
	_gear.focus_mode = Control.FOCUS_NONE
	var glyph := GearIcon.new()
	glyph.color = look.color("ui", "pill_text")
	_gear.add_child(glyph)
	_gear.size = Vector2(side, side)
	_gear.anchor_left = 1.0
	_gear.anchor_right = 1.0
	_gear.offset_left = -side - look.num("ui", "top_margin")
	_gear.offset_right = -look.num("ui", "top_margin")
	_gear.offset_top = look.num("ui", "top_margin")
	_gear.offset_bottom = look.num("ui", "top_margin") + side
	_gear.pressed.connect(settings_pressed.emit)
	add_child(_gear)
	_fps = Label.new()
	_fps.anchor_left = 1.0
	_fps.anchor_right = 1.0
	_fps.offset_left = -160.0
	_fps.offset_right = -look.num("ui", "top_margin")
	_fps.offset_top = look.num("ui", "top_margin") * 2.0 + side
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.add_theme_color_override(&"font_color", look.color("ui", "pill_text"))
	_fps.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	_fps.add_theme_constant_override(&"outline_size", 6)
	add_child(_fps)
	state.coins_changed.connect(func(_c: int) -> void: queue_redraw())
	state.energy_changed.connect(func(_e: float) -> void: queue_redraw())
	state.level_up.connect(func(_l: int, _r: int) -> void: queue_redraw())
	state.day_started.connect(func(_d: int, _a: bool) -> void: queue_redraw())


func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.25
		_fps.visible = _state.show_fps
		_fps.text = "FPS %d" % Engine.get_frames_per_second()
		queue_redraw()


func _draw() -> void:
	var m: float = _look.num("ui", "top_margin")
	var h: float = _look.num("ui", "top_height")
	var font: Font = ThemeDB.fallback_font
	var text_color: Color = _look.color("ui", "pill_text")
	var x: float = m
	# Level: star + "Nv 2" + species bar to the next level.
	var w: float = 290.0
	_pill(Rect2(x, m, w, h))
	_star(Vector2(x + 32.0, m + h * 0.5), 20.0)
	draw_string(font, Vector2(x + 30.0, m + h * 0.5 + 8.0), str(_state.level), HORIZONTAL_ALIGNMENT_CENTER, 4.0, 22, _look.color("ui", "ink"))
	var level_name: String = _data.level_names[_state.level - 1]
	draw_string(font, Vector2(x + 62.0, m + 26.0), level_name, HORIZONTAL_ALIGNMENT_LEFT, w - 70.0, 20, text_color)
	var have: int = _state.discovered()
	var need: int = _progression.level_need(_state.level + 1) if _state.level < _data.max_level() else have
	var base: int = _progression.level_need(_state.level) if _state.level > 1 else 0
	var k: float = 1.0 if need <= base else clampf(float(have - base) / float(need - base), 0.0, 1.0)
	_bar(Rect2(x + 62.0, m + 36.0, w - 140.0, 16.0), k, _look.color("ui", "species_fill"))
	draw_string(font, Vector2(x + w - 72.0, m + 51.0), "%d/%d" % [have, need], HORIZONTAL_ALIGNMENT_LEFT, 70.0, 18, text_color)
	x += w + m
	# Coins.
	w = 170.0
	_pill(Rect2(x, m, w, h))
	draw_circle(Vector2(x + 30.0, m + h * 0.5), 15.0, _look.color("ui", "coin"))
	draw_arc(Vector2(x + 30.0, m + h * 0.5), 15.0, 0.0, TAU, 20, _look.color("ui", "coin_dark"), 3.0)
	draw_string(font, Vector2(x + 54.0, m + h * 0.5 + 9.0), str(_state.coins), HORIZONTAL_ALIGNMENT_LEFT, w - 60.0, 26, text_color)
	x += w + m
	# Energy.
	w = 230.0
	_pill(Rect2(x, m, w, h))
	var energy_max: float = _data.fixed("energy_max")
	var e: float = clampf(_state.energy / energy_max, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 26, m + 14), Vector2(x + 16, m + 36), Vector2(x + 26, m + 36), Vector2(x + 20, m + 52), Vector2(x + 36, m + 28), Vector2(x + 26, m + 28)]), _look.color("ui", "coin"))
	_bar(Rect2(x + 46.0, m + 22.0, w - 120.0, 20.0), e, _look.color("ui", "energy_fill") if e > 0.25 else _look.color("ui", "energy_low"))
	draw_string(font, Vector2(x + w - 68.0, m + 40.0), Texts.fmt("energy_fmt", [roundi(e * 100.0)]), HORIZONTAL_ALIGNMENT_LEFT, 66.0, 20, text_color)
	x += w + m
	# Clock: sun or moon, day, time and period.
	w = 300.0
	_pill(Rect2(x, m, w, h))
	var hour: float = fmod(_state.minutes / 60.0, 24.0)
	var night: bool = hour >= 18.5 or hour < 6.0
	var icon_c := Vector2(x + 32.0, m + h * 0.5)
	if night:
		draw_circle(icon_c, 15.0, _look.color("ui", "moon"))
		draw_circle(icon_c + Vector2(7, -5), 13.0, _look.color("ui", "pill_fill").lightened(0.1))
	else:
		for i in 8:
			var a: float = TAU * float(i) / 8.0
			draw_line(icon_c + Vector2(cos(a), sin(a)) * 17.0, icon_c + Vector2(cos(a), sin(a)) * 23.0, _look.color("ui", "sun"), 3.0)
		draw_circle(icon_c, 13.0, _look.color("ui", "sun"))
	draw_string(font, Vector2(x + 62.0, m + 27.0), Texts.fmt("day_fmt", [_state.day]) + "  " + _clock.clock_text(_state.minutes), HORIZONTAL_ALIGNMENT_LEFT, w - 70.0, 22, text_color)
	draw_string(font, Vector2(x + 62.0, m + 52.0), _clock.period_name(_state.minutes), HORIZONTAL_ALIGNMENT_LEFT, w - 70.0, 18, _look.color("ui", "row_alt"))


func _pill(rect: Rect2) -> void:
	draw_style_box(UiKit.flat(_look.color("ui", "pill_fill"), int(rect.size.y * 0.5)), rect)


func _bar(rect: Rect2, k: float, color: Color) -> void:
	draw_style_box(UiKit.flat(_look.color("ui", "energy_back"), int(rect.size.y * 0.5)), rect)
	if k > 0.0:
		draw_style_box(UiKit.flat(color, int(rect.size.y * 0.5)), Rect2(rect.position, Vector2(maxf(rect.size.y, rect.size.x * k), rect.size.y)))


func _star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = -PI * 0.5 + TAU * float(i) / 10.0
		var rr: float = r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, _look.color("ui", "star"))
