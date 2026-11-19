class_name FishIcon
extends Control
## A small fish drawing for the shop, bag and book (Story 007): body, tail, fin and eye in a
## color made from the species id, with a ring in the rarity color; undiscovered species are a
## dark silhouette with a "?". Also draws rods, baits and goods as simple colored shapes.
## No emoji, no textures: drawn with [method CanvasItem.draw_colored_polygon].
##
## Usage:
## [codeblock]
## var icon := FishIcon.new()
## icon.setup_fish("tilapia", Color.html("#5ab0f0"), true)
## row.add_child(icon)
## [/codeblock]

## What the icon shows.
enum Kind { FISH, ROD, BAIT, GOOD }

var _kind: Kind = Kind.FISH
var _body: Color = Color.WHITE
var _ring: Color = Color.WHITE
var _known: bool = true
var _id: String = ""
## Draws the ring and the light disc behind the fish (off in the fish book grid).
var framed: bool = true


func _init() -> void:
	custom_minimum_size = Vector2(64.0, 52.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## A fish of species [param id]; [param rarity_color] rings it; [param known] false = silhouette.
func setup_fish(id: String, rarity_color: Color, known: bool) -> void:
	_kind = Kind.FISH
	_id = id
	var h: float = float(absi(hash(id)) % 1000) / 1000.0
	_body = Color.from_hsv(h, 0.45, 0.85)
	_ring = rarity_color
	_known = known
	queue_redraw()


## Another item: [param kind] with its [param color].
func setup_item(kind: Kind, color: Color) -> void:
	_kind = kind
	_body = color
	_ring = color.darkened(0.4)
	_known = true
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	if framed:
		draw_circle(c, minf(size.x, size.y) * 0.48, Color(1, 1, 1, 0.35))
		draw_arc(c, minf(size.x, size.y) * 0.48, 0.0, TAU, 32, _ring, 3.0, true)
	if _kind == Kind.FISH and FishArt.draw(self, _id, Rect2(size * 0.08, size * 0.84), false, not _known):
		return
	match _kind:
		Kind.FISH:
			_draw_fish(c)
		Kind.ROD:
			draw_line(c + Vector2(-18, 16), c + Vector2(18, -16), _body, 5.0, true)
			draw_line(c + Vector2(18, -16), c + Vector2(20, 12), Color(1, 1, 1, 0.8), 1.5, true)
			draw_circle(c + Vector2(20, 13), 4.0, Color(0.9, 0.2, 0.15))
		Kind.BAIT:
			draw_circle(c, 9.0, _body)
			draw_arc(c + Vector2(0, -10), 6.0, PI, TAU, 10, Color(0.5, 0.5, 0.55), 2.0)
		Kind.GOOD:
			draw_circle(c + Vector2(0, 2), 12.0, _body)
			draw_circle(c + Vector2(-4, -2), 4.0, _body.lightened(0.4))


func _draw_fish(c: Vector2) -> void:
	var body: Color = _body if _known else Color(0.15, 0.12, 0.1, 0.85)
	var dark: Color = body.darkened(0.3)
	var pts := PackedVector2Array()
	for i in 20:
		var a: float = TAU * float(i) / 20.0
		pts.append(c + Vector2(cos(a) * 17.0 - 3.0, sin(a) * 9.0))
	draw_colored_polygon(PackedVector2Array([c + Vector2(10, 0), c + Vector2(22, -10), c + Vector2(22, 10)]), dark)
	draw_colored_polygon(pts, body)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -7), c + Vector2(4, -15), c + Vector2(6, -7)]), dark)
	if _known:
		draw_circle(c + Vector2(-12, -2), 2.6, Color(1, 1, 1))
		draw_circle(c + Vector2(-12.5, -2), 1.4, Color(0.1, 0.08, 0.06))
		draw_arc(c + Vector2(-6, 0), 6.0, -0.9, 0.9, 8, body.lightened(0.3), 1.5)
	else:
		draw_string(ThemeDB.fallback_font, c + Vector2(-7, 8), "?", HORIZONTAL_ALIGNMENT_CENTER, 14.0, 22, Color(1, 1, 1, 0.9))
