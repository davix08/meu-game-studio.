class_name GameData
extends RefCounted
## Read-only game tables and tuning values, loaded from the JSON files in src/data/.
##
## This is the only place gameplay numbers enter the game: logic asks
## [method tune] for a tuning knob and [method fixed] for a value the 2D prototype
## kept constant. Files are validated here, at the border; past this point the
## data is trusted. Safe to read from any thread once loaded (never mutated).
##
## Usage:
## [codeblock]
## var data := GameData.load_from_dir()
## if data == null:
##     return  # an error was already pushed
## var cost: float = data.tune("cast_cost")
## var sardine: GameData.Species = data.species_by_id("sardinha")
## [/codeblock]

## Folder that holds config.json, species.json, rods.json, baits.json, items.json, levels.json.
const DEFAULT_DIR: String = "res://src/data/"


## A fish species (data.js species without the drawing fields).
class Species:
	extends RefCounted
	## Unique id, e.g. "sardinha".
	var id: String = ""
	## Display name.
	var name: String = ""
	## Rarity index, 0 (Comum) .. 4 (Lendário).
	var rarity: int = 0
	## Lightest possible weight in kg.
	var kg_min: float = 0.0
	## Heaviest possible weight in kg.
	var kg_max: float = 0.0
	## Base sale value in coins.
	var base_value: int = 0
	## Capture difficulty 0..1.
	var difficulty: float = 0.0
	## When it bites: "any", "day" or "night".
	var time: String = "any"


## Anything sold in the shop: a price and the level that unlocks it.
class ShopEntry:
	extends RefCounted
	## Unique id.
	var id: String = ""
	## Display name.
	var name: String = ""
	## Price in coins.
	var price: int = 0
	## Player level that unlocks it.
	var level: int = 1
	## UI color as a hex string (kept from the 2D data for the shop screens).
	var color: String = ""


## A fishing rod.
class Rod:
	extends ShopEntry
	## Cast reach, in world units (2D pixels, rescaled by the 3D world story).
	var cast_range: float = 0.0
	## Added to the green zone width.
	var zone: float = 0.0
	## Multiplies the catch progress gain.
	var power: float = 1.0


## A bait.
class Bait:
	extends ShopEntry
	## Multiplies the wait for a bite.
	var wait: float = 1.0
	## Raises the odds of each rarity step.
	var rare: float = 0.0


## A consumable shop item.
class Item:
	extends ShopEntry
	## Short description for the shop.
	var description: String = ""
	## What using it does: "snack" or "luck".
	var effect: String = ""


## Seed for the run's [RandomSource].
var seed_value: int = 1
## All species, in data.js order.
var species: Array[Species] = []
## All rods, in shop order.
var rods: Array[Rod] = []
## All baits, in shop order.
var baits: Array[Bait] = []
## All items, in shop order.
var items: Array[Item] = []
## Level names; index 0 is level 1. Its size is the maximum level.
var level_names: PackedStringArray = PackedStringArray()
## Rarity names; index is the rarity. Its size is the number of rarities.
var rarity_names: PackedStringArray = PackedStringArray()
## Rarity UI colors as hex strings.
var rarity_colors: PackedStringArray = PackedStringArray()
## Tuning key of each rarity's base odds weight, e.g. "w_common".
var rarity_weight_keys: PackedStringArray = PackedStringArray()
## Day periods: start hours, ascending, matched with [member period_names].
var period_hours: PackedFloat32Array = PackedFloat32Array()
## Day period names.
var period_names: PackedStringArray = PackedStringArray()

var _tune: Dictionary[String, float] = {}
var _tune_min: Dictionary[String, float] = {}
var _tune_max: Dictionary[String, float] = {}
var _tune_step: Dictionary[String, float] = {}
var _fixed: Dictionary[String, Variant] = {}
var _species_by_id: Dictionary[String, Species] = {}
var _rods_by_id: Dictionary[String, Rod] = {}
var _baits_by_id: Dictionary[String, Bait] = {}
var _items_by_id: Dictionary[String, Item] = {}


