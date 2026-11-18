# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
# Date: 2026-11-18
# One-thumb fishing loop on a dock. One context button (bottom right, or Space):
#   IDLE      hold  -> CHARGING (power meter bounces)   release -> FLYING
#   WAITING   fish approach; bite -> BITE (tap within the window to hook)
#   FIGHT     hold = reel (tension up, fish closer); release = let it run
#   RESULT    tap -> IDLE
# `-- --autotest` plays one full round by itself and prints PASS/FAIL.
extends Node2D

enum S { IDLE, CHARGING, FLYING, WAITING, BITE, FIGHT, RESULT }

const ROD_TIP := Vector2(326, 152)
const PLAYER := Vector2(320, 172)
const BITE_WINDOW := 0.9
const SWEET := Vector2(0.78, 0.94)

var state := S.IDLE
var rng := RandomNumberGenerator.new()
var held := false
var power := 0.0
var _power_t := 0.0
var perfect := false
var cast_target := Vector2.ZERO
var bobber := Vector2.ZERO
var _fly_t := 0.0
var _wait_left := 0.0
var _bite_left := 0.0
var species: Dictionary = {}
var fight: Fight
var result_text := ""
var result_kind := ""
var catch_size := 0.0
var catch_weight := 0.0
var message := "Segure o botão para lançar"
var _msg_t := 0.0
var records := {} # id -> {count, best_size, best_weight}
var stats := {"hooked": 0, "caught": 0, "broke": 0, "escaped": 0, "missed": 0}
var coins := 0
var _t := 0.0
var shadows: Array = [] # [{pos, vel, target}]
var _shake := 0.0

var hud: Node2D
var btn_center := Vector2.ZERO
const BTN_R := 38.0
var _btn_touch := -1


func _ready() -> void:
	rng.seed = 2026
	var water := ColorRect.new()
	water.position = Vector2(-80, -20)
	water.size = Vector2(840, 300)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://water.gdshader")
	mat.set_shader_parameter("rect_size", water.size)
	water.material = mat
	water.show_behind_parent = true
	add_child(water)
	var world := Node2D.new()
	world.set_script(preload("res://world.gd"))
	world.show_behind_parent = true
	add_child(world)
	for i in 3:
		shadows.append({"pos": Vector2(rng.randf_range(80, 560), rng.randf_range(30, 220)), "vel": Vector2.ZERO})
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud)
	layer.add_child(hud)
	get_viewport().size_changed.connect(_layout)
	_layout()
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	btn_center = Vector2(s.x - 62, s.y - 62)


# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _btn_touch == -1 and t.position.distance_to(btn_center) <= BTN_R + 14:
			_btn_touch = t.index
			_press()
		elif not t.pressed and t.index == _btn_touch:
			_btn_touch = -1
			_release()
	elif event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE and not event.is_echo():
		if event.is_pressed():
			_press()
		else:
			_release()


func _press() -> void:
	held = true
	match state:
		S.IDLE:
			state = S.CHARGING
			_power_t = 0.0
		S.WAITING:
			_say("Cedo demais! O peixe se assustou.")
			stats["missed"] += 1
			_reset_line()
		S.BITE:
			_hook()
		S.RESULT:
			state = S.IDLE
			_say("Segure o botão para lançar")


