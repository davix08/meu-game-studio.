# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
# Tree / rock / bush. Origin is at the base (feet) so y-sort works.
extends StaticBody2D

var kind := "tree"
var variant := 0


func setup(k: String, v: int) -> void:
	kind = k
	variant = v
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	match kind:
		"tree":
			circle.radius = 6.0
		"rock":
			circle.radius = 7.0 + variant
		_:
			circle.radius = 5.0
	shape.shape = circle
	add_child(shape)


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
	draw_circle(Vector2.ZERO, r.x, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	match kind:
		"tree":
			_ellipse(Vector2(2, 1), Vector2(15, 5), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(-3, -14, 6, 15), Color("6b4428"))
			draw_rect(Rect2(-3, -14, 2, 15), Color("845634"))
			var dark := Color("2e5e2a") if variant % 2 == 0 else Color("2f5a33")
			draw_circle(Vector2(0, -26), 15, dark)
			draw_circle(Vector2(-6, -30), 10, Color("3c7a34"))
			draw_circle(Vector2(6, -28), 10, Color("3c7a34"))
			draw_circle(Vector2(-2, -34), 8, Color("4f9640"))
			draw_rect(Rect2(-6, -38, 3, 2), Color("6fb352"))
			draw_rect(Rect2(3, -33, 2, 2), Color("6fb352"))
		"rock":
			var s := 1.0 + variant * 0.25
			_ellipse(Vector2(1, 1), Vector2(10 * s, 4 * s), Color(0, 0, 0, 0.25))
			_ellipse(Vector2(0, -4 * s), Vector2(9 * s, 7 * s), Color("6d7178"))
			_ellipse(Vector2(-1, -6 * s), Vector2(7 * s, 5 * s), Color("8a8f96"))
			draw_rect(Rect2(-4 * s, -9 * s, 3, 2), Color("aeb3b9"))
		_:
			_ellipse(Vector2(1, 1), Vector2(10, 3), Color(0, 0, 0, 0.22))
			draw_circle(Vector2(-4, -5), 6, Color("3a7031"))
			draw_circle(Vector2(4, -5), 6, Color("3a7031"))
			draw_circle(Vector2(0, -8), 6, Color("4c8a3d"))
			if variant % 3 == 0:
				draw_rect(Rect2(-3, -9, 2, 2), Color("d84a4a"))
				draw_rect(Rect2(3, -6, 2, 2), Color("d84a4a"))
