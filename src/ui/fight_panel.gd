class_name FightPanel
extends Control
## The fishing minigame panel (2026-11-19), drawn in code in a chunky pixel style: a wooden
## board under a fishing rod with its reel; on the left a few lures and a glass tube that fills
## with the catch progress; on the right an underwater window (water, sand, swaying seaweed,
## coral, bubbles) where the fish swims and the hook hangs on its line.
## The rules are the ones of [FishingMachine], unchanged: the fish is the green zone
## ([member FishingMachine.zone_center], [member FishingMachine.zone_width]), the hook is the
## player's marker ([member FishingMachine.indicator], raised by holding PUXAR) and the tube is
## [member FishingMachine.progress]. It only reads the machine. Sizes and colors: "fight" group of
## world_look.json; every shape snaps to a pixel grid of "pixel" screen pixels.
##
## Usage:
## [codeblock]
## var panel := FightPanel.new()
## fishing_hud.add_child(panel)
## panel.setup(look, data, machine)
## [/codeblock]

var _look: WorldLook
var _data: GameData
var _machine: FishingMachine
var _p: float = 4.0
var _time: float = 0.0
var _prev_center: float = 0.5
var _facing: float = 1.0
var _tranco_left: float = 0.0
var _texts_mood: Array = []


## Places the panel at the bottom center and reads the look.
func setup(look: WorldLook, data: GameData, machine: FishingMachine) -> void:
	_look = look
	_data = data
	_machine = machine
	_p = look.num("fight", "pixel")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w: float = look.num("fight", "width")
	var h: float = look.num("fight", "height")
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -w * 0.5
	offset_right = w * 0.5
	offset_bottom = -look.num("fight", "bottom")
	offset_top = offset_bottom - h - 60.0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FishingHud.TEXTS_PATH))
	if parsed is Dictionary:
		_texts_mood = (parsed as Dictionary).get("mood", [])
	visible = false


## Shows "TRANCO!" for [param seconds] (the fish darted).
func flash_tranco(seconds: float) -> void:
	_tranco_left = seconds


func _process(delta: float) -> void:
	var phase: FishingMachine.Phase = _machine.phase
	visible = phase == FishingMachine.Phase.FIGHT or phase == FishingMachine.Phase.CAUGHT
	if not visible:
		return
	_time += delta
	_tranco_left = maxf(0.0, _tranco_left - delta)
	var moved: float = _machine.zone_center - _prev_center
	if absf(moved) > 0.0005:
		_facing = signf(moved)
	_prev_center = _machine.zone_center
	queue_redraw()


func _c(key: String) -> Color:
	return _look.color("fight", key)


## A rectangle snapped to the pixel grid.
func _r(x: float, y: float, w: float, h: float, color: Color) -> void:
	var px: float = floorf(x / _p) * _p
	var py: float = floorf(y / _p) * _p
	draw_rect(Rect2(px, py, maxf(_p, roundf(w / _p) * _p), maxf(_p, roundf(h / _p) * _p)), color)


