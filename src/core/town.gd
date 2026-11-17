class_name Town
extends RefCounted
## The town rules over [GameState] (no drawing): warehouse (Story 010), rod workshop (011),
## neighbor requests (012), restaurant (014), farm plots (015), ranch (016), clothes (017) and
## the mayor's city panel (018), plus the daily tick that grows plants, feeds animals, refills the
## brewery and updates the satisfaction. Every action returns a [enum Result] for the UI to show.
## All values come from [TownData]. Not thread-safe.
##
## Usage:
## [codeblock]
## var town := Town.new(data, town_data, state, RandomSource.new(7))
## if town.deliver("ana") == Town.Result.OK:
##     print("pedido entregue")
## state.day_started.connect(func(_d: int, _a: bool) -> void: town.on_new_day())
## [/codeblock]

## Outcome of a town action.
enum Result {
	OK, ## Done.
	NOT_ENOUGH_COINS, ## Too poor.
	NOT_BUILT, ## The lot of this service is not built yet.
	LOCKED, ## The city level is too low.
	FULL, ## No room (bag, warehouse, stock, trough, home).
	EMPTY, ## Nothing to move, sell, cook, collect or feed.
	MAX_LEVEL, ## Already at the top.
	NO_ENERGY, ## Not enough energy.
	NOT_READY, ## The plant is not ripe, the request is not out, the plot is busy.
	MISSING, ## The needed fish, seeds or items are missing.
	ALREADY, ## Already owned, watered or built.
}

## Plot growth stage.
enum Stage { EMPTY, SPROUT, GROWING, RIPE }

var _data: GameData
var _town: TownData
var _state: GameState
var _rng: RandomSource


## Builds the rules over [param data], [param town], [param state]; [param rng] rolls requests.
func _init(data: GameData, town: TownData, state: GameState, rng: RandomSource) -> void:
	_data = data
	_town = town
	_state = state
	_rng = rng


# --- Warehouse (Story 010) ---

## Fish the warehouse can hold.
func storage_capacity() -> int:
	return int(_town.num("storage", "start_capacity")) + int(_town.num("storage", "upgrade_step")) * _state.storage_upgrades


## Cost of the next expansion, or -1 at the maximum.
func storage_upgrade_cost() -> int:
	var costs: Array = _town.list("storage", "upgrade_costs")
	return int(costs[_state.storage_upgrades]) if _state.storage_upgrades < costs.size() else -1


## Moves bag fish [param index] into the warehouse.
func to_storage(index: int) -> Result:
	if not _state.is_built("armazem"):
		return Result.NOT_BUILT
	if index < 0 or index >= _state.bag.size():
		return Result.EMPTY
	if _state.storage.size() >= storage_capacity():
		return Result.FULL
	_state.storage.append(_state.bag[index])
	_state.bag.remove_at(index)
	_state.town_changed.emit()
	return Result.OK


## Moves warehouse fish [param index] back into the bag.
func to_bag(index: int) -> Result:
	if index < 0 or index >= _state.storage.size():
		return Result.EMPTY
	if _state.bag.size() >= int(_data.tune("bag_size")):
		return Result.FULL
	_state.bag.append(_state.storage[index])
	_state.storage.remove_at(index)
	_state.town_changed.emit()
	return Result.OK


## Buys the next warehouse expansion.
func upgrade_storage() -> Result:
	var cost: int = storage_upgrade_cost()
	if cost < 0:
		return Result.MAX_LEVEL
	if _state.coins < cost:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= cost
	_state.storage_upgrades += 1
	_state.town_changed.emit()
	return Result.OK


## Value of the fish in the warehouse.
func storage_value() -> int:
	var total: int = 0
	for fish: GameState.Catch in _state.storage:
		total += fish.value
	return total


## Value of the goods that can be sold (sell price above 0).
func goods_value() -> int:
	var total: int = 0
	for id: String in _state.goods:
		total += int(_town.good(id).get("sell", 0)) * _state.good_count(id)
	return total


## Sells the warehouse fish and the sellable goods (the bag is sold by [Economy.sell_all]).
## Returns the coins earned (0 when there was nothing).
func sell_storage_and_goods() -> int:
	var earned: int = storage_value() + goods_value()
	if earned <= 0:
		return 0
	_state.storage.clear()
	for id: String in _state.goods.keys():
		if int(_town.good(id).get("sell", 0)) > 0:
			_state.goods[id] = 0
	_state.coins += earned
	_state.stats_earned += earned
	_state.town_changed.emit()
	return earned