## Loads and validates every data file in [param dir_path].
## Returns null (after push_error) when a file is missing or malformed.
##
## [codeblock]
## var data := GameData.load_from_dir("res://src/data/")
## [/codeblock]
static func load_from_dir(dir_path: String = DEFAULT_DIR) -> GameData:
	var data := GameData.new()
	var ok: bool = data._load_config(_read_json(dir_path.path_join("config.json")))
	ok = ok and data._load_species(_read_json(dir_path.path_join("species.json")))
	ok = ok and data._load_rods(_read_json(dir_path.path_join("rods.json")))
	ok = ok and data._load_baits(_read_json(dir_path.path_join("baits.json")))
	ok = ok and data._load_items(_read_json(dir_path.path_join("items.json")))
	ok = ok and data._load_levels(_read_json(dir_path.path_join("levels.json")))
	return data if ok else null


## Current value of a tuning knob from config.json, e.g. [code]tune("cast_cost")[/code].
func tune(key: String) -> float:
	return _tune[key]


## Lower bound of a tuning knob (for a tweak panel).
func tune_min(key: String) -> float:
	return _tune_min[key]


## Upper bound of a tuning knob (for a tweak panel).
func tune_max(key: String) -> float:
	return _tune_max[key]


## Step of a tuning knob (for a tweak panel).
func tune_step(key: String) -> float:
	return _tune_step[key]


## Changes a tuning knob at runtime, clamped to its min/max. Example:
## [code]data.set_tune("cast_cost", 8.0)[/code]
func set_tune(key: String, value: float) -> void:
	_tune[key] = clampf(value, _tune_min[key], _tune_max[key])


## All tuning keys, in config.json order.
func tune_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(_tune.keys())
	return keys


## A value the 2D kept constant (config.json "fixed"), as a float.
## Example: [code]data.fixed("energy_max")[/code]
func fixed(key: String) -> float:
	return float(_fixed[key])


## A text value from config.json "fixed", e.g. [code]data.fixed_text("start_rod")[/code].
func fixed_text(key: String) -> String:
	return str(_fixed[key])


## The species with [param id]. The id must exist.
func species_by_id(id: String) -> Species:
	return _species_by_id[id]


## The rod with [param id]. The id must exist.
func rod_by_id(id: String) -> Rod:
	return _rods_by_id[id]


## The bait with [param id]. The id must exist.
func bait_by_id(id: String) -> Bait:
	return _baits_by_id[id]


## The item with [param id]. The id must exist.
func item_by_id(id: String) -> Item:
	return _items_by_id[id]


## True when [param id] names a species (used when loading saves).
func has_species(id: String) -> bool:
	return _species_by_id.has(id)


## True when [param id] names a rod (used when loading saves).
func has_rod(id: String) -> bool:
	return _rods_by_id.has(id)


## True when [param id] names a bait (used when loading saves).
func has_bait(id: String) -> bool:
	return _baits_by_id.has(id)


## Highest player level.
func max_level() -> int:
	return level_names.size()


## Highest rarity index.
func max_rarity_index() -> int:
	return rarity_names.size() - 1


# --- Loading (the border: everything is validated here) ---

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameData: missing data file %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("GameData: %s is not valid JSON" % path)
	return parsed


static func _has_keys(entry: Variant, keys: Array[String], file: String) -> bool:
	if not (entry is Dictionary):
		push_error("GameData: %s has an entry that is not an object" % file)
		return false
	var dict: Dictionary = entry
	for key: String in keys:
		if not dict.has(key):
			push_error("GameData: %s entry %s lacks \"%s\"" % [file, str(dict.get("id", "?")), key])
			return false
	return true


static func _is_array(value: Variant, file: String) -> bool:
	if value is Array:
		return true
	if value != null:
		push_error("GameData: %s must be a JSON array" % file)
	return false


