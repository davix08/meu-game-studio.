class_name TownData
extends RefCounted
## The town values (src/data/town.json): storage, rod workshop, neighbors and their requests and
## routine, restaurant, farm, ranch, goods, clothes and the city lots and levels.
##
## Read-only after loading. Groups are kept as dictionaries and read with [method num],
## [method text] and [method list]; the lists that the systems look up by id (goods, crops,
## animals, clothes, lots, neighbors) get indexed accessors. Every number from JSON is a float,
## so callers convert with int() where they need a count.
##
## Stories 010-018 (design/game-brief.md, Your systems).
##
## Usage:
## [codeblock]
## var town := TownData.load_file()
## var cost: int = int(town.num("storage", "upgrade_step"))
## var egg: Dictionary = town.good("ovo")
## [/codeblock]

## Default location of the data file.
const DEFAULT_PATH: String = "res://src/data/town.json"

var _data: Dictionary = {}
var _goods: Dictionary = {}
var _crops: Dictionary = {}
var _animals: Dictionary = {}
var _lots: Dictionary = {}
var _neighbors: Dictionary = {}
var _clothes: Dictionary = {}


## Loads [param path]; returns null (after an error) when it is missing or not an object.
static func load_file(path: String = DEFAULT_PATH) -> TownData:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("TownData: %s is missing or is not a JSON object" % path)
		return null
	var town := TownData.new()
	town._data = parsed
	town._index("goods", town._goods, town._data)
	town._index("crops", town._crops, town.group("farm"))
	town._index("animals", town._animals, town.group("ranch"))
	town._index("lots", town._lots, town.group("city"))
	town._index("neighbors", town._neighbors, town._data)
	var clothes: Dictionary = town.group("clothes")
	for slot: String in clothes:
		for entry: Variant in clothes[slot]:
			var e: Dictionary = entry
			town._clothes[str(e["id"])] = e
	return town


## One group of the file (an object).
func group(name: String) -> Dictionary:
	return _data[name]


## A number from [param group_name].[param key].
func num(group_name: String, key: String) -> float:
	return float(group(group_name)[key])


## A string from [param group_name].[param key].
func text(group_name: String, key: String) -> String:
	return str(group(group_name)[key])


## An array from [param group_name].[param key].
func list(group_name: String, key: String) -> Array:
	return group(group_name)[key]


## The goods, in file order (each a dictionary with id, name, sell, price, color).
func goods() -> Array:
	return _data["goods"]


## A good by id, or an empty dictionary.
func good(id: String) -> Dictionary:
	return _goods.get(id, {})


## Display name of a good (or the id when unknown).
func good_name(id: String) -> String:
	return str(good(id).get("name", id))


## The crops, in file order.
func crops() -> Array:
	return list("farm", "crops")


## A crop by id, or an empty dictionary.
func crop(id: String) -> Dictionary:
	return _crops.get(id, {})


## The animals, in file order.
func animals() -> Array:
	return list("ranch", "animals")


## An animal kind by id, or an empty dictionary.
func animal(id: String) -> Dictionary:
	return _animals.get(id, {})


## The ranch homes (galinheiro, pasto).
func homes() -> Array:
	return list("ranch", "homes")


## The city lots, in file order.
func lots() -> Array:
	return list("city", "lots")


## A lot by id, or an empty dictionary.
func lot(id: String) -> Dictionary:
	return _lots.get(id, {})


## The neighbors, in file order.
func neighbors() -> Array:
	return _data["neighbors"]


## A neighbor by id, or an empty dictionary.
func neighbor(id: String) -> Dictionary:
	return _neighbors.get(id, {})


## The clothes of [param slot] ("hat", "shirt" or "boots").
func clothes(slot: String) -> Array:
	return group("clothes")[slot]


## A clothing piece by id, or an empty dictionary.
func piece(id: String) -> Dictionary:
	return _clothes.get(id, {})


## The city levels (index 0 is level 1).
func city_levels() -> Array:
	return list("city", "levels")


func _index(key: String, into: Dictionary, source: Dictionary) -> void:
	for entry: Variant in source[key]:
		var e: Dictionary = entry
		into[str(e["id"])] = e