## Buys [param amount] of a good that has a price (seeds, feed).
func buy_good(id: String, amount: int = 1) -> Result:
	var price: int = int(_town.good(id).get("price", 0)) * amount
	if price <= 0:
		return Result.MISSING
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_state.add_good(id, amount)
	_state.town_changed.emit()
	return Result.OK


# --- Rod workshop (Story 011) ---

## Workshop level of the equipped rod.
func rod_level() -> int:
	return _state.rod_levels.get(_state.rod, 0)


## Cost of the next level of the equipped rod, or -1 at the maximum.
func rod_upgrade_cost() -> int:
	var level: int = rod_level()
	if level >= int(_town.num("workshop", "max_level")):
		return -1
	var costs: Array = _town.list("workshop", "level_costs")
	return int(costs[level]) + int(float(_data.rod_by_id(_state.rod).price) * _town.num("workshop", "rod_price_factor"))


## Upgrades the equipped rod one level.
func upgrade_rod() -> Result:
	if not _state.is_built("oficina"):
		return Result.NOT_BUILT
	var cost: int = rod_upgrade_cost()
	if cost < 0:
		return Result.MAX_LEVEL
	if _state.coins < cost:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= cost
	_state.rod_levels[_state.rod] = rod_level() + 1
	_state.town_changed.emit()
	return Result.OK


# --- Neighbor requests (Story 012) ---

## Gives every neighbor without a request a new one when its day has come.
func ensure_requests() -> void:
	var changed: bool = false
	for entry: Variant in _town.neighbors():
		var id: String = str((entry as Dictionary)["id"])
		var req: Dictionary = _state.requests.get(id, {})
		if not req.has("done"):
			req["done"] = 0
		if str(req.get("species", "")) == "" and int(req.get("ready_day", 0)) <= _state.day:
			var sp: GameData.Species = _roll_request_species()
			req["species"] = sp.id
			var top: int = int(_town.num("requests", "count_max"))
			var low: int = int(_town.num("requests", "count_min"))
			req["count"] = 1 if sp.rarity >= 2 else low + int(_rng.next_float() * float(top - low + 1))
			changed = true
		_state.requests[id] = req
	if changed:
		_state.town_changed.emit()


## The open request of neighbor [param id]: {"species", "count"} or empty when none is out.
func request_of(id: String) -> Dictionary:
	var req: Dictionary = _state.requests.get(id, {})
	return req if str(req.get("species", "")) != "" else {}


## Coins paid for the open request of [param id].
func request_reward(id: String) -> int:
	var req: Dictionary = request_of(id)
	if req.is_empty():
		return 0
	var sp: GameData.Species = _data.species_by_id(str(req["species"]))
	return int(float(sp.base_value * int(req["count"])) * _town.num("requests", "reward_mult")) + int(_town.num("requests", "reward_bonus"))


## How many fish of [param species] the player has (bag plus warehouse).
func fish_owned(species: String) -> int:
	var n: int = 0
	for fish: GameState.Catch in _state.bag:
		n += 1 if fish.id == species else 0
	for fish: GameState.Catch in _state.storage:
		n += 1 if fish.id == species else 0
	return n


## Delivers the open request of [param id]: takes the fish (warehouse first), pays coins and a
## luck bait; the next request comes after next_after_days.
func deliver(id: String) -> Result:
	var req: Dictionary = request_of(id)
	if req.is_empty():
		return Result.NOT_READY
	var species: String = str(req["species"])
	var count: int = int(req["count"])
	if fish_owned(species) < count:
		return Result.MISSING
	var reward: int = request_reward(id)
	var left: int = count
	left = _take_fish(_state.storage, species, left)
	left = _take_fish(_state.bag, species, left)
	_state.coins += reward
	_state.luck_baits += int(_town.num("requests", "reward_luck_baits"))
	var stored: Dictionary = _state.requests[id]
	stored["species"] = ""
	stored["count"] = 0
	stored["ready_day"] = _state.day + int(_town.num("requests", "next_after_days"))
	stored["done"] = int(stored.get("done", 0)) + 1
	_state.request_score += 1.0
	_state.town_changed.emit()
	check_city_level()
	return Result.OK


