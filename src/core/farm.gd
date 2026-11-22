class_name Farm
extends RefCounted
## The farm rules of the 2026-11-19 map (no drawing): the farm level (experience from fishing,
## cutting trees, breaking rocks, collecting eggs, feeding and milking), the bag's room for items
## and the shed (galpão) that keeps the rest, building the chicken coop and the milking corral
## with wood, stone and coins, phone orders delivered by the truck as boxes, and milking.
## Animals, troughs and products reuse [Town]. Values from town.json ("farm_life"). Not
## thread-safe.
##
## Usage:
## [codeblock]
## var farm := Farm.new(data, town_data, state, town)
## farm.add_xp(farm.xp_for("chop"))
## if farm.order_good("madeira", 10) == Farm.Result.OK:
##     print("o caminhão vai trazer")
## [/codeblock]

## The farm reached [param new_level].
signal farm_level_up(new_level: int)
## A paid order is waiting for the truck.
signal order_placed

## Outcome of a farm action.
enum Result {
	OK, ## Done.
	NOT_ENOUGH_COINS, ## Too poor.
	LOW_LEVEL, ## The farm level is too low.
	MISSING, ## Materials, seeds or items are missing.
	BAG_FULL, ## No room for items in the bag.
	NO_ENERGY, ## Not enough energy.
	NOT_BUILT, ## The building is not built.
	ALREADY, ## Already built, installed or done today.
	FULL, ## No room for more animals.
	EMPTY, ## Nothing to do.
}

## The farm buildings that can be built, in order.
const BUILDINGS: Array[String] = ["galinheiro", "curral"]

var _data: GameData
var _town_data: TownData
var _state: GameState
var _town: Town
## Real-time production: storage room for wood and stone (set by the main scene).
var production: Production


## Builds the rules over the data, the state and the town rules (animals and products).
func _init(data: GameData, town_data: TownData, state: GameState, town: Town) -> void:
	_data = data
	_town_data = town_data
	_state = state
	_town = town


func _n(key: String) -> float:
	return _town_data.num("farm_life", key)


# --- Level ---

## Farm level, 1..10, from the experience thresholds.
func level() -> int:
	var table: Array = _town_data.list("farm_life", "level_xp")
	var lvl: int = 1
	for i in table.size():
		if _state.farm_xp >= int(table[i]):
			lvl = i + 1
	return lvl


## Experience needed for the next level, or -1 at the top. Second value: the current level start.
func level_bounds() -> Vector2i:
	var table: Array = _town_data.list("farm_life", "level_xp")
	var lvl: int = level()
	var start: int = int(table[lvl - 1])
	return Vector2i(start, int(table[lvl]) if lvl < table.size() else -1)


## Experience given by [param action] ("chop", "rock", "egg", "feed", "milk", "box", "build").
func xp_for(action: String) -> int:
	return int(_n("xp_" + action))


## Experience for a fish of [param rarity].
func xp_for_catch(rarity: int) -> int:
	var table: Array = _town_data.list("farm_life", "xp_catch")
	return int(table[clampi(rarity, 0, table.size() - 1)])


## Adds experience; emits [signal farm_level_up] for every level passed.
func add_xp(amount: int) -> void:
	var before: int = level()
	_state.farm_xp += amount
	var after: int = level()
	for lvl in range(before + 1, after + 1):
		farm_level_up.emit(lvl)
	_state.town_changed.emit()


# --- Bag and shed ---

## Units of items in the bag (fish not counted: they have their own 20 places).
func bag_items() -> int:
	var n: int = 0
	for id: String in _state.goods:
		n += _state.good_count(id)
	return n


## Room for items in the bag.
func bag_room() -> int:
	return maxi(0, int(_n("bag_items")) - bag_items())


## Count of a good in the bag plus the shed.
func owned(id: String) -> int:
	return _state.good_count(id) + int(_state.shed.get(id, 0))


## Moves all of good [param id] from the bag to the shed.
func store_good(id: String) -> Result:
	var n: int = _state.good_count(id)
	if n <= 0:
		return Result.EMPTY
	_state.add_good(id, -n)
	_state.shed[id] = int(_state.shed.get(id, 0)) + n
	_state.town_changed.emit()
	return Result.OK


## Moves as much of good [param id] as fits from the shed to the bag.
func take_good(id: String) -> Result:
	var n: int = mini(int(_state.shed.get(id, 0)), bag_room())
	if int(_state.shed.get(id, 0)) <= 0:
		return Result.EMPTY
	if n <= 0:
		return Result.BAG_FULL
	_state.shed[id] = int(_state.shed[id]) - n
	_state.add_good(id, n)
	_state.town_changed.emit()
	return Result.OK


