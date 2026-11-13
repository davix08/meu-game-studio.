# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
# Builds the whole test map in code, wires stick -> player, and runs an
# optional scripted self-test (`-- --autotest`) that drives the stick with
# injected touch events and prints PASS/FAIL lines.
extends Node2D

const Obstacle := preload("res://obstacle.gd")

var player: CharacterBody2D
var hud: CanvasLayer
var obstacles: Array[Node2D] = []


func _ready() -> void:
	var water := ColorRect.new()
	var wx := 760.0
	water.position = Vector2(wx, 0)
	water.size = Vector2(Layout.W - wx, Layout.H)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://water.gdshader")
	mat.set_shader_parameter("rect_size", water.size)
	water.material = mat
	add_child(water)

	var ground := Node2D.new()
	ground.set_script(preload("res://ground.gd"))
	add_child(ground)
	var shore := Node2D.new()
	shore.set_script(preload("res://shore.gd"))
	add_child(shore)

	_build_water_collision()

	var entities := Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	_scatter(entities)

	player = CharacterBody2D.new()
	player.set_script(preload("res://player.gd"))
	player.position = Layout.SPAWN
	entities.add_child(player)

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = Layout.W
	cam.limit_bottom = Layout.H
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	player.add_child(cam)

	hud = CanvasLayer.new()
	hud.set_script(preload("res://hud.gd"))
	add_child(hud)

	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()


func _build_water_collision() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for y in range(0, Layout.H, 8):
		var x0 := Layout.shore_x(y + 4) + 2.0
		if y >= Layout.DOCK_Y0 and y < Layout.DOCK_Y1:
			x0 = Layout.DOCK_X1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(Layout.W - x0 + 40, 8)
		cs.shape = r
		cs.position = Vector2(x0 + r.size.x / 2.0, y + 4)
		body.add_child(cs)
	# map border
	for rect in [Rect2(-40, -40, Layout.W + 80, 40), Rect2(-40, Layout.H, Layout.W + 80, 40), Rect2(-40, 0, 40, Layout.H)]:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = rect.size
		cs.shape = r
		cs.position = rect.position + rect.size / 2.0
		body.add_child(cs)