func _draw() -> void:
	if _machine.species == null:
		return
	var caught: bool = _machine.phase == FishingMachine.Phase.CAUGHT
	var w: float = size.x
	var top: float = 60.0
	var h: float = size.y - top
	var p: float = _p
	# Title above the board.
	var rarity: Color = Color.html(_data.rarity_colors[_machine.species.rarity])
	var title: String = Texts.get_text("caught") if caught else Texts.get_text("fight_hint")
	_label(Vector2(w * 0.5, 14.0), title, _look.integer("fight", "title_font"), rarity if caught else Color.WHITE)
	# Board with planks and a dark edge.
	var by: float = top + p * 3.0
	_r(0.0, by, w, h - p * 3.0, _c("board_edge"))
	_r(p, by + p, w - p * 2.0, h - p * 5.0, _c("board"))
	_r(p, by + p, w - p * 2.0, p, _c("board_light"))
	for k in 3:
		_r(p, by + (h - p * 3.0) * (0.3 + 0.25 * float(k)), w - p * 2.0, p, _c("board_dark"))
	_r(w - p * 4.0, by + h * 0.35, p * 3.0, h * 0.3, _c("board_dark"))
	# Fishing rod across the top: cork handle, reel, shaft and guides.
	_r(p * 2.0, top, w * 0.3, p * 3.0, _c("rod_cork"))
	_r(p * 2.0, top + p * 2.0, w * 0.3, p, _c("rod_cork_dark"))
	_r(w * 0.3, top + p, w * 0.7 - p * 2.0, p, _c("rod_shaft"))
	_r(w * 0.3, top + p, w * 0.7 - p * 2.0, p * 0.5, _c("rod_shaft_light"))
	for k in 4:
		var gx: float = w * (0.45 + 0.17 * float(k))
		_r(gx, top, p, p * 3.0, _c("rod_shaft"))
	var reel := Vector2(w * 0.11, top + p * 9.0)
	_disc(reel, p * 6.0, _c("reel"))
	_disc(reel, p * 4.0, _c("reel_light"))
	for k in 4:
		var a: float = _time * 6.0 * (_machine.indicator_velocity if not caught else 0.0) + TAU * float(k) / 4.0
		_r(reel.x + cos(a) * p * 2.5 - p * 0.5, reel.y + sin(a) * p * 2.5 - p * 0.5, p, p, _c("reel"))
	# Lures pinned on the left part of the board.
	_lure(Vector2(p * 6.0, by + h * 0.55), _c("coral"))
	_lure(Vector2(p * 14.0, by + h * 0.72), _c("pebble"))
	_hook_shape(Vector2(p * 22.0, by + h * 0.5), _c("hook"))
	# Progress tube.
	var left_w: float = _look.num("fight", "left_width")
	var gw: float = _look.num("fight", "gauge_width")
	var gx0: float = left_w - gw - p * 3.0
	var gy0: float = by + p * 3.0
	var gh: float = h - p * 9.0
	_r(gx0 - p, gy0 - p, gw + p * 2.0, gh + p * 2.0, _c("glass_dark"))
	_r(gx0, gy0, gw, gh, _c("glass"))
	var progress: float = 1.0 if caught else clampf(_machine.progress, 0.0, 1.0)
	_r(gx0, gy0 + gh * (1.0 - progress), gw, gh * progress, _c("gauge_water"))
	for k in 5:
		_r(gx0 + gw - p * 2.0, gy0 + gh * float(k) / 5.0, p * 2.0, p, _c("glass_dark"))
	_r(gx0 - p * 2.0, gy0 + gh * (1.0 - progress) - p * 0.5, p * 2.0, p, _c("gauge_mark"))
	# Underwater window.
	var wx: float = left_w
	var wy: float = by + p * 3.0
	var ww: float = w - left_w - p * 7.0
	var wh: float = h - p * 9.0
	_r(wx - p * 2.0, wy - p * 2.0, ww + p * 4.0, wh + p * 4.0, _c("frame"))
	_r(wx - p, wy - p, ww + p * 2.0, p, _c("frame_light"))
	var bands: int = int(wh / p)
	for k in bands:
		_r(wx, wy + float(k) * p, ww, p, _c("water_top").lerp(_c("water_bottom"), float(k) / float(maxi(bands - 1, 1))))
	var sand_y: float = wy + wh - p * 3.0
	_r(wx, sand_y, ww, p * 3.0, _c("sand"))
	for k in int(ww / (p * 6.0)):
		_r(wx + float(k) * p * 6.0 + p * 2.0, sand_y + p, p * 2.0, p, _c("sand_dark"))
	var weeds: int = _look.integer("fight", "weeds")
	for k in weeds:
		var sx: float = wx + ww * (float(k) + 0.5) / float(weeds) + sin(float(k) * 7.3) * p * 3.0
		var tall: int = 5 + (k * 7) % 6
		for seg in tall:
			var sway: float = sin(_time * 1.6 + float(k) + float(seg) * 0.5) * p * 0.8 * float(seg) / float(tall)
			_r(sx + sway, sand_y - float(seg + 1) * p * 1.6, p, p * 1.6, _c("weed_a") if (seg + k) % 2 == 0 else _c("weed_b"))
		if k % 3 == 1:
			_r(sx + p * 3.0, sand_y - p * 3.0, p * 2.0, p * 3.0, _c("coral"))
			_r(sx + p * 2.0, sand_y - p * 4.0, p, p * 2.0, _c("coral"))
		if k % 2 == 0:
			_r(sx - p * 3.0, sand_y - p, p * 2.0, p, _c("pebble"))
	# Bubbles rising.
	var bubbles: int = _look.integer("fight", "bubbles")
	for k in bubbles:
		var t: float = fmod(_time * 0.3 + float(k) * 0.37, 1.0)
		var bx: float = wx + ww * fmod(float(k) * 0.618, 1.0)
		_r(bx + sin(t * 9.0 + float(k)) * p, sand_y - t * (wh - p * 4.0), p, p, _c("bubble"))
	# The fish (green zone) and the hook (marker).
	# The zone where the hook catches is a lighter band; the fish swims in its middle.
	var zone_w: float = _machine.zone_width * ww
	var fish_x: float = wx + _machine.zone_center * ww
	_r(fish_x - zone_w * 0.5, wy, zone_w, wh - p * 3.0, _c("zone_in") if _machine.in_zone or caught else _c("zone"))
	var fish_len: float = clampf(zone_w * 0.8, p * 12.0, p * _look.num("fight", "fish_max_pixels"))
	var fish_y: float = wy + wh * 0.45 + sin(_time * 3.0) * p
	if _tranco_left > 0.0:
		fish_y += sin(_time * 40.0) * p
	var fish_color: Color = Color.from_hsv(float(absi(hash(_machine.species.id)) % 1000) / 1000.0, 0.65, 0.8)
	if not FishArt.draw(self, _machine.species.id, Rect2(fish_x - fish_len * 0.5, fish_y - fish_len * 0.4, fish_len, fish_len * 0.8), _facing > 0.0, false):
		_fish(Vector2(fish_x, fish_y), fish_len, fish_color, rarity)
	var hx: float = wx + _machine.indicator * ww
	var hook_y: float = fish_y + p * 2.0
	_r(hx, wy, p * 0.5, hook_y - wy, _c("line"))
	_hook_shape(Vector2(hx, hook_y), _c("hook_in") if _machine.in_zone or caught else _c("hook"))
	# Mood and TRANCO! under the board.
	if not caught:
		var mood: String = Texts.get_text("mood_fmt") % str(_texts_mood[mini(_machine.species.rarity, _texts_mood.size() - 1)]) if not _texts_mood.is_empty() else ""
		_label(Vector2(wx + p * 2.0 + 60.0, top - 12.0), mood, _look.integer("fight", "mood_font"), rarity)
		if _tranco_left > 0.0:
			_label(Vector2(wx + ww - 60.0, top - 12.0), Texts.get_text("tranco"), _look.integer("fight", "tranco_font"), _c("coral"))