## Moves every item of the bag to the shed.
func store_all() -> Result:
	if bag_items() == 0:
		return Result.EMPTY
	for id: String in _state.goods.keys():
		store_good(id)
	return Result.OK


## Takes [param amount] of [param id], from the shed first and then from the bag.
func _spend(id: String, amount: int) -> void:
	var from_shed: int = mini(amount, int(_state.shed.get(id, 0)))
	_state.shed[id] = int(_state.shed.get(id, 0)) - from_shed
	_state.add_good(id, -(amount - from_shed))


# --- Cutting trees and breaking rocks ---

## Cuts the tree or breaks the rock of placement [param index] ([param rock] true for rocks).
## Wood or stone go to the bag; it grows back after regrow_days.
func gather(index: int, rock: bool) -> Result:
	var key: String = str(index)
	if _state.chopped.has(key):
		return Result.ALREADY
	if not _state.tools.has("picareta" if rock else "machado"):
		return Result.MISSING
	var yield_amount: int = int(_n("stone_yield" if rock else "wood_yield"))
	var item: String = "pedra" if rock else "madeira"
	if production != null and production.room_for(item) < yield_amount:
		return Result.BAG_FULL
	if production == null and bag_room() < yield_amount:
		return Result.BAG_FULL
	var cost: float = _n("rock_energy" if rock else "chop_energy")
	if _state.energy < cost:
		return Result.NO_ENERGY
	_state.energy -= cost
	if production != null:
		_state.shed[item] = int(_state.shed.get(item, 0)) + yield_amount
	else:
		_state.add_good(item, yield_amount)
	_state.chopped[key] = _state.day + int(_n("regrow_days"))
	add_xp(xp_for("rock" if rock else "chop"))
	return Result.OK


## Indices of the trees and rocks that grow back today (removed from the cut list).
func regrow() -> Array[int]:
	var back: Array[int] = []
	for key: Variant in _state.chopped.keys():
		if int(_state.chopped[key]) <= _state.day:
			back.append(int(str(key)))
			_state.chopped.erase(key)
	return back


# --- Buildings ---

## The needs of building [param id]: {"level", "madeira", "pedra", "coins"}.
func needs(id: String) -> Dictionary:
	return (_town_data.group("farm_life")["buildings"] as Dictionary).get(id, {})


## Why [param id] cannot be built now (OK when it can).
func build_blocker(id: String) -> Result:
	var need: Dictionary = needs(id)
	if _state.is_built(id):
		return Result.ALREADY
	if level() < int(need.get("level", 1)):
		return Result.LOW_LEVEL
	if owned("madeira") < int(need.get("madeira", 0)) or owned("pedra") < int(need.get("pedra", 0)):
		return Result.MISSING
	if _state.coins < int(need.get("coins", 0)):
		return Result.NOT_ENOUGH_COINS
	return Result.OK


## Builds [param id], spending wood, stone and coins.
func build(id: String) -> Result:
	var blocker: Result = build_blocker(id)
	if blocker != Result.OK:
		return blocker
	var need: Dictionary = needs(id)
	_spend("madeira", int(need.get("madeira", 0)))
	_spend("pedra", int(need.get("pedra", 0)))
	_state.coins -= int(need.get("coins", 0))
	_state.lots_built.append(id)
	add_xp(xp_for("build"))
	return Result.OK


# --- Orders and the truck ---

## Buys [param amount] of a good by phone; the truck brings it to the shed.
func order_good(id: String, amount: int) -> Result:
	var price: int = int(_town_data.good(id).get("price", 0)) * amount
	if price <= 0:
		return Result.MISSING
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_add_order("galpao", id, amount)
	return Result.OK


## Buys an animal at the auction; the truck brings it to its home (coop or corral).
func order_animal(kind: String) -> Result:
	var info: Dictionary = _town_data.animal(kind)
	var home_id: String = str(info["home"])
	if not home_ready(home_id):
		return Result.NOT_BUILT
	var capacity: int = 0
	for h: Variant in _town_data.homes():
		if str((h as Dictionary)["id"]) == home_id:
			capacity = int((h as Dictionary)["capacity"])
	if _town.animals_in(home_id) + _coming(home_id) >= capacity:
		return Result.FULL
	var price: int = int(info["price"])
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_add_order(home_id, kind, 1)
	return Result.OK


