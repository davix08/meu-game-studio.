extends Node2D
## Placeholder art for the Vigia Petrificado, drawn with primitives.
## A towering stone sentinel with a rune-carved shield and one glowing eye.

const STONE := Color(0.55, 0.52, 0.5)
const STONE_DARK := Color(0.36, 0.34, 0.33)
const RUNE := Color(0.45, 0.85, 0.95)

## 0..1, how bright the runes are (telegraphs an attack).
var glow: float = 0.0
## Number of cracks to draw (grows with each phase).
var cracks: int = 0


func _draw() -> void:
	var rune := RUNE.lerp(Color.WHITE, glow * 0.6)
	# Legs and body.
	draw_rect(Rect2(-90, -120, 60, 120), STONE_DARK)
	draw_rect(Rect2(30, -120, 60, 120), STONE_DARK)
	draw_rect(Rect2(-120, -320, 240, 210), STONE)
	# Head with a single eye slit.
	draw_rect(Rect2(-60, -400, 120, 90), STONE)
	draw_rect(Rect2(-40, -365, 80, 12), rune)
	# Shield arm (front).
	var shield := PackedVector2Array([Vector2(-170, -300), Vector2(-90, -300), Vector2(-90, -150), Vector2(-130, -110), Vector2(-170, -150)])
	draw_colored_polygon(shield, STONE_DARK)
	draw_line(Vector2(-130, -280), Vector2(-130, -140), rune, 4.0 + glow * 4.0)
	draw_line(Vector2(-155, -230), Vector2(-105, -230), rune, 4.0 + glow * 4.0)
	# Chest rune.
	draw_circle(Vector2(0, -220), 22.0 + glow * 8.0, rune)
	# Cracks per phase.
	for i: int in cracks:
		var x := -80.0 + 60.0 * i
		draw_polyline(PackedVector2Array([Vector2(x, -320), Vector2(x + 18, -270), Vector2(x - 6, -230), Vector2(x + 12, -180)]), Color.BLACK, 3.0)