## A chunky fish centered on [param c], [param length] long, facing the swimming direction.
func _fish(c: Vector2, length: float, body: Color, rim: Color) -> void:
	var p: float = _p
	var cols: int = maxi(6, int(length / p))
	var half_h: float = maxf(p * 2.0, length * 0.18)
	for i in cols:
		var u: float = (float(i) + 0.5) / float(cols)
		# Round head (u near 1), body narrowing to the tail (u near 0).
		var profile: float = sqrt(maxf(0.0, sin(u * PI))) * lerpf(0.55, 1.0, u)
		var hh: float = maxf(p, half_h * profile)
		var x: float = c.x + (u - 0.5) * length * _facing
		_r(x, c.y - hh, p, hh * 2.0, body)
		_r(x, c.y + hh * 0.25, p, hh * 0.75, body.lightened(0.35))
		_r(x, c.y - hh, p, p, rim)
	var tail_x: float = c.x - length * 0.5 * _facing
	for k in 3:
		var tx: float = tail_x - float(k) * p * _facing
		_r(tx, c.y - p * float(k + 1), p, p * float(k * 2 + 2), body.darkened(0.25))
	var eye_x: float = c.x + length * 0.36 * _facing
	_r(eye_x, c.y - half_h * 0.45, p, p, Color.WHITE)
	_r(eye_x + p * 0.5 * _facing, c.y - half_h * 0.45, p * 0.5, p, Color(0.1, 0.08, 0.06))


func _hook_shape(c: Vector2, color: Color) -> void:
	var p: float = _p
	_r(c.x, c.y, p, p * 3.0, color)
	_r(c.x - p * 2.0, c.y + p * 3.0, p * 3.0, p, color)
	_r(c.x - p * 2.0, c.y + p * 1.0, p, p * 2.0, color)


func _lure(c: Vector2, color: Color) -> void:
	var p: float = _p
	_r(c.x, c.y, p * 5.0, p * 2.0, color)
	_r(c.x + p * 5.0, c.y - p, p * 2.0, p * 4.0, color.darkened(0.25))
	_r(c.x + p, c.y, p, p, Color.WHITE)
	_hook_shape(Vector2(c.x - p * 2.0, c.y + p), _c("hook"))


func _disc(c: Vector2, r: float, color: Color) -> void:
	var p: float = _p
	var n: int = int(r / p)
	for j in range(-n, n + 1):
		var half: float = sqrt(maxf(0.0, r * r - pow(float(j) * p, 2.0)))
		_r(c.x - half, c.y + float(j) * p, half * 2.0, p, color)


func _label(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var box: float = size.x
	draw_string_outline(font, Vector2(center.x - box * 0.5, center.y + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, box, font_size, 5, Color(0.12, 0.08, 0.05))
	draw_string(font, Vector2(center.x - box * 0.5, center.y + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, box, font_size, color)
