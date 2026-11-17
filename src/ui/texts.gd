class_name Texts
extends RefCounted
## The Portuguese texts of the interface (src/data/texts_pt.json), loaded once and shared.
##
## Usage:
## [codeblock]
## var title: String = Texts.get_text("shop")
## var line: String = Texts.fmt("sold", [120])
## [/codeblock]

const PATH: String = "res://src/data/texts_pt.json"

static var _texts: Dictionary = {}


## The text of [param key] (the key itself when missing).
static func get_text(key: String) -> String:
	if _texts.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_texts = parsed
	return str(_texts.get(key, key))


## The text of [param key] formatted with [param args] (the % operator).
static func fmt(key: String, args: Array) -> String:
	return get_text(key) % args