# --- Restaurant (Story 014) ---

## Turns fish [param index] of the bag ([param from_storage] false) or warehouse into a dish.
func cook(index: int, from_storage: bool) -> Result:
	if not _state.is_built("restaurante"):
		return Result.NOT_BUILT
	var source: Array[GameState.Catch] = _state.storage if from_storage else _state.bag
	if index < 0 or index >= source.size():
		return Result.EMPTY
	if _state.dishes.size() >= int(_town.num("restaurant", "stock_max")):
		return Result.FULL
	var fish: GameState.Catch = source[index]
	var sp: GameData.Species = _data.species_by_id(fish.id)
	var names: Array = _town.list("restaurant", "dish_names")
	var value: int = maxi(int(_town.num("restaurant", "dish_min_value")), int(float(fish.value) * _town.num("restaurant", "dish_value_mult")))
	_state.dishes.append({"name": "%s de %s" % [str(names[mini(sp.rarity, names.size() - 1)]), sp.name], "value": value})
	source.remove_at(index)
	_state.town_changed.emit()
	return Result.OK


## A neighbor wants a meal: buys the first dish on sale. Returns true when served.
func npc_meal() -> bool:
	if not _state.is_built("restaurante"):
		return false
	_state.meals_wanted += 1
	if _state.dishes.is_empty():
		return false
	var dish: Dictionary = _state.dishes.pop_front()
	var value: int = int(dish["value"])
	_state.coins += value
	_state.sales_today += value
	_state.meals_served += 1
	_state.town_changed.emit()
	return true


## A neighbor wants a drink: the brewery sells one while it has stock. Returns true when sold.
func npc_drink() -> bool:
	if not _state.is_built("restaurante") or _state.drinks <= 0:
		return false
	_state.drinks -= 1
	var price: int = int(_town.num("restaurant", "drink_price"))
	_state.coins += price
	_state.sales_today += price
	_state.town_changed.emit()
	return true


# --- Farm plots (Story 015) ---

## Makes sure there are [param count] plots (the world decides how many exist).
func ensure_plots(count: int) -> void:
	while _state.plots.size() < count:
		_state.plots.append({"crop": "", "days": 0, "watered": false})


## Growth stage of plot [param i].
func stage(i: int) -> Stage:
	var plot: Dictionary = _state.plots[i]
	var crop_id: String = str(plot["crop"])
	if crop_id == "":
		return Stage.EMPTY
	var days: int = int(plot["days"])
	if days >= int(_town.crop(crop_id)["grow_days"]):
		return Stage.RIPE
	return Stage.SPROUT if days == 0 else Stage.GROWING


## Plants [param crop_id] in plot [param i] (spends one seed and energy).
func plant(i: int, crop_id: String) -> Result:
	if stage(i) != Stage.EMPTY:
		return Result.NOT_READY
	var seed_id: String = str(_town.crop(crop_id)["seed"])
	if _state.good_count(seed_id) <= 0:
		return Result.MISSING
	if not _spend_energy(_town.num("farm", "plant_energy")):
		return Result.NO_ENERGY
	_state.add_good(seed_id, -1)
	_state.plots[i] = {"crop": crop_id, "days": 0, "watered": false}
	_state.town_changed.emit()
	return Result.OK


## Waters plot [param i] for today.
func water(i: int) -> Result:
	var s: Stage = stage(i)
	if s == Stage.EMPTY or s == Stage.RIPE:
		return Result.NOT_READY
	if bool(_state.plots[i]["watered"]):
		return Result.ALREADY
	if not _spend_energy(_town.num("farm", "water_energy")):
		return Result.NO_ENERGY
	_state.plots[i]["watered"] = true
	_state.town_changed.emit()
	return Result.OK


## Harvests a ripe plot [param i] into the goods.
func harvest(i: int) -> Result:
	if stage(i) != Stage.RIPE:
		return Result.NOT_READY
	if not _spend_energy(_town.num("farm", "harvest_energy")):
		return Result.NO_ENERGY
	var crop: Dictionary = _town.crop(str(_state.plots[i]["crop"]))
	_state.add_good(str(crop["id"]), int(crop["harvest"]))
	_state.plots[i] = {"crop": "", "days": 0, "watered": false}
	_state.town_changed.emit()
	return Result.OK