func _load_config(json: Variant) -> bool:
	if not _has_keys(json, ["seed", "tune", "fixed", "periods"], "config.json"):
		return false
	var root: Dictionary = json
	if not (root["tune"] is Dictionary and root["fixed"] is Dictionary):
		push_error("GameData: config.json \"tune\" and \"fixed\" must be objects")
		return false
	seed_value = int(root["seed"])
	var tune_root: Dictionary = root["tune"]
	for key: Variant in tune_root:
		var knob: Variant = tune_root[key]
		if not _has_keys(knob, ["value", "min", "max", "step"], "config.json tune." + str(key)):
			return false
		var k: Dictionary = knob
		_tune[str(key)] = float(k["value"])
		_tune_min[str(key)] = float(k["min"])
		_tune_max[str(key)] = float(k["max"])
		_tune_step[str(key)] = float(k["step"])
	var fixed_root: Dictionary = root["fixed"]
	for key: Variant in fixed_root:
		_fixed[str(key)] = fixed_root[key]
	if not _is_array(root["periods"], "config.json periods"):
		return false
	var periods: Array = root["periods"]
	for period: Variant in periods:
		if not _has_keys(period, ["hour", "name"], "config.json periods"):
			return false
		var p: Dictionary = period
		period_hours.append(float(p["hour"]))
		period_names.append(str(p["name"]))
	return true


func _load_species(json: Variant) -> bool:
	if not _is_array(json, "species.json"):
		return false
	var list: Array = json
	for entry: Variant in list:
		if not _has_keys(entry, ["id", "name", "r", "kg", "v", "d", "time"], "species.json"):
			return false
		var e: Dictionary = entry
		if not (e["kg"] is Array and (e["kg"] as Array).size() == 2):
			push_error("GameData: species.json entry %s needs kg [min, max]" % str(e["id"]))
			return false
		var kg: Array = e["kg"]
		var sp := Species.new()
		sp.id = str(e["id"])
		sp.name = str(e["name"])
		sp.rarity = int(e["r"])
		sp.kg_min = float(kg[0])
		sp.kg_max = float(kg[1])
		sp.base_value = int(e["v"])
		sp.difficulty = float(e["d"])
		sp.time = str(e["time"])
		species.append(sp)
		_species_by_id[sp.id] = sp
	return true


func _load_rods(json: Variant) -> bool:
	if not _is_array(json, "rods.json"):
		return false
	var list: Array = json
	for entry: Variant in list:
		if not _has_keys(entry, ["id", "name", "price", "level", "range", "zone", "power", "col"], "rods.json"):
			return false
		var e: Dictionary = entry
		var rod := Rod.new()
		_fill_shop_entry(rod, e)
		rod.cast_range = float(e["range"])
		rod.zone = float(e["zone"])
		rod.power = float(e["power"])
		rods.append(rod)
		_rods_by_id[rod.id] = rod
	return true


func _load_baits(json: Variant) -> bool:
	if not _is_array(json, "baits.json"):
		return false
	var list: Array = json
	for entry: Variant in list:
		if not _has_keys(entry, ["id", "name", "price", "level", "wait", "rare", "col"], "baits.json"):
			return false
		var e: Dictionary = entry
		var bait := Bait.new()
		_fill_shop_entry(bait, e)
		bait.wait = float(e["wait"])
		bait.rare = float(e["rare"])
		baits.append(bait)
		_baits_by_id[bait.id] = bait
	return true


func _load_items(json: Variant) -> bool:
	if not _is_array(json, "items.json"):
		return false
	var list: Array = json
	for entry: Variant in list:
		if not _has_keys(entry, ["id", "name", "price", "level", "desc", "effect"], "items.json"):
			return false
		var e: Dictionary = entry
		var item := Item.new()
		_fill_shop_entry(item, e)
		item.description = str(e["desc"])
		item.effect = str(e["effect"])
		items.append(item)
		_items_by_id[item.id] = item
	return true


func _load_levels(json: Variant) -> bool:
	if not _has_keys(json, ["levels", "rarities"], "levels.json"):
		return false
	var root: Dictionary = json
	var names: Array = root["levels"]
	for level_name: Variant in names:
		level_names.append(str(level_name))
	var rarities: Array = root["rarities"]
	for entry: Variant in rarities:
		if not _has_keys(entry, ["name", "color", "weight_key"], "levels.json rarities"):
			return false
		var e: Dictionary = entry
		rarity_names.append(str(e["name"]))
		rarity_colors.append(str(e["color"]))
		rarity_weight_keys.append(str(e["weight_key"]))
	return true


static func _fill_shop_entry(target: ShopEntry, e: Dictionary) -> void:
	target.id = str(e["id"])
	target.name = str(e["name"])
	target.price = int(e["price"])
	target.level = int(e["level"])
	target.color = str(e.get("col", ""))
