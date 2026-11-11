class_name SaveGame
extends RefCounted
## Saving and loading the [GameState] as JSON in user://, format version 2.
##
## Keeps the same fields as the 2D save (coins, level, day, minutes, energy, bag,
## book, rods_owned, rod, baits_owned, bait, snacks, luck_baits, luck_left, map,
## stats, plus the player position and facing), in snake_case. A version 1 save
## from the 2D prototype (its localStorage JSON text, camelCase, with px, py, dir
## and v: 1) is converted on load by [method convert_v1].
## When to save (after a catch, a sale, on a timer) is the caller's choice.
## Single-thread: do not save and load the same path concurrently.
##
## Usage:
## [codeblock]
## SaveGame.write(state)                       # user://lakebound_save.json
## var state := GameState.create_new(data)
## SaveGame.apply(state, data, SaveGame.read())  # an empty dict leaves a new game
## [/codeblock]

## Version written by this class.
const FORMAT_VERSION: int = 2
## Version of the 2D prototype's save ("v": 1).
const V1_VERSION: int = 1
## Default save file.
const DEFAULT_PATH: String = "user://lakebound_save.json"


## The save dictionary (format 2) for [param state].
static func to_dict(state: GameState) -> Dictionary:
	var bag: Array[Dictionary] = []
	for fish: GameState.Catch in state.bag:
		bag.append({"id": fish.id, "weight": fish.weight, "value": fish.value})
	var book: Dictionary = {}
	for id: String in state.book:
		var entry: GameState.BookEntry = state.book[id]
		book[id] = {"count": entry.count, "best": entry.best}
	return {
		"version": FORMAT_VERSION,
		"coins": state.coins,
		"level": state.level,
		"day": state.day,
		"minutes": state.minutes,
		"energy": state.energy,
		"bag": bag,
		"book": book,
		"rods_owned": Array(state.rods_owned),
		"rod": state.rod,
		"baits_owned": Array(state.baits_owned),
		"bait": state.bait,
		"snacks": state.snacks,
		"luck_baits": state.luck_baits,
		"luck_left": state.luck_left,
		"map": state.map,
		"stats": {"caught": state.stats_caught, "earned": state.stats_earned},
		"pos": [state.position.x, state.position.y, state.position.z],
		"dir": state.dir,
	}


## Writes [param state] to [param path]. Returns false when the file cannot be written.
static func write(state: GameState, path: String = DEFAULT_PATH) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	var ok: bool = file.store_string(JSON.stringify(to_dict(state), "\t"))
	file.close()
	return ok


## Reads the save at [param path] as a format 2 dictionary, converting a v1 save.
## Returns an empty dictionary when there is no save or it is unreadable.
static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("SaveGame: %s is not a JSON object; ignored" % path)
		return {}
	var save: Dictionary = parsed
	if save.has("version") and int(_number(save, "version", 0)) == FORMAT_VERSION:
		return save
	if not save.has("version") and int(_number(save, "v", 0)) == V1_VERSION:
		return convert_v1(save)
	push_warning("SaveGame: %s has an unknown version; ignored" % path)
	return {}


## Converts a 2D prototype save (v1: camelCase, bag {id, w, v}, book {n, best},
## px/py in 2D pixels) to format 2. px, py become pos [px, 0, py] without
## rescaling (the 3D world story rescales). Only the keys present are carried over.
##
## [codeblock]
## var v2: Dictionary = SaveGame.convert_v1(JSON.parse_string(local_storage_text))
## [/codeblock]
static func convert_v1(v1: Dictionary) -> Dictionary:
	var renames: Dictionary[String, String] = {
		"coins": "coins", "level": "level", "day": "day", "minutes": "minutes",
		"energy": "energy", "rodsOwned": "rods_owned", "rod": "rod",
		"baitsOwned": "baits_owned", "bait": "bait", "snacks": "snacks",
		"luckBaits": "luck_baits", "luckLeft": "luck_left", "map": "map",
		"stats": "stats", "dir": "dir",
	}
	var out: Dictionary = {"version": FORMAT_VERSION}
	for old_key: String in renames:
		if v1.has(old_key):
			out[renames[old_key]] = v1[old_key]
	if v1.get("bag") is Array:
		var bag: Array[Dictionary] = []
		for fish: Variant in v1["bag"]:
			if fish is Dictionary:
				var f: Dictionary = fish
				bag.append({"id": f.get("id"), "weight": f.get("w"), "value": f.get("v")})
		out["bag"] = bag
	if v1.get("book") is Dictionary:
		var book: Dictionary = {}
		var old_book: Dictionary = v1["book"]
		for id: Variant in old_book:
			if old_book[id] is Dictionary:
				var entry: Dictionary = old_book[id]
				book[id] = {"count": entry.get("n"), "best": entry.get("best")}
		out["book"] = book
	if v1.has("px") and v1.has("py"):
		out["pos"] = [v1["px"], 0.0, v1["py"]]
	return out


