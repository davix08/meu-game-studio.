class_name FishArt
extends RefCounted
## The pixel art of each fish species (assets/fish/fish_NN.png, cut from the sheet the user sent
## on 2026-11-19): which picture and which color tint each species uses, from
## src/data/fish_art.json. The pictures face left. Textures are loaded once and shared.
##
## Usage:
## [codeblock]
## var tex: Texture2D = FishArt.texture("tilapia")
## var tint: Color = FishArt.tint("tilapia")
## [/codeblock]

const DATA_PATH: String = "res://src/data/fish_art.json"

static var _data: Dictionary = {}
static var _textures: Dictionary = {}


static func _load() -> void:
	if not _data.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if parsed is Dictionary:
		_data = parsed


## The picture of species [param id], or null when the art is missing.
static func texture(id: String) -> Texture2D:
	_load()
	var species: Dictionary = _data.get("species", {})
	if not species.has(id):
		return null
	var n: int = int((species[id] as Dictionary)["sprite"])
	if not _textures.has(n):
		var path: String = str(_data["path"]) % n
		_textures[n] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[n]


## The color the picture of species [param id] is multiplied by.
static func tint(id: String) -> Color:
	_load()
	var species: Dictionary = _data.get("species", {})
	if not species.has(id):
		return Color.WHITE
	return Color.html(str((species[id] as Dictionary)["tint"]))


## Draws the picture of [param id] on [param canvas] inside [param rect], keeping its shape,
## facing right when [param face_right]; [param silhouette] draws it as a dark shape.
## Returns false when there is no picture (the caller draws its own fish).
static func draw(canvas: CanvasItem, id: String, rect: Rect2, face_right: bool, silhouette: bool) -> bool:
	var tex: Texture2D = texture(id)
	if tex == null:
		return false
	var tex_size: Vector2 = tex.get_size()
	var k: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size: Vector2 = tex_size * k
	var center: Vector2 = rect.get_center()
	var color: Color = Color(0.2, 0.17, 0.15, 0.9) if silhouette else tint(id)
	var flip: bool = face_right == bool(_data.get("faces_left", true))
	canvas.draw_set_transform(center, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	canvas.draw_texture_rect(tex, Rect2(-draw_size * 0.5, draw_size), false, color)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true