func _release() -> void:
	held = false
	if state == S.CHARGING:
		_cast()


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_shake = maxf(0.0, _shake - delta * 4.0)
	match state:
		S.CHARGING:
			_power_t += delta
			var tri := fmod(_power_t * 1.1, 2.0)
			power = tri if tri <= 1.0 else 2.0 - tri
		S.FLYING:
			_fly_t += delta / 0.55
			var p := ROD_TIP.lerp(cast_target, minf(_fly_t, 1.0))
			p.y -= sin(minf(_fly_t, 1.0) * PI) * 40.0
			bobber = p
			if _fly_t >= 1.0:
				bobber = cast_target
				state = S.WAITING
				_wait_left = rng.randf_range(1.5, 5.0)
				_say("Espere a mordida…")
		S.WAITING:
			_wait_left -= delta
			if _wait_left <= 0.0:
				state = S.BITE
				_bite_left = BITE_WINDOW
				_shake = 1.0
				Input.vibrate_handheld(120)
				_say("MORDEU! Toque!")
		S.BITE:
			_bite_left -= delta
			if _bite_left <= 0.0:
				stats["missed"] += 1
				_say("Lento demais… o peixe roubou a isca.")
				_reset_line()
		S.FIGHT:
			var r := fight.step(delta, held)
			bobber = ROD_TIP.lerp(cast_target, clampf(fight.d, 0.0, 1.3))
			bobber += Vector2(sin(_t * 23.0), cos(_t * 17.0)) * (1.5 + fight.pull * 2.0)
			if fight.surging():
				_shake = maxf(_shake, 0.4)
			if r != "":
				_end_fight(r)
	_update_shadows(delta)
	queue_redraw()
	hud.queue_redraw()


func _cast() -> void:
	perfect = power >= SWEET.x and power <= SWEET.y
	var dist := 30.0 + power * 120.0
	var wobble := 0.0 if perfect else rng.randf_range(-40.0, 40.0) * (1.0 - power * 0.5)
	cast_target = ROD_TIP + Vector2(wobble, -dist)
	_fly_t = 0.0
	state = S.FLYING
	_say("Perfeito!" if perfect else "Lançado!")


func _hook() -> void:
	species = Species.pick(rng, power, perfect)
	fight = Fight.new(species["strength"], species["surge"], rng)
	stats["hooked"] += 1
	state = S.FIGHT
	_say("Fisgou! Segure para puxar, solte se a linha esticar demais")


func _end_fight(r: String) -> void:
	stats[r] += 1
	state = S.RESULT
	result_kind = r
	match r:
		"caught":
			var sz: Vector2 = species["size"]
			catch_size = snappedf(rng.randf_range(sz.x, sz.y), 0.1)
			catch_weight = snappedf(species["k"] * pow(catch_size, 3) / 1000.0, 0.01)
			var rec: Dictionary = records.get(species["id"], {"count": 0, "best_size": 0.0, "best_weight": 0.0})
			var is_record: bool = catch_size > rec["best_size"]
			rec["count"] += 1
			rec["best_size"] = maxf(rec["best_size"], catch_size)
			rec["best_weight"] = maxf(rec["best_weight"], catch_weight)
			records[species["id"]] = rec
			var value := int(species["value"] * (0.6 + catch_size / sz.y))
			coins += value
			result_text = "%s  (%s)\n%.1f cm · %.2f kg · +%d moedas%s" % [species["name"], species["rarity"], catch_size, catch_weight, value, "\nNOVO RECORDE!" if is_record and rec["count"] > 1 else ""]
		"broke":
			result_text = "A linha arrebentou!\nEra um peixe forte… (%s?)" % ("?" if species["rarity"] == "Comum" else species["rarity"])
			_shake = 1.0
		"escaped":
			result_text = "O peixe escapou.\nPuxe mais quando a tensão estiver baixa."
	_say("Toque para continuar")


func _reset_line() -> void:
	state = S.IDLE
	held = false


func _say(t: String) -> void:
	message = t
	_msg_t = 2.5


