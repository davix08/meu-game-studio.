extends Node2D
## Placeholder backdrop for the gate of Vesper: dusk sky, ruined towers, floor.

@export var floor_y: float = 640.0
@export var width: float = 1280.0
@export var height: float = 720.0


func _draw() -> void:
	# Sky bands.
	var bands := [Color(0.16, 0.11, 0.2), Color(0.25, 0.15, 0.24), Color(0.4, 0.22, 0.25)]
	var band_h: float = floor_y / bands.size()
	for i: int in bands.size():
		draw_rect(Rect2(0, band_h * i, width, band_h + 1), bands[i])
	# A pale broken moon.
	draw_circle(Vector2(980, 150), 70, Color(0.92, 0.86, 0.75))
	draw_circle(Vector2(1010, 130), 64, bands[0])
	# Ruined towers.
	var tower := Color(0.1, 0.08, 0.12)
	for t: Vector3 in [Vector3(120, 140, 300), Vector3(360, 90, 220), Vector3(700, 120, 340), Vector3(1150, 100, 260)]:
		draw_rect(Rect2(t.x - t.y * 0.5, floor_y - t.z, t.y, t.z), tower)
		draw_rect(Rect2(t.x - t.y * 0.3, floor_y - t.z - 30, t.y * 0.25, 30), tower)
	# Floor.
	draw_rect(Rect2(0, floor_y, width, height - floor_y), Color(0.2, 0.17, 0.18))
	draw_line(Vector2(0, floor_y), Vector2(width, floor_y), Color(0.45, 0.4, 0.38), 3.0)
