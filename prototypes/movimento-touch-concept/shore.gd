# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
# Animated foam along the shoreline.
extends Node2D

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for y in range(0, Layout.H, 4):
		if y >= Layout.DOCK_Y0 - 2 and y < Layout.DOCK_Y1 + 4:
			continue
		var sx := floorf(Layout.shore_x(y + 2) / 2.0) * 2.0
		var lap := floorf((2.5 + 2.5 * sin(_t * 1.6 + y * 0.09)) / 2.0) * 2.0
		draw_rect(Rect2(sx, y, 2 + lap, 4), Color(0.93, 0.97, 1.0, 0.85))
		draw_rect(Rect2(sx + 4 + lap, y, 2, 4), Color(0.93, 0.97, 1.0, 0.35))