func _update_shadows(delta: float) -> void:
	for i in shadows.size():
		var sh: Dictionary = shadows[i]
		var target: Vector2
		if i == 0 and state in [S.WAITING, S.BITE]:
			target = bobber + Vector2(0, 6) # the curious one swims to the bobber
		elif i == 0 and state == S.FIGHT:
			target = bobber + Vector2(sin(_t * 3.0) * 6.0, 6)
		else:
			target = sh.get("target", sh["pos"])
			if sh["pos"].distance_to(target) < 6.0:
				sh["target"] = Vector2(rng.randf_range(40, 600), rng.randf_range(20, 225))
				target = sh["target"]
		var speed := 60.0 if i == 0 and state == S.FIGHT else 18.0
		sh["vel"] = sh["vel"].lerp((target - sh["pos"]).limit_length(speed), delta * 2.0)
		sh["pos"] += sh["vel"] * delta


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake * 2.0
	draw_set_transform(off)
	for sh in shadows:
		var p: Vector2 = sh["pos"]
		if p.y < world_shore(p.x) - 8:
			var ang: float = sh["vel"].angle() if sh["vel"].length() > 1.0 else 0.0
			draw_set_transform(p + off, ang, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, 9.0, Color(0.02, 0.1, 0.2, 0.35))
			draw_set_transform(off)
	# player: fisher seen from behind, facing the water
	var bob := sin(_t * 2.0)
	draw_rect(Rect2(PLAYER + Vector2(-6, 2), Vector2(12, 3)), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(PLAYER + Vector2(-3, -4), Vector2(2, 6)), Color("2f3a5c"))
	draw_rect(Rect2(PLAYER + Vector2(1, -4), Vector2(2, 6)), Color("2f3a5c"))
	draw_rect(Rect2(PLAYER + Vector2(-4, -12 + bob * 0.3), Vector2(8, 9)), Color("c9583a"))
	draw_rect(Rect2(PLAYER + Vector2(-3, -18), Vector2(6, 6)), Color("5a3a22"))
	draw_rect(Rect2(PLAYER + Vector2(-5, -19), Vector2(10, 2)), Color("d8b860"))
	draw_rect(Rect2(PLAYER + Vector2(-3, -21), Vector2(6, 2)), Color("e6c870"))
	# rod
	var bend := 0.0
	if state == S.FIGHT:
		bend = fight.tension * 6.0
	elif state == S.CHARGING:
		bend = -power * 5.0
	var tip := ROD_TIP + Vector2(bend * 0.6, bend)
	draw_line(PLAYER + Vector2(3, -8), tip, Color("6b4428"), 2.0)
	# line + bobber
	if state in [S.FLYING, S.WAITING, S.BITE, S.FIGHT]:
		var lc := Color(1, 1, 1, 0.8)
		if state == S.FIGHT and fight.tension > 0.85:
			lc = Color(1, 0.3, 0.25, 0.95)
		var sag := 0.0 if state == S.FIGHT and held else 8.0
		var mid := (tip + bobber) / 2.0 + Vector2(0, sag)
		draw_polyline(PackedVector2Array([tip, mid, bobber]), lc, 1.0)
		var dip := 0.0
		if state == S.WAITING:
			dip = sin(_t * 3.0) * 1.0
		elif state == S.BITE:
			dip = 3.0 + sin(_t * 30.0) * 2.0
		var bp := bobber + Vector2(0, dip)
		if state != S.FLYING:
			draw_arc(bobber + Vector2(0, 2), 5.0 + fmod(_t * 6.0, 4.0), 0, TAU, 16, Color(1, 1, 1, 0.35), 1.0)
		draw_circle(bp, 3.0, Color("e8463b"))
		draw_rect(Rect2(bp + Vector2(-3, 0), Vector2(6, 2)), Color.WHITE)
		if state == S.BITE:
			draw_string(ThemeDB.fallback_font, bp + Vector2(-3, -8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.95, 0.3))
	draw_set_transform(Vector2.ZERO)


