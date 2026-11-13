# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
# Date: 2026-11-13
class_name Layout
extends RefCounted

const W := 1280
const H := 768
const DOCK_Y0 := 360
const DOCK_Y1 := 392
const DOCK_X1 := 1060
const SPAWN := Vector2(220, 520)


static func shore_x(y: float) -> float:
	return 820.0 + 18.0 * sin(y * 0.02) + 10.0 * sin(y * 0.053)


static func dock_x0() -> float:
	return shore_x(float(DOCK_Y0 + DOCK_Y1) * 0.5) - 24.0


## Points along the dirt path from spawn to the dock.
static func path_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var a := SPAWN
	var c := Vector2(480, 600)
	var b := Vector2(dock_x0() + 6.0, float(DOCK_Y0 + DOCK_Y1) * 0.5)
	for i in 61:
		var t := float(i) / 60.0
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts


static func dist_to_path(p: Vector2) -> float:
	var best := INF
	for q in path_points():
		best = minf(best, p.distance_to(q))
	return best
