class_name SaveGame
extends RefCounted
## Saving and loading the [GameState] as JSON in user://, format version 3.
##
## Format 3 (Stories 008-018) adds the town (warehouse, rod levels, goods, requests, plots,
## animals, troughs, pending products, clothes, lots, city level and scores, restaurant stock,
## neighbor walkers) and the settings. A format 2 save loads too: its position was on the
## 48x34 map and is moved by [constant WorldGrid.ORIGIN] onto the bigger map.
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
const FORMAT_VERSION: int = 4
## Format 3 (the village map), still read: the player goes back to the farm house.
const V3_VERSION: int = 3
## Previous format (before the town), still read.
const V2_VERSION: int = 2
## Version of the 2D prototype's save ("v": 1).
const V1_VERSION: int = 1
## Default save file.
const DEFAULT_PATH: String = "user://lakebound_save.json"


## The save dictionary (format 2) for [param state].
static func to_dict(state: GameState) -> Dictionary:
	var bag: Array[Dictionary] = _fish_list(state.bag)
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
		"storage": _fish_list(state.storage),
		"storage_upgrades": state.storage_upgrades,
		"rod_levels": state.rod_levels.duplicate(),
		"goods": state.goods.duplicate(),
		"requests": state.requests.duplicate(true),
		"plots": state.plots.duplicate(true),
		"garden_bait_left": state.garden_bait_left,
		"animals": state.animals.duplicate(true),
		"troughs": state.troughs.duplicate(),
		"pending": state.pending.duplicate(true),
		"clothes_owned": Array(state.clothes_owned),
		"outfit": state.outfit.duplicate(),
		"lots_built": Array(state.lots_built),
		"city_level": state.city_level,
		"request_score": state.request_score,
		"food_score": state.food_score,
		"dishes": state.dishes.duplicate(true),
		"drinks": state.drinks,
		"sales_today": state.sales_today,
		"meals_wanted": state.meals_wanted,
		"meals_served": state.meals_served,
		"npcs": state.npcs.duplicate(true),
		"farm_xp": state.farm_xp,
		"shed": state.shed.duplicate(),
		"orders": state.orders.duplicate(true),
		"boxes": state.boxes.duplicate(true),
		"chopped": state.chopped.duplicate(),
		"milker": state.milker,
		"rod_out": state.rod_out,
		"crop_plots": state.crop_plots.duplicate(true),
		"prod_started": state.prod_started,
		"storage_levels": state.storage_levels.duplicate(),
		"factories": state.factories.duplicate(true),
		"order_board": state.order_board.duplicate(true),
		"stall": state.stall.duplicate(true),
		"expanded": Array(state.expanded),
		"tools": Array(state.tools),
		"placed": state.placed.duplicate(true),
		"sound_on": state.sound_on,
		"fps_on": state.show_fps,
		"graphics_light": state.graphics_light,
	}


