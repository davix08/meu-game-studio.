class_name WorldLook
extends RefCounted
## Visual and performance tuning for the 3D world, loaded from src/data/world_look.json.
##
## Implements the "values in data" rule for Story 002 (design/game-brief.md, MVP feature 9):
## colors, sizes, camera, light and counts live in the JSON, never in the logic. The JSON is a
## map of groups (objects) of values; read them with [method num], [method color] and friends.
##
## Usage:
## [codeblock]
## var look := WorldLook.load_file()
## var distance: float = look.num("camera", "distance")
## var grass: Color = look.color("colors", "grass_a")
## [/codeblock]

## Default location of the data file.
const DEFAULT_PATH: String = "res://src/data/world_look.json"

var _data: Dictionary = {}


## Loads and parses [param path]. Returns null (after pushing an error) when the file is
## missing or is not a JSON object.
static func load_file(path: String = DEFAULT_PATH) -> WorldLook:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("WorldLook: %s is missing or is not a JSON object" % path)
		return null
	var look := WorldLook.new()
	look._data = parsed
	return look


## A number from [param group].[param key].
func num(group: String, key: String) -> float:
	return float(_value(group, key))


## An integer from [param group].[param key] (also used for 0/1 switches).
func integer(group: String, key: String) -> int:
	return int(_value(group, key))


## A color from [param group].[param key], written as a hex string ("#rrggbb" or "#rrggbbaa").
func color(group: String, key: String) -> Color:
	return Color.html(str(_value(group, key)))


## A list of colors from [param group].[param key] (an array of hex strings).
func color_list(group: String, key: String) -> Array[Color]:
	var out: Array[Color] = []
	var entries: Array = _value(group, key)
	for entry: Variant in entries:
		out.append(Color.html(str(entry)))
	return out


## A string from [param group].[param key].
func text(group: String, key: String) -> String:
	return str(_value(group, key))


func _value(group: String, key: String) -> Variant:
	var entries: Dictionary = _data[group]
	return entries[key]