func _scatter(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var placed: Array[Vector2] = []
	var wanted := {"tree": 46, "rock": 18, "bush": 30}
	for kind in wanted:
		var n := 0
		var tries := 0
		while n < wanted[kind] and tries < 3000:
			tries += 1
			var p := Vector2(rng.randf_range(20, 790), rng.randf_range(30, Layout.H - 10))
			var margin := 46.0 if kind == "tree" else 34.0
			if p.x > Layout.shore_x(p.y) - margin:
				continue
			if Layout.dist_to_path(p) < 26 or p.distance_to(Layout.SPAWN) < 60:
				continue
			var ok := true
			for q in placed:
				if p.distance_to(q) < 30:
					ok = false
					break
			if not ok:
				continue
			placed.append(p)
			var o := StaticBody2D.new()
			o.set_script(Obstacle)
			o.position = p
			o.setup(kind, rng.randi() % 4)
			parent.add_child(o)
			obstacles.append(o)
			n += 1


func _physics_process(_delta: float) -> void:
	var v: Vector2 = hud.left_stick.value
	var kb := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	if kb != Vector2.ZERO:
		v = kb
	player.move_input = v
	player.aim_input = hud.right_stick.value
	player.running = hud.run_on or Input.is_key_pressed(KEY_SHIFT)
	hud.debug.text = "pos %d,%d  vel %.0f  stick %.2f  %s  fps %d" % [
		player.position.x, player.position.y, player.velocity.length(), v.length(),
		"CORRER" if player.running else "andar", Engine.get_frames_per_second()]


# ---------------------------------------------------------------- self-test

func _touch(index: int, vp_pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = get_viewport().get_final_transform() * vp_pos
	Input.parse_input_event(e)


func _drag(index: int, vp_pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = get_viewport().get_final_transform() * vp_pos
	Input.parse_input_event(e)


func _hold_left(dir: Vector2, seconds: float) -> Vector2:
	var c: Vector2 = hud.left_stick.home
	_touch(0, c, true)
	await get_tree().physics_frame
	_drag(0, c + dir * 40.0)
	await get_tree().create_timer(0.3).timeout # reach full speed
	var start := player.position
	await get_tree().create_timer(seconds).timeout
	var moved := player.position - start
	_touch(0, c + dir * 40.0, false)
	await get_tree().create_timer(0.3).timeout
	return moved


func _check(name: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", name, detail])


func _autotest() -> void:
	await get_tree().create_timer(0.5).timeout
	var d1 := await _hold_left(Vector2.RIGHT, 1.0)
	_check("stick moves player (walk)", absf(d1.x - player.WALK_SPEED) < 8.0, "dx/s=%.1f" % d1.x)
	var d2 := await _hold_left(Vector2(1, -1).normalized(), 1.0)
	_check("diagonal not faster than straight", absf(d2.length() - d1.length()) < 6.0, "diag=%.1f straight=%.1f" % [d2.length(), d1.length()])
	var small := await _hold_left(Vector2.LEFT * 0.1, 0.5)
	_check("dead zone ignores tiny drag", small.length() < 1.0, "moved=%.2f" % small.length())
	_touch(5, hud.run_center, true)
	_touch(5, hud.run_center, false)
	player.position = Vector2(Layout.dock_x0() - 10, float(Layout.DOCK_Y0 + Layout.DOCK_Y1) / 2.0)
	await get_tree().physics_frame
	var d3 := await _hold_left(Vector2.RIGHT, 1.0)
	_check("run button toggles run", absf(d3.x - player.RUN_SPEED) < 10.0, "dx/s=%.1f" % d3.x)
	_touch(5, hud.run_center, true)
	_touch(5, hud.run_center, false)
	# right stick shows aim
	var rc: Vector2 = hud.right_stick.home
	_touch(1, rc, true)
	_drag(1, rc + Vector2(30, -20))
	await get_tree().create_timer(0.2).timeout
	_check("right stick sets aim", player.aim_input.length() > 0.5, "aim=%s" % player.aim_input)
	_touch(1, rc, false)
	# shore blocks walking into water
	player.position = Vector2(Layout.shore_x(600) - 50, 600)
	await get_tree().physics_frame
	await _hold_left(Vector2.RIGHT, 1.5)
	_check("water blocks at shore", player.position.x < Layout.shore_x(600) + 4, "x=%.1f shore=%.1f" % [player.position.x, Layout.shore_x(600)])
	# dock lets you walk out over water and stops at its end
	player.position = Vector2(Layout.dock_x0() - 20, float(Layout.DOCK_Y0 + Layout.DOCK_Y1) / 2.0)
	await get_tree().physics_frame
	await _hold_left(Vector2.RIGHT, 4.5)
	_check("dock walkable to its end", player.position.x > Layout.DOCK_X1 - 12 and player.position.x < Layout.DOCK_X1 + 1, "x=%.1f end=%d" % [player.position.x, Layout.DOCK_X1])
	# trees block
	var tree: Node2D = null
	for o in obstacles:
		if o.kind == "tree" and o.position.x > 80:
			tree = o
			break
	player.position = tree.position + Vector2(-30, 0)
	await get_tree().physics_frame
	await _hold_left(Vector2.RIGHT, 1.0)
	_check("tree trunk blocks", player.position.x < tree.position.x - 8, "x=%.1f tree=%.1f" % [player.position.x, tree.position.x])
	# leave the player on the dock for the screenshot
	player.position = Vector2(Layout.DOCK_X1 - 90, float(Layout.DOCK_Y0 + Layout.DOCK_Y1) / 2.0)
	await get_tree().create_timer(1.0).timeout
	print("AUTOTEST DONE")
	get_tree().quit()