static func _fish_list(fish_list: Array[GameState.Catch]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for fish: GameState.Catch in fish_list:
		out.append({"id": fish.id, "weight": fish.weight, "value": fish.value})
	return out


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
	if save.has("version") and int(_number(save, "version", 0)) == V3_VERSION:
		return convert_v3(save)
	if save.has("version") and int(_number(save, "version", 0)) == V2_VERSION:
		return convert_v3(convert_v2(save))
	if not save.has("version") and int(_number(save, "v", 0)) == V1_VERSION:
		return convert_v3(convert_v1(save))
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
	out["version"] = V2_VERSION
	return convert_v2(out)


## Converts a format 3 save (village map) to format 4 (farm map): same progress, but the
## position and the neighbor walkers are dropped, so the farmer starts at the house.
static func convert_v3(v3: Dictionary) -> Dictionary:
	var out: Dictionary = v3.duplicate(true)
	out["version"] = FORMAT_VERSION
	out.erase("pos")
	out.erase("npcs")
	return out


## Converts a format 2 save: same fields, the position moved onto the bigger map (Story 009).
static func convert_v2(v2: Dictionary) -> Dictionary:
	var out: Dictionary = v2.duplicate(true)
	out["version"] = V3_VERSION
	if out.get("pos") is Array and (out["pos"] as Array).size() == 3:
		var pos: Array = out["pos"]
		if _is_number(pos[0]) and _is_number(pos[2]):
			pos[0] = float(pos[0]) + float(WorldGrid.ORIGIN.x) * WorldGrid.PIXELS_PER_BLOCK
			pos[2] = float(pos[2]) + float(WorldGrid.ORIGIN.y) * WorldGrid.PIXELS_PER_BLOCK
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
	if map == GameState.MAP_OUTDOOR or map == GameState.MAP_INDOOR or map == GameState.MAP_BARN:
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
	_apply_town(state, data, save)


static func _apply_town(state: GameState, data: GameData, save: Dictionary) -> void:
	if save.get("storage") is Array:
		var holder := GameState.new()
		_apply_bag(holder, data, save["storage"])
		state.storage = holder.bag
	state.storage_upgrades = int(_number(save, "storage_upgrades", state.storage_upgrades))
	if save.get("rod_levels") is Dictionary:
		var levels: Dictionary = save["rod_levels"]
		for id: Variant in levels:
			if data.has_rod(str(id)) and _is_number(levels[id]):
				state.rod_levels[str(id)] = int(levels[id])
	if save.get("goods") is Dictionary:
		var goods: Dictionary = save["goods"]
		for id: Variant in goods:
			if _is_number(goods[id]):
				state.goods[str(id)] = int(goods[id])
	if save.get("requests") is Dictionary:
		state.requests = (save["requests"] as Dictionary).duplicate(true)
	if save.get("plots") is Array:
		state.plots.clear()
		for p: Variant in save["plots"]:
			if p is Dictionary:
				var plot: Dictionary = p
				state.plots.append({"crop": str(plot.get("crop", "")), "days": int(_number(plot, "days", 0)), "watered": bool(plot.get("watered", false))})
	state.garden_bait_left = _number(save, "garden_bait_left", state.garden_bait_left)
	if save.get("animals") is Array:
		state.animals.clear()
		for a: Variant in save["animals"]:
			if a is Dictionary:
				var animal: Dictionary = a
				state.animals.append({"kind": str(animal.get("kind", "")), "joy": _number(animal, "joy", 50.0), "age": int(_number(animal, "age", 0)), "milk_ready": bool(animal.get("milk_ready", false))})
	if save.get("troughs") is Dictionary:
		var troughs: Dictionary = save["troughs"]
		for id: Variant in troughs:
			if _is_number(troughs[id]):
				state.troughs[str(id)] = int(troughs[id])
	if save.get("pending") is Dictionary:
		state.pending = (save["pending"] as Dictionary).duplicate(true)
	if save.get("clothes_owned") is Array:
		state.clothes_owned = PackedStringArray(save["clothes_owned"])
	if save.get("outfit") is Dictionary:
		var outfit: Dictionary = save["outfit"]
		for slot: Variant in outfit:
			state.outfit[str(slot)] = str(outfit[slot])
	if save.get("lots_built") is Array:
		state.lots_built = PackedStringArray(save["lots_built"])
	state.city_level = int(_number(save, "city_level", state.city_level))
	state.request_score = _number(save, "request_score", state.request_score)
	state.food_score = _number(save, "food_score", state.food_score)
	if save.get("dishes") is Array:
		state.dishes.clear()
		for d: Variant in save["dishes"]:
			if d is Dictionary:
				var dish: Dictionary = d
				state.dishes.append({"name": str(dish.get("name", "")), "value": int(_number(dish, "value", 0))})
	state.drinks = int(_number(save, "drinks", state.drinks))
	state.sales_today = int(_number(save, "sales_today", state.sales_today))
	state.meals_wanted = int(_number(save, "meals_wanted", state.meals_wanted))
	state.meals_served = int(_number(save, "meals_served", state.meals_served))
	if save.get("npcs") is Dictionary:
		state.npcs = (save["npcs"] as Dictionary).duplicate(true)
	state.farm_xp = int(_number(save, "farm_xp", state.farm_xp))
	if save.get("shed") is Dictionary:
		var shed: Dictionary = save["shed"]
		for id: Variant in shed:
			if _is_number(shed[id]):
				state.shed[str(id)] = int(shed[id])
	for key: String in ["orders", "boxes"]:
		if save.get(key) is Array:
			var list: Array[Dictionary] = state.orders if key == "orders" else state.boxes
			list.clear()
			for o: Variant in save[key]:
				if o is Dictionary and (o as Dictionary).get("items") is Dictionary:
					list.append({"dest": str((o as Dictionary).get("dest", "galpao")), "items": ((o as Dictionary)["items"] as Dictionary).duplicate()})
	if save.get("chopped") is Dictionary:
		state.chopped = (save["chopped"] as Dictionary).duplicate()
	if save.get("milker") is bool:
		state.milker = save["milker"]
	if save.get("rod_out") is bool:
		state.rod_out = save["rod_out"]
	if save.get("crop_plots") is Array:
		state.crop_plots.clear()
		for p: Variant in save["crop_plots"]:
			if p is Dictionary:
				state.crop_plots.append({"crop": str((p as Dictionary).get("crop", "")), "ready_at": _number(p, "ready_at", 0.0)})
	if save.get("prod_started") is bool:
		state.prod_started = save["prod_started"]
	if save.get("storage_levels") is Dictionary:
		state.storage_levels = (save["storage_levels"] as Dictionary).duplicate()
	if save.get("factories") is Dictionary:
		state.factories = (save["factories"] as Dictionary).duplicate(true)
	if save.get("order_board") is Array:
		state.order_board.clear()
		for o: Variant in save["order_board"]:
			if o is Dictionary:
				state.order_board.append((o as Dictionary).duplicate(true))
	if save.get("stall") is Array:
		state.stall = (save["stall"] as Array).duplicate(true)
	if save.get("placed") is Dictionary:
		state.placed = (save["placed"] as Dictionary).duplicate(true)
	if save.get("tools") is Array:
		state.tools = PackedStringArray(save["tools"])
	if save.get("expanded") is Array:
		state.expanded = PackedStringArray(save["expanded"])
	if save.get("sound_on") is bool:
		state.sound_on = save["sound_on"]
	# "fps_on" replaces "show_fps" (2026-11-22): the counter is on for everybody once.
	if save.get("fps_on") is bool:
		state.show_fps = save["fps_on"]
	if save.get("graphics_light") is bool:
		state.graphics_light = save["graphics_light"]


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
