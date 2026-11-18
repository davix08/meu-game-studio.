# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
# Date: 2026-11-18
# Static backdrop: shore, grass, dock. Water is a shader ColorRect behind it.
extends Node2D

const SHORE_Y := 262.0
const DOCK_X0 := 296.0
const DOCK_X1 := 344.0
const DOCK_TOP := 150.0

var _t := 0.0


static func shore_y(x: float) -> float:
	return SHORE_Y + 6.0 * sin(x * 0.03) + 3.0 * sin(x * 0.11)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# sand + grass, per 4 px column
	for x in range(-80, 760, 4):
		var sy := floorf(shore_y(x) / 2.0) * 2.0
		draw_rect(Rect2(x, sy, 4, 26), Color("d9c58f"))
		draw_rect(Rect2(x, sy + 22, 4, 4), Color("c4ad74"))
		draw_rect(Rect2(x, sy + 26, 4, 140), Color("4f8a3c"))
		# foam lapping
		var lap := floorf((2.0 + 2.0 * sin(_t * 1.6 + x * 0.09)) / 2.0) * 2.0
		draw_rect(Rect2(x, sy - 2 - lap, 4, 2 + lap), Color(0.93, 0.97, 1.0, 0.8))
	for i in 160:
		var p := Vector2(rng.randf_range(-80, 760), rng.randf_range(300, 400))
		draw_rect(Rect2(p, Vector2(1, 3)), Color("3d6e2e"))
		if rng.randf() < 0.15:
			draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 2)), Color("f2e36b"))
	# dock (vertical, into the water)
	draw_rect(Rect2(DOCK_X0 - 2, DOCK_TOP - 2, DOCK_X1 - DOCK_X0 + 4, 200), Color("5e3b20"))
	for y in range(int(DOCK_TOP), 360, 7):
		var c := Color("8a5a34") if (y / 7) % 2 == 0 else Color("a06b3f")
		draw_rect(Rect2(DOCK_X0, y, DOCK_X1 - DOCK_X0, 6), c)
		draw_rect(Rect2(DOCK_X0 + 6, y + 3, 1, 1), Color("5e3b20"))
		draw_rect(Rect2(DOCK_X1 - 7, y + 3, 1, 1), Color("5e3b20"))
	for y in range(int(DOCK_TOP), 260, 36):
		draw_rect(Rect2(DOCK_X0 - 5, y, 5, 6), Color("4a2e18"))
		draw_rect(Rect2(DOCK_X1, y, 5, 6), Color("4a2e18"))
	# a bucket on the dock
	draw_rect(Rect2(DOCK_X1 - 14, DOCK_TOP + 40, 9, 9), Color("7c8a94"))
	draw_rect(Rect2(DOCK_X1 - 14, DOCK_TOP + 40, 9, 2), Color("aab6be"))