## Uses one [param crop_id] as bait: shorter waits for bait_minutes of game time.
func use_crop_bait(crop_id: String) -> Result:
	if not bool(_town.crop(crop_id).get("bait", false)):
		return Result.MISSING
	if _state.good_count(crop_id) <= 0:
		return Result.EMPTY
	_state.add_good(crop_id, -1)
	_state.garden_bait_left += _town.num("farm", "bait_minutes")
	_state.town_changed.emit()
	return Result.OK


# --- Ranch (Story 016) ---

## True when the ranch home [param home_id] exists (its lot built, or it needs no lot).
func home_open(home_id: String) -> bool:
	for h: Variant in _town.homes():
		var home: Dictionary = h
		if str(home["id"]) == home_id:
			var lot: String = str(home["lot"])
			return lot == "" or _state.is_built(lot)
	return false


## Animals living in [param home_id].
func animals_in(home_id: String) -> int:
	var n: int = 0
	for a: Dictionary in _state.animals:
		n += 1 if str(_town.animal(str(a["kind"]))["home"]) == home_id else 0
	return n


## Buys an animal of [param kind].
func buy_animal(kind: String) -> Result:
	var info: Dictionary = _town.animal(kind)
	var home_id: String = str(info["home"])
	if not home_open(home_id):
		return Result.NOT_BUILT
	var capacity: int = 0
	for h: Variant in _town.homes():
		if str((h as Dictionary)["id"]) == home_id:
			capacity = int((h as Dictionary)["capacity"])
	if animals_in(home_id) >= capacity:
		return Result.FULL
	var price: int = int(info["price"])
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_state.animals.append({"kind": kind, "joy": _town.num("ranch", "joy_start")})
	_state.town_changed.emit()
	return Result.OK


## Fills the trough of [param home_id] with feed (ração first, then wheat) up to its capacity.
func fill_trough(home_id: String) -> Result:
	var room: int = int(_town.num("ranch", "trough_capacity")) - _state.troughs.get(home_id, 0)
	if room <= 0:
		return Result.FULL
	var moved: int = 0
	for feed: Variant in _town.list("ranch", "feeds"):
		var id: String = str(feed)
		var take: int = mini(room - moved, _state.good_count(id))
		_state.add_good(id, -take)
		moved += take
	if moved == 0:
		return Result.MISSING
	_state.troughs[home_id] = _state.troughs.get(home_id, 0) + moved
	_state.town_changed.emit()
	return Result.OK


## Products waiting at [param home_id].
func pending_count(home_id: String) -> int:
	var n: int = 0
	var products: Dictionary = _state.pending.get(home_id, {})
	for id: Variant in products:
		n += int(products[id])
	return n


## Moves the products waiting at [param home_id] into the goods.
func collect(home_id: String) -> Result:
	var products: Dictionary = _state.pending.get(home_id, {})
	if pending_count(home_id) == 0:
		return Result.EMPTY
	for id: Variant in products:
		_state.add_good(str(id), int(products[id]))
	_state.pending[home_id] = {}
	_state.town_changed.emit()
	return Result.OK


# --- Clothes (Story 017) ---

## Buys clothing [param id] (and equips it), or equips it when already owned.
func buy_piece(id: String) -> Result:
	if not _state.is_built("roupas"):
		return Result.NOT_BUILT
	var piece: Dictionary = _town.piece(id)
	if piece.is_empty():
		return Result.MISSING
	if not _state.clothes_owned.has(id):
		var price: int = int(piece["price"])
		if _state.coins < price:
			return Result.NOT_ENOUGH_COINS
		_state.coins -= price
		_state.clothes_owned.append(id)
	_state.outfit[_slot_of(id)] = id
	_state.town_changed.emit()
	return Result.OK


# --- City (Story 018) ---

