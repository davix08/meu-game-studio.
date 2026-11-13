# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
extends Node2D

const GRASS := [Color("4f8a3c"), Color("56933f"), Color("4a8238"), Color("5c9a44")]
const SAND := Color("d9c58f")
const SAND_DARK := Color("c4ad74")
const DIRT := Color("9b7651")
const DIRT_DARK := Color("86643f")
const PLANK := Color("8a5a34")
const PLANK_LIGHT := Color("a06b3f")
const PLANK_DARK := Color("5e3b20")

var _rng := RandomNumberGenerator.new()


func _draw() -> void:
	_rng.seed = 7
	# Grass tiles with colour variation.
	for ty in Layout.H / 16:
		for tx in Layout.W / 16:
			var x := tx * 16
			if x >= Layout.shore_x(ty * 16 + 8) - 34:
				continue
			draw_rect(Rect2(x, ty * 16, 16, 16), GRASS[_rng.randi() % GRASS.size()])
	# Sand strip and shoreline, 4 px rows.
	for y in range(0, Layout.H, 4):
		var sx := floorf(Layout.shore_x(y + 2) / 2.0) * 2.0
		draw_rect(Rect2(sx - 34, y, 34, 4), SAND)
		draw_rect(Rect2(sx - 34, y, 3, 4), SAND_DARK)
	# Dirt path.
	for p in Layout.path_points():
		draw_circle(p, 13.0, DIRT_DARK)
	for p in Layout.path_points():
		draw_circle(p, 11.0, DIRT)
	# Grass tufts and flowers.
	for i in 420:
		var p := Vector2(_rng.randf_range(8, 780), _rng.randf_range(8, Layout.H - 8))
		if p.x > Layout.shore_x(p.y) - 40 or Layout.dist_to_path(p) < 16:
			continue
		if _rng.randf() < 0.8:
			draw_rect(Rect2(p, Vector2(1, 3)), Color("3d6e2e"))
			draw_rect(Rect2(p + Vector2(2, -1), Vector2(1, 4)), Color("3d6e2e"))
		else:
			var fc: Color = [Color("f2e36b"), Color("f08fb0"), Color("ffffff")][_rng.randi() % 3]
			draw_rect(Rect2(p, Vector2(2, 2)), fc)
	_draw_dock()


func _draw_dock() -> void:
	var x0 := Layout.dock_x0()
	var len := Layout.DOCK_X1 - x0
	# posts
	for i in range(0, int(len) + 1, 48):
		draw_rect(Rect2(x0 + i, Layout.DOCK_Y0 - 3, 5, 6), PLANK_DARK)
		draw_rect(Rect2(x0 + i, Layout.DOCK_Y1 - 2, 5, 7), PLANK_DARK)
	draw_rect(Rect2(x0, Layout.DOCK_Y0, len, Layout.DOCK_Y1 - Layout.DOCK_Y0 + 3), PLANK_DARK)
	for i in range(0, int(len), 8):
		var c := PLANK if (i / 8) % 2 == 0 else PLANK_LIGHT
		draw_rect(Rect2(x0 + i, Layout.DOCK_Y0, 7, Layout.DOCK_Y1 - Layout.DOCK_Y0), c)
		draw_rect(Rect2(x0 + i + 3, Layout.DOCK_Y0 + 6, 1, 1), PLANK_DARK)
		draw_rect(Rect2(x0 + i + 3, Layout.DOCK_Y1 - 7, 1, 1), PLANK_DARK)