## True when animals can live in [param home_id]: its building is built, or it is always there
## (the barn stalls for horses, 2026-11-22).
func home_ready(home_id: String) -> bool:
	return _state.is_built(home_id) or bool(_town_data.home(home_id).get("always_built", false))


## Animals already bought for [param home_id] that are on the way or in a box.
func _coming(home_id: String) -> int:
	var n: int = 0
	for list: Array[Dictionary] in [_state.orders, _state.boxes]:
		for o: Dictionary in list:
			if str(o["dest"]) == home_id:
				for id: Variant in o["items"]:
					n += int((o["items"] as Dictionary)[id])
	return n


func _add_order(dest: String, id: String, amount: int) -> void:
	for o: Dictionary in _state.orders:
		if str(o["dest"]) == dest:
			var items: Dictionary = o["items"]
			items[id] = int(items.get(id, 0)) + amount
			_state.town_changed.emit()
			order_placed.emit()
			return
	_state.orders.append({"dest": dest, "items": {id: amount}})
	_state.town_changed.emit()
	order_placed.emit()


## Destinations with orders waiting for the truck, in order.
func order_destinations() -> Array[String]:
	var out: Array[String] = []
	for o: Dictionary in _state.orders:
		if not out.has(str(o["dest"])):
			out.append(str(o["dest"]))
	return out


## The truck leaves the order for [param dest] as a box in front of it (the order stays saved
## as an order until this moment, so closing the game during a trip loses nothing).
func drop_box(dest: String) -> void:
	for i in _state.orders.size():
		if str(_state.orders[i]["dest"]) == dest:
			_state.boxes.append(_state.orders[i])
			_state.orders.remove_at(i)
			_state.town_changed.emit()
			return


## Opens box [param index]: goods go to the shed, animals to their home.
func open_box(index: int) -> Result:
	if index < 0 or index >= _state.boxes.size():
		return Result.EMPTY
	var box: Dictionary = _state.boxes[index]
	var items: Dictionary = box["items"]
	if str(box["dest"]) == "galpao":
		for id: Variant in items:
			_state.shed[str(id)] = int(_state.shed.get(str(id), 0)) + int(items[id])
	else:
		for kind: Variant in items:
			for k in int(items[kind]):
				_state.animals.append({"kind": str(kind), "joy": _town_data.num("ranch", "joy_start"), "age": 0})
	_state.boxes.remove_at(index)
	add_xp(xp_for("box"))
	return Result.OK


# --- Animals ---

## Fills the trough of [param home_id] (bag first, then shed).
func feed(home_id: String) -> Result:
	var r: Town.Result = _town.fill_trough(home_id)
	if r == Town.Result.OK:
		add_xp(xp_for("feed"))
		return Result.OK
	return Result.FULL if r == Town.Result.FULL else Result.MISSING


## Collects the products waiting at [param home_id] into the bag (as many as fit).
func collect(home_id: String) -> Result:
	var products: Dictionary = _state.pending.get(home_id, {})
	var total: int = _town.pending_count(home_id)
	if total == 0:
		return Result.EMPTY
	if bag_room() <= 0:
		return Result.BAG_FULL
	var got: int = 0
	for id: Variant in products.keys():
		var take: int = mini(int(products[id]), bag_room())
		_state.add_good(str(id), take)
		products[id] = int(products[id]) - take
		got += take
	_state.pending[home_id] = products
	add_xp(xp_for("egg") * got)
	return Result.OK


## Cows ready to be milked by hand today.
func cows_to_milk() -> int:
	var n: int = 0
	for a: Dictionary in _state.animals:
		n += 1 if bool(a.get("milk_ready", false)) else 0
	return n


## Milks every cow that is ready (one milk each), into the bag.
func milk() -> Result:
	var cows: int = cows_to_milk()
	if cows == 0:
		return Result.EMPTY
	if bag_room() < cows:
		return Result.BAG_FULL
	if _state.energy < _n("milk_energy"):
		return Result.NO_ENERGY
	_state.energy -= _n("milk_energy")
	for a: Dictionary in _state.animals:
		if bool(a.get("milk_ready", false)):
			a["milk_ready"] = false
			_state.add_good("leite", 1)
	add_xp(xp_for("milk") * cows)
	return Result.OK


## Installs the milking machine (milk then waits in the corral bucket by itself).
func buy_milker() -> Result:
	if _state.milker:
		return Result.ALREADY
	if not _state.is_built("curral"):
		return Result.NOT_BUILT
	if level() < int(_n("milker_level")):
		return Result.LOW_LEVEL
	var price: int = int(_n("milker_price"))
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_state.milker = true
	_state.town_changed.emit()
	return Result.OK