## Satisfaction 0..100 = weighted requests, food and services (weights in town.json).
func satisfaction() -> float:
	var req: float = clampf(_state.request_score / _town.num("city", "request_target"), 0.0, 1.0)
	var services: int = 0
	var built: int = 0
	for lot: Variant in _town.lots():
		var l: Dictionary = lot
		if bool(l.get("service", false)):
			services += 1
			built += 1 if _state.is_built(str(l["id"])) else 0
	var svc: float = float(built) / float(maxi(services, 1))
	var score: float = _town.num("city", "weight_requests") * req + _town.num("city", "weight_food") * _state.food_score + _town.num("city", "weight_services") * svc
	return clampf(score * 100.0, 0.0, 100.0)


## Builds lot [param id].
func build_lot(id: String) -> Result:
	var lot: Dictionary = _town.lot(id)
	if lot.is_empty():
		return Result.MISSING
	if _state.is_built(id):
		return Result.ALREADY
	if _state.city_level < int(lot["min_city_level"]):
		return Result.LOCKED
	var cost: int = int(lot["cost"])
	if _state.coins < cost:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= cost
	_state.lots_built.append(id)
	_state.town_changed.emit()
	check_city_level()
	return Result.OK


## Satisfaction needed for the next city level, or -1 at the top.
func next_level_goal() -> float:
	var levels: Array = _town.city_levels()
	if _state.city_level >= levels.size():
		return -1.0
	return float((levels[_state.city_level] as Dictionary)["satisfaction"])


## Raises the city level while the satisfaction passes the goals, paying each reward.
func check_city_level() -> void:
	var levels: Array = _town.city_levels()
	while _state.city_level < levels.size() and satisfaction() >= next_level_goal():
		var reward: int = int((levels[_state.city_level] as Dictionary)["reward"])
		_state.city_level += 1
		_state.coins += reward
		_state.city_level_up.emit(_state.city_level, reward)


# --- Daily tick ---

## A new day: watered plants grow, animals eat from their trough and produce, the brewery
## refills, the food score and request score update, new requests come, the city may level up.
func on_new_day() -> void:
	for i: int in _state.plots.size():
		var plot: Dictionary = _state.plots[i]
		if str(plot["crop"]) != "" and bool(plot["watered"]):
			plot["days"] = int(plot["days"]) + 1
		plot["watered"] = false
	for a: Dictionary in _state.animals:
		var info: Dictionary = _town.animal(str(a["kind"]))
		var home_id: String = str(info["home"])
		var feed: int = int(info["feed"])
		var trough: int = _state.troughs.get(home_id, 0)
		if trough >= feed:
			_state.troughs[home_id] = trough - feed
			a["joy"] = minf(100.0, float(a["joy"]) + _town.num("ranch", "joy_fed"))
			var products: Dictionary = _state.pending.get(home_id, {})
			var product: String = str(info["product"])
			products[product] = int(products.get(product, 0)) + 1
			_state.pending[home_id] = products
		else:
			a["joy"] = maxf(0.0, float(a["joy"]) - _town.num("ranch", "joy_hungry"))
	if _state.meals_wanted > 0:
		var served: float = float(_state.meals_served) / float(_state.meals_wanted)
		_state.food_score = lerpf(_state.food_score, served, _town.num("city", "food_smoothing"))
	_state.meals_wanted = 0
	_state.meals_served = 0
	_state.sales_today = 0
	_state.drinks = int(_town.num("restaurant", "drinks_per_day"))
	_state.request_score *= _town.num("city", "request_decay")
	ensure_requests()
	check_city_level()
	_state.town_changed.emit()


func _roll_request_species() -> GameData.Species:
	var top: int = mini(_state.level - 1, _data.max_rarity_index())
	var pool: Array[GameData.Species] = []
	for sp: GameData.Species in _data.species:
		if sp.rarity <= top and sp.time == "any":
			pool.append(sp)
	return pool[mini(int(_rng.next_float() * float(pool.size())), pool.size() - 1)]


func _take_fish(source: Array[GameState.Catch], species: String, count: int) -> int:
	var left: int = count
	for i: int in range(source.size() - 1, -1, -1):
		if left <= 0:
			break
		if source[i].id == species:
			source.remove_at(i)
			left -= 1
	return left


func _spend_energy(amount: float) -> bool:
	if _state.energy < amount:
		return false
	_state.energy -= amount
	return true


func _slot_of(id: String) -> String:
	for slot: String in ["hat", "shirt", "boots"]:
		for p: Variant in _town.clothes(slot):
			if str((p as Dictionary)["id"]) == id:
				return slot
	return "hat"
