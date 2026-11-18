class_name NeighborFace
extends Control
## A simple drawn face for the neighbor dialog (Story 012): skin, hair, hat, eyes and a smile in
## the neighbor's colors from town.json.
##
## Usage:
## [codeblock]
## var face := NeighborFace.new()
## face.setup(town_data.neighbor("ana"))
## [/codeblock]

var _skin: Color = Color.WHITE
var _hair: Color = Color.BLACK
var _hat: Color = Color.RED


func _init() -> void:
	custom_minimum_size = Vector2(96.0, 96.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Takes the colors of neighbor [param n].
func setup(n: Dictionary) -> void:
	_skin = Color.html(str(n["skin"]))
	_hair = Color.html(str(n["hair"]))
	_hat = Color.html(str(n["hat"]))
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5 + Vector2(0.0, 6.0)
	draw_circle(c + Vector2(0, -4), 36.0, _hair)
	draw_circle(c, 32.0, _skin)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-46, -22), c + Vector2(46, -22), c + Vector2(30, -30), c + Vector2(-30, -30)]), _hat.darkened(0.2))
	draw_circle(c + Vector2(0, -34), 22.0, _hat)
	draw_rect(Rect2(c + Vector2(-46, -26), Vector2(92, 6)), _hat.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		draw_circle(c + Vector2(side * 11.0, -2.0), 4.0, Color(0.12, 0.08, 0.06))
		draw_circle(c + Vector2(side * 18.0, 9.0), 5.0, Color(1.0, 0.55, 0.55, 0.5))
	draw_arc(c + Vector2(0, 6), 10.0, 0.3, PI - 0.3, 10, Color(0.4, 0.15, 0.1), 3.0)