func world_shore(x: float) -> float:
	return 262.0 + 6.0 * sin(x * 0.03) + 3.0 * sin(x * 0.11)


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	var s := get_viewport().get_visible_rect().size
	# top bar: session stats
	var caught_species := records.size()
	hud.draw_rect(Rect2(0, 0, s.x, 16), Color(0, 0, 0, 0.35))
	hud.draw_string(font, Vector2(6, 12), "Peixes: %d   Espécies: %d/4   Moedas: %d   Linhas partidas: %d" % [stats["caught"], caught_species, coins, stats["broke"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	# message
	if _msg_t > 0.0 or state != S.RESULT:
		hud.draw_string(font, Vector2(0, 34), message, HORIZONTAL_ALIGNMENT_CENTER, s.x, 11, Color(1, 1, 1), )
	# button
	var label := "LANÇAR"
	var col := Color(0.2, 0.55, 0.85)
	match state:
		S.CHARGING: label = "SOLTE"
		S.FLYING, S.WAITING: label = "…"; col = Color(0.35, 0.4, 0.45)
		S.BITE: label = "FISGAR!"; col = Color(0.95, 0.55, 0.15)
		S.FIGHT: label = "PUXAR"; col = Color(0.85, 0.3, 0.25) if held else Color(0.3, 0.65, 0.4)
		S.RESULT: label = "OK"
	var r := BTN_R + (4.0 * sin(_t * 18.0) if state == S.BITE else 0.0)
	hud.draw_circle(btn_center, r + 3, Color(0, 0, 0, 0.35))
	hud.draw_circle(btn_center, r, Color(col, 0.9 if held else 0.75))
	hud.draw_string(font, btn_center + Vector2(-BTN_R, 4), label, HORIZONTAL_ALIGNMENT_CENTER, BTN_R * 2, 11, Color.WHITE)
	# power meter (charging)
	if state == S.CHARGING:
		var bx := btn_center.x - 64
		var rect := Rect2(bx, btn_center.y - 50, 10, 90)
		hud.draw_rect(rect.grow(2), Color(0, 0, 0, 0.5))
		var sweet_y0 := rect.end.y - rect.size.y * SWEET.y
		hud.draw_rect(Rect2(bx, sweet_y0, 10, rect.size.y * (SWEET.y - SWEET.x)), Color(0.3, 0.85, 0.4, 0.8))
		hud.draw_rect(Rect2(bx, rect.end.y - rect.size.y * power, 10, 2), Color.WHITE)
		hud.draw_string(font, Vector2(bx - 10, rect.position.y - 6), "força", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	# tension + distance (fight)
	if state == S.FIGHT:
		var bx := btn_center.x - 66
		var rect := Rect2(bx, btn_center.y - 56, 12, 100)
		hud.draw_rect(rect.grow(2), Color(0, 0, 0, 0.5))
		hud.draw_rect(Rect2(bx, rect.position.y, 12, rect.size.y * 0.15), Color(0.8, 0.15, 0.1, 0.6))
		var tv := clampf(fight.tension, 0.0, 1.0)
		var tc := Color(0.35, 0.8, 0.4).lerp(Color(0.95, 0.2, 0.15), tv)
		hud.draw_rect(Rect2(bx, rect.end.y - rect.size.y * tv, 12, rect.size.y * tv), tc)
		hud.draw_string(font, Vector2(bx - 14, rect.position.y - 6), "tensão", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		# distance bar along the bottom
		var dw := 180.0
		var dr := Rect2(s.x / 2.0 - dw / 2.0, s.y - 22, dw, 6)
		hud.draw_rect(dr.grow(2), Color(0, 0, 0, 0.5))
		var prog := clampf(1.0 - fight.d, 0.0, 1.0)
		hud.draw_rect(Rect2(dr.position, Vector2(dw * prog, 6)), Color(0.4, 0.75, 1.0))
		hud.draw_string(font, Vector2(dr.position.x, dr.position.y - 4), "peixe chegando", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		hud.draw_rect(Rect2(bx + 16, rect.position.y, 6, rect.size.y), Color(0, 0, 0, 0.4))
		hud.draw_rect(Rect2(bx + 16, rect.end.y - rect.size.y * fight.stamina, 6, rect.size.y * fight.stamina), Color(0.95, 0.8, 0.3, 0.8))
	# result card
	if state == S.RESULT:
		var card := Rect2(s.x / 2.0 - 130, s.y / 2.0 - 50, 260, 86)
		hud.draw_rect(card.grow(3), Color(0.1, 0.07, 0.04, 0.85))
		hud.draw_rect(card, Color(0.96, 0.9, 0.76))
		if result_kind == "caught":
			var fc: Color = species["color"]
			var c := card.position + Vector2(36, 32)
			hud.draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
			hud.draw_circle(Vector2.ZERO, 18, fc)
			hud.draw_set_transform(Vector2.ZERO)
			hud.draw_colored_polygon(PackedVector2Array([c + Vector2(16, 0), c + Vector2(28, -8), c + Vector2(28, 8)]), fc.darkened(0.2))
			hud.draw_circle(c + Vector2(-10, -2), 2, Color.BLACK)
			hud.draw_string(font, card.position + Vector2(70, 22), "Peixe pego!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.4, 0.15))
		else:
			hud.draw_string(font, card.position + Vector2(12, 22), "Que pena!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.15, 0.1))
		var y := 40.0
		for ln in result_text.split("\n"):
			hud.draw_string(font, card.position + Vector2(70 if result_kind == "caught" else 12, y), ln, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 80, 9, Color(0.15, 0.1, 0.05))
			y += 13.0


# ------------------------------------------------------------------ self-test

func _check(name: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", name, detail])


func _tap_button(pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = get_viewport().get_final_transform() * btn_center
	Input.parse_input_event(e)


func _autotest() -> void:
	await get_tree().create_timer(0.6).timeout
	_check("starts idle", state == S.IDLE, str(state))
	# charge until the meter is in the sweet zone, then release
	_tap_button(true)
	await get_tree().create_timer(0.1).timeout
	_check("hold starts charging", state == S.CHARGING, str(state))
	while not (power >= SWEET.x + 0.02 and power <= SWEET.y - 0.02 and _power_t > 0.3):
		await get_tree().process_frame
	_tap_button(false)
	await get_tree().create_timer(0.05).timeout
	_check("release casts", state == S.FLYING and perfect, "state=%d perfect=%s power=%.2f" % [state, perfect, power])
	while state in [S.FLYING, S.WAITING]:
		await get_tree().process_frame
	_check("fish bites", state == S.BITE, str(state))
	await get_tree().create_timer(0.25).timeout
	_tap_button(true)
	await get_tree().process_frame
	_check("tap during bite hooks", state == S.FIGHT, "%s" % species.get("name", "?"))
	_tap_button(false)
	# play the fight like a careful human: reel, back off near the red zone
	var reel := false
	var shot_taken := false
	while state == S.FIGHT:
		if fight.tension > 0.85 and reel:
			reel = false
			_tap_button(false)
		elif fight.tension < 0.55 and not reel:
			reel = true
			_tap_button(true)
		if not shot_taken and fight.d < 0.6:
			shot_taken = true
			print("SHOT fight")
		await get_tree().create_timer(0.1).timeout
	if reel:
		_tap_button(false)
	_check("careful reeling lands the fish", result_kind == "caught", result_kind)
	await get_tree().create_timer(1.5).timeout
	_tap_button(true)
	_tap_button(false)
	await get_tree().process_frame
	_check("tap on result returns to idle", state == S.IDLE, str(state))
	# a lazy cast (tap) still works and too-early tap scares the fish
	_tap_button(true)
	await get_tree().create_timer(0.05).timeout
	_tap_button(false)
	await get_tree().create_timer(0.1).timeout
	while state == S.FLYING:
		await get_tree().process_frame
	_tap_button(true)
	_tap_button(false)
	await get_tree().create_timer(0.15).timeout
	_check("tap while waiting scares the fish", state == S.IDLE and stats["missed"] == 1, "missed=%d" % stats["missed"])
	print("AUTOTEST DONE")
	get_tree().quit()