## Copies a format 2 [param save] into [param state]. Missing or malformed
## fields, and ids unknown to [param data], keep the state's current values
## (a new game's, when [param state] comes from [method GameState.create_new]).
static func apply(state: GameState, data: GameData, save: Dictionary) -> void:
	if save.is_empty():
		return
	state.coins = int(_number(save, "coins", state.coins))
	state.level = clampi(int(_number(save, "level", state.level)), 1, data.max_level())
	state.day = int(_number(save, "day", state.day))
	state.minutes = _number(save, "minutes", state.minutes)
	state.energy = clampf(_number(save, "energy", state.energy), 0.0, data.fixed("energy_max"))
	state.snacks = int(_number(save, "snacks", state.snacks))
	state.luck_baits = int(_number(save, "luck_baits", state.luck_baits))
	state.luck_left = _number(save, "luck_left", state.luck_left)
	state.dir = int(_number(save, "dir", 0))
	var map: String = str(save.get("map", "")) if save.get("map") is String else ""
	if map == GameState.MAP_OUTDOOR or map == GameState.MAP_INDOOR:
		state.map = map
	if save.get("bag") is Array:
		_apply_bag(state, data, save["bag"])
	if save.get("book") is Dictionary:
		_apply_book(state, data, save["book"])
	if save.get("rods_owned") is Array:
		state.rods_owned = _known_ids(save["rods_owned"], data.has_rod, state.rods_owned)
	if save.get("baits_owned") is Array:
		state.baits_owned = _known_ids(save["baits_owned"], data.has_bait, state.baits_owned)
	var rod: String = str(save.get("rod", ""))
	if state.rods_owned.has(rod):
		state.rod = rod
	var bait: String = str(save.get("bait", ""))
	if state.baits_owned.has(bait):
		state.bait = bait
	if save.get("stats") is Dictionary:
		var stats: Dictionary = save["stats"]
		state.stats_caught = int(_number(stats, "caught", state.stats_caught))
		state.stats_earned = int(_number(stats, "earned", state.stats_earned))
	if save.get("pos") is Array and (save["pos"] as Array).size() == 3:
		var pos: Array = save["pos"]
		if _is_number(pos[0]) and _is_number(pos[1]) and _is_number(pos[2]):
			state.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))


static func _apply_bag(state: GameState, data: GameData, bag: Array) -> void:
	state.bag.clear()
	for entry: Variant in bag:
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		if not (data.has_species(str(e.get("id", ""))) and _is_number(e.get("weight")) and _is_number(e.get("value"))):
			push_warning("SaveGame: dropped an unreadable bag entry")
			continue
		var fish := GameState.Catch.new()
		fish.id = str(e["id"])
		fish.weight = float(e["weight"])
		fish.value = int(e["value"])
		state.bag.append(fish)


static func _apply_book(state: GameState, data: GameData, book: Dictionary) -> void:
	state.book.clear()
	for id: Variant in book:
		var value: Variant = book[id]
		if not (data.has_species(str(id)) and value is Dictionary):
			push_warning("SaveGame: dropped an unreadable book entry")
			continue
		var e: Dictionary = value
		var entry := GameState.BookEntry.new()
		entry.count = int(_number(e, "count", 1))
		entry.best = _number(e, "best", 0.0)
		state.book[str(id)] = entry


static func _known_ids(ids: Array, is_known: Callable, fallback: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for id: Variant in ids:
		if is_known.call(str(id)):
			out.append(str(id))
	return out if not out.is_empty() else fallback


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _number(save: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = save.get(key)
	if _is_number(value):
		return float(value)
	if value != null:
		push_warning("SaveGame: field \"%s\" is not a number; kept the default" % key)
	return fallback
