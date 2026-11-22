class_name Production
extends RefCounted
## Real-time farm production in the style of farm builders (2026-11-21, rules only):
##   - the field: plots, planting and harvesting by real time;
##   - factories: queues of recipes;
##   - animals: fed with their own feed, producing after real time;
##   - storage: the silo (crops) and the barn (everything else), each with a limit and upgrades
##     paid in rare materials that drop now and then;
##   - the order board: deliveries for coins and experience;
##   - the roadside stall: player-priced sales;
##   - land expansions.
## Timers are Unix timestamps, so they keep running while the game is closed. Values come from
## src/data/farm_prod.json. Uses [Farm] for the farm level and experience. Not thread-safe.
##
## Usage:
## [codeblock]
## var prod := Production.new(data, town_data, state, farm, FarmProd.load_file())
## prod.plant(0, "trigo")
## prod.tick()                        # every second: stall sales, milker
## var left: int = prod.seconds_left(state.crop_plots[0]["ready_at"])
## [/codeblock]

## A rare material dropped (shown as a message).
signal material_dropped(id: String)
## An order was delivered (the truck comes to take it).
signal order_shipped

## Outcome of an action.
enum Result { OK, LOW_LEVEL, MISSING, FULL, BUSY, NOT_READY, NOT_BUILT, NOT_ENOUGH_COINS, MAX, EMPTY }

## Clock: returns the current Unix time in seconds (replaced in tests).
var now: Callable = func() -> float: return Time.get_unix_time_from_system()

var _data: GameData
var _town: TownData
var _state: GameState
var _farm: Farm
var _p: Dictionary
var _rng := RandomNumberGenerator.new()


## Builds the rules; [param prod] is the parsed farm_prod.json.
func _init(data: GameData, town: TownData, state: GameState, farm: Farm, prod: Dictionary) -> void:
	_data = data
	_town = town
	_state = state
	_farm = farm
	_p = prod
	_rng.randomize()


## Reads src/data/farm_prod.json.
static func load_data(path: String = "res://src/data/farm_prod.json") -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## The parsed production data.
func data() -> Dictionary:
	return _p


## Seconds until [param ready_at] (0 when ready).
func seconds_left(ready_at: float) -> int:
	return maxi(0, ceili(ready_at - float(now.call())))


## Fills a new game (starting crops) and moves old bag items into storage. Call once at start.
func setup_state() -> void:
	if _state.crop_plots.is_empty():
		for i in int(_field("start_plots")):
			_state.crop_plots.append({"crop": "", "ready_at": 0.0})
	if not _state.prod_started:
		_state.prod_started = true
		var start: Dictionary = _p["start_silo"]
		for id: Variant in start:
			_add(str(id), int(start[id]))
	for id: String in _state.goods.keys():
		var n: int = _state.good_count(id)
		if n > 0:
			_state.shed[id] = int(_state.shed.get(id, 0)) + n
			_state.goods[id] = 0
	if _state.order_board.is_empty():
		fill_orders()


func _field(key: String) -> float:
	return float((_p["field"] as Dictionary)[key])


# --- Storage (silo and barn) ---

## "silo" for crops, "barn" for everything else.
func storage_of(id: String) -> String:
	return "silo" if (_p["silo_items"] as Array).has(id) else "barn"


## Capacity of the silo or barn.
func capacity(kind: String) -> int:
	var s: Dictionary = (_p["storage"] as Dictionary)[kind]
	return int(s["base"]) + int(s["step"]) * int(_state.storage_levels.get(kind, 0))


## Chests upstairs in the barn (2026-11-22): storage.barn.chests_min, one more per barn
## level, up to chests_max. The barn capacity is split between them.
func chest_count() -> int:
	var b: Dictionary = (_p["storage"] as Dictionary)["barn"]
	return clampi(int(b.get("chests_min", 2)) + int(_state.storage_levels.get("barn", 0)), int(b.get("chests_min", 2)), int(b.get("chests_max", 6)))


## Chest [param i] as (units inside, room). Chests fill in order: the next one only starts
## when the one before is full. The first chests take the leftover of an uneven split.
func chest_fill(i: int) -> Vector2i:
	var n: int = chest_count()
	var total: int = capacity("barn")
	var room: int = total / n + (1 if i < total % n else 0)
	var before: int = 0
	for k in i:
		before += total / n + (1 if k < total % n else 0)
	return Vector2i(clampi(used("barn") - before, 0, room), room)


## Units stored in the silo or barn.
func used(kind: String) -> int:
	var n: int = 0
	for id: Variant in _state.shed:
		if storage_of(str(id)) == kind:
			n += int(_state.shed[id])
	return n


## Free room in the storage of [param id].
func room_for(id: String) -> int:
	var kind: String = storage_of(id)
	return capacity(kind) - used(kind)


## Count of [param id] in storage.
func count(id: String) -> int:
	return int(_state.shed.get(id, 0))


## Adds [param n] of [param id] if it fits; returns false when full.
func _add(id: String, n: int) -> bool:
	if n <= 0:
		return true
	if room_for(id) < n:
		return false
	_state.shed[id] = count(id) + n
	return true


func _take(id: String, n: int) -> void:
	_state.shed[id] = maxi(0, count(id) - n)


func _has_all(items: Dictionary) -> bool:
	for id: Variant in items:
		if count(str(id)) < int(items[id]):
			return false
	return true


## Materials needed for the next upgrade of [param kind]: {id: count}.
func upgrade_needs(kind: String) -> Dictionary:
	var lvl: int = int(_state.storage_levels.get(kind, 0))
	var out: Dictionary = {}
	for id: Variant in ((_p["storage"] as Dictionary)[kind] as Dictionary)["materials"]:
		out[str(id)] = lvl + 1
	return out


## Upgrades the silo or barn with materials.
func upgrade_storage(kind: String) -> Result:
	var needs: Dictionary = upgrade_needs(kind)
	if not _has_all(needs):
		return Result.MISSING
	for id: Variant in needs:
		_take(str(id), int(needs[id]))
	_state.storage_levels[kind] = int(_state.storage_levels.get(kind, 0)) + 1
	_changed()
	return Result.OK


## Maybe drops a rare material for [param source] ("harvest", "factory", "animal", "fish").
func roll_drop(source: String) -> void:
	var drops: Dictionary = _p["drops"]
	if _rng.randf() >= float(drops.get(source, 0.0)):
		return
	var weights: Dictionary = drops["weights"]
	var total: float = 0.0
	for id: Variant in weights:
		total += float(weights[id])
	var x: float = _rng.randf() * total
	for id: Variant in weights:
		x -= float(weights[id])
		if x <= 0.0:
			if _add(str(id), 1):
				material_dropped.emit(str(id))
			return


# --- Field ---

## The crops, in data order.
func crops() -> Array:
	return _p["crops"]


## A crop by id.
func crop(id: String) -> Dictionary:
	for c: Variant in crops():
		if str((c as Dictionary)["id"]) == id:
			return c
	return {}


## Stage of plot [param i]: 0 empty, 1 growing, 2 ripe.
func plot_stage(i: int) -> int:
	var plot: Dictionary = _state.crop_plots[i]
	if str(plot["crop"]) == "":
		return 0
	return 2 if float(plot["ready_at"]) <= float(now.call()) else 1


## Grown fraction 0..1 of plot [param i].
func plot_growth(i: int) -> float:
	var plot: Dictionary = _state.crop_plots[i]
	if str(plot["crop"]) == "":
		return 0.0
	var total: float = float(crop(str(plot["crop"]))["seconds"])
	return clampf(1.0 - (float(plot["ready_at"]) - float(now.call())) / total, 0.0, 1.0)


## Plants [param crop_id] in plot [param i] (uses 1 of the crop from the silo).
func plant(i: int, crop_id: String) -> Result:
	var c: Dictionary = crop(crop_id)
	if _farm.level() < int(c["level"]):
		return Result.LOW_LEVEL
	if plot_stage(i) != 0:
		return Result.BUSY
	if count(crop_id) < 1:
		return Result.MISSING
	_take(crop_id, 1)
	_state.crop_plots[i] = {"crop": crop_id, "ready_at": float(now.call()) + float(c["seconds"])}
	_changed()
	return Result.OK


## Plants [param crop_id] in every empty plot it can; returns how many.
func plant_all(crop_id: String) -> int:
	var n: int = 0
	for i in _state.crop_plots.size():
		if plot_stage(i) == 0 and plant(i, crop_id) == Result.OK:
			n += 1
	return n


## Harvests plot [param i] into the silo.
func harvest(i: int) -> Result:
	if plot_stage(i) != 2:
		return Result.NOT_READY
	var plot: Dictionary = _state.crop_plots[i]
	var c: Dictionary = crop(str(plot["crop"]))
	if not _add(str(c["id"]), int(_field("harvest_yield"))):
		return Result.FULL
	_state.crop_plots[i] = {"crop": "", "ready_at": 0.0}
	_farm.add_xp(int(c["xp"]))
	roll_drop("harvest")
	_changed()
	return Result.OK


## Harvests every ripe plot; returns how many (stops when the silo is full).
func harvest_all() -> int:
	var n: int = 0
	for i in _state.crop_plots.size():
		if plot_stage(i) == 2:
			if harvest(i) != Result.OK:
				break
			n += 1
	return n


## Price of the next plot, or -1 at the maximum.
func plot_price() -> int:
	var n: int = _state.crop_plots.size()
	if n >= int(_field("max_plots")):
		return -1
	return int(_field("plot_price_base")) + int(_field("plot_price_step")) * (n - int(_field("start_plots")))


## Buys one more plot.
func buy_plot() -> Result:
	var price: int = plot_price()
	if price < 0:
		return Result.MAX
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	_state.crop_plots.append({"crop": "", "ready_at": 0.0})
	_changed()
	return Result.OK


# --- Factories ---

## Factory ids, in data order.
func factory_ids() -> Array:
	return (_p["factories"] as Dictionary).keys()


## Factory data by id.
func factory(id: String) -> Dictionary:
	return (_p["factories"] as Dictionary).get(id, {})


## The queue state of factory [param id]: {"slots", "queue": [{"item", "out", "ready_at"}]}.
func factory_state(id: String) -> Dictionary:
	if not _state.factories.has(id):
		_state.factories[id] = {"slots": int(factory(id)["slots"]), "queue": []}
	return _state.factories[id]


## Starts recipe [param recipe_id] in factory [param id].
func produce(id: String, recipe_id: String) -> Result:
	if not _state.is_built(id):
		return Result.NOT_BUILT
	var recipe: Dictionary = {}
	for r: Variant in factory(id)["recipes"]:
		if str((r as Dictionary)["id"]) == recipe_id:
			recipe = r
	if recipe.is_empty():
		return Result.MISSING
	if _farm.level() < int(recipe["level"]):
		return Result.LOW_LEVEL
	var fs: Dictionary = factory_state(id)
	var queue: Array = fs["queue"]
	if queue.size() >= int(fs["slots"]):
		return Result.FULL
	var ins: Dictionary = recipe["in"]
	if not _has_all(ins):
		return Result.MISSING
	for item: Variant in ins:
		_take(str(item), int(ins[item]))
	var start: float = float(now.call())
	if not queue.is_empty():
		start = maxf(start, float((queue[queue.size() - 1] as Dictionary)["ready_at"]))
	queue.append({"item": recipe_id, "out": int(recipe["out"]), "xp": int(recipe["xp"]), "ready_at": start + float(recipe["seconds"])})
	_changed()
	return Result.OK


## Finished items waiting in factory [param id].
func factory_done(id: String) -> int:
	var n: int = 0
	for q: Variant in factory_state(id)["queue"]:
		if float((q as Dictionary)["ready_at"]) <= float(now.call()):
			n += 1
	return n


## Collects the finished items of factory [param id] into the barn.
func collect_factory(id: String) -> Result:
	var queue: Array = factory_state(id)["queue"]
	var got: int = 0
	var full: bool = false
	while not queue.is_empty() and float((queue[0] as Dictionary)["ready_at"]) <= float(now.call()):
		var q: Dictionary = queue[0]
		if not _add(str(q["item"]), int(q["out"])):
			full = true
			break
		_farm.add_xp(int(q.get("xp", 1)))
		roll_drop("factory")
		queue.pop_front()
		got += 1
	if got > 0:
		_changed()
		return Result.OK
	return Result.FULL if full else Result.EMPTY


## Price of the next queue slot in factory [param id], or -1 at the maximum.
func slot_price(id: String) -> int:
	var fs: Dictionary = factory_state(id)
	if int(fs["slots"]) >= int(factory(id)["max_slots"]):
		return -1
	return int(factory(id)["slot_price"]) * (int(fs["slots"]) - int(factory(id)["slots"]) + 1)


## Buys one more queue slot.
func buy_slot(id: String) -> Result:
	var price: int = slot_price(id)
	if price < 0:
		return Result.MAX
	if _state.coins < price:
		return Result.NOT_ENOUGH_COINS
	_state.coins -= price
	factory_state(id)["slots"] = int(factory_state(id)["slots"]) + 1
	_changed()
	return Result.OK


# --- Animals ---

func _animal(kind: String) -> Dictionary:
	return (_p["animals"] as Dictionary).get(kind, {})


## Animals of [param home]: indices into [member GameState.animals].
func animals_of(home: String) -> Array[int]:
	var out: Array[int] = []
	for i in _state.animals.size():
		var info: Dictionary = _town.animal(str(_state.animals[i]["kind"]))
		if str(info.get("home", "")) == home:
			out.append(i)
	return out


## 0 hungry, 1 producing, 2 ready to collect.
func animal_stage(i: int) -> int:
	var a: Dictionary = _state.animals[i]
	if not bool(a.get("fed", false)):
		return 0
	return 2 if float(a.get("ready_at", 0.0)) <= float(now.call()) else 1


## The feed the animals of [param home] eat.
func feed_of(home: String) -> String:
	for i: int in animals_of(home):
		return str(_animal(str(_state.animals[i]["kind"]))["feed"])
	return ""


## Feeds every hungry animal of [param home] (1 feed each); returns how many ate.
func feed_home(home: String) -> int:
	var n: int = 0
	for i: int in animals_of(home):
		var a: Dictionary = _state.animals[i]
		var info: Dictionary = _animal(str(a["kind"]))
		if animal_stage(i) != 0 or count(str(info["feed"])) < 1:
			continue
		_take(str(info["feed"]), 1)
		a["fed"] = true
		a["ready_at"] = float(now.call()) + float(info["seconds"])
		n += 1
	if n > 0:
		_changed()
	return n


## Animals of [param home] ready to collect.
func ready_in(home: String) -> int:
	var n: int = 0
	for i: int in animals_of(home):
		n += 1 if animal_stage(i) == 2 else 0
	return n


## Collects the products of the ready animals of [param home] into the barn.
func collect_home(home: String) -> Result:
	var got: int = 0
	var full: bool = false
	for i: int in animals_of(home):
		if animal_stage(i) != 2:
			continue
		var a: Dictionary = _state.animals[i]
		var info: Dictionary = _animal(str(a["kind"]))
		var product: String = str(info["product"])
		if product != "" and not _add(product, 1):
			full = true
			break
		a["fed"] = false
		a["ready_at"] = 0.0
		if info.has("grows_into"):
			a["age"] = int(a.get("age", 0)) + 1
			if int(a["age"]) >= int(info["feeds_to_grow"]):
				a["kind"] = str(info["grows_into"])
				a["age"] = 0
		_farm.add_xp(int(info["xp"]))
		roll_drop("animal")
		got += 1
	if got > 0:
		_changed()
		return Result.OK
	return Result.FULL if full else Result.EMPTY


# --- Order board ---

## Fills empty or cooled-down order slots with new orders.
func fill_orders() -> void:
	var cfg: Dictionary = _p["orders"]
	while _state.order_board.size() < int(cfg["size"]):
		_state.order_board.append({"items": {}, "coins": 0, "xp": 0, "wait_until": 0.0})
	var changed: bool = false
	for i in _state.order_board.size():
		var o: Dictionary = _state.order_board[i]
		if (o["items"] as Dictionary).is_empty() and float(o["wait_until"]) <= float(now.call()):
			_state.order_board[i] = _new_order()
			changed = true
	if changed:
		_changed()


func _new_order() -> Dictionary:
	var cfg: Dictionary = _p["orders"]
	var pool: Array = []
	for e: Variant in cfg["pool"]:
		if _farm.level() >= int((e as Dictionary)["level"]):
			pool.append(e)
	var kinds: int = 1 + _rng.randi_range(0, mini(int(cfg["max_kinds"]), pool.size()) - 1)
	var items: Dictionary = {}
	var coins: int = 0
	for k in kinds:
		var e: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
		var id: String = str(e["id"])
		if items.has(id):
			continue
		var n: int = _rng.randi_range(int(e["min"]), int(e["max"]))
		items[id] = n
		coins += int(_town.good(id).get("sell", 1)) * n
	coins = int(float(coins) * float(cfg["coin_mult"]))
	return {"items": items, "coins": coins, "xp": maxi(1, int(float(coins) * float(cfg["xp_mult"]))), "wait_until": 0.0}


## Delivers order [param i] (takes the items, pays coins and experience).
func deliver(i: int) -> Result:
	var o: Dictionary = _state.order_board[i]
	var items: Dictionary = o["items"]
	if items.is_empty():
		return Result.EMPTY
	if not _has_all(items):
		return Result.MISSING
	for id: Variant in items:
		_take(str(id), int(items[id]))
	_state.coins += int(o["coins"])
	_farm.add_xp(int(o["xp"]))
	_state.order_board[i] = {"items": {}, "coins": 0, "xp": 0, "wait_until": float(now.call()) + float((_p["orders"] as Dictionary)["new_seconds"])}
	order_shipped.emit()
	_changed()
	return Result.OK


## Throws order [param i] away; a new one comes after discard_seconds.
func discard(i: int) -> void:
	_state.order_board[i] = {"items": {}, "coins": 0, "xp": 0, "wait_until": float(now.call()) + float((_p["orders"] as Dictionary)["discard_seconds"])}
	_changed()


# --- Roadside stall ---

## Stall slots: {"item", "count", "price", "sell_at", "sold"} or {} when empty.
func stall() -> Array:
	var cfg: Dictionary = _p["stall"]
	while _state.stall.size() < int(cfg["slots"]):
		_state.stall.append({})
	return _state.stall


## Suggested price for [param n] of [param id].
func base_price(id: String, n: int) -> int:
	return maxi(1, int(_town.good(id).get("sell", 1)) * n)


## Puts [param n] of [param id] on stall slot [param slot] for [param price] coins.
func put_on_stall(slot: int, id: String, n: int, price: int) -> Result:
	var slots: Array = stall()
	if not (slots[slot] as Dictionary).is_empty():
		return Result.BUSY
	if count(id) < n or n <= 0:
		return Result.MISSING
	var cfg: Dictionary = _p["stall"]
	_take(id, n)
	var ratio: float = float(price) / float(base_price(id, n))
	var t: float = inverse_lerp(float(cfg["price_min"]), float(cfg["price_max"]), ratio)
	var wait: float = lerpf(float(cfg["sell_min"]), float(cfg["sell_max"]), clampf(t, 0.0, 1.0)) * _rng.randf_range(0.8, 1.2)
	slots[slot] = {"item": id, "count": n, "price": price, "sell_at": float(now.call()) + wait, "sold": false}
	_changed()
	return Result.OK


## Collects the coins of a sold slot, or takes an unsold one back.
func clear_stall(slot: int) -> Result:
	var s: Dictionary = stall()[slot]
	if s.is_empty():
		return Result.EMPTY
	if bool(s["sold"]):
		_state.coins += int(s["price"])
		_state.stats_earned += int(s["price"])
	else:
		_state.shed[str(s["item"])] = count(str(s["item"])) + int(s["count"])
	_state.stall[slot] = {}
	_changed()
	return Result.OK


## Slots sold and waiting to be collected.
func stall_sold() -> int:
	var n: int = 0
	for s: Variant in stall():
		n += 1 if not (s as Dictionary).is_empty() and bool((s as Dictionary)["sold"]) else 0
	return n


# --- Expansions ---

## Expansion data by id.
func expansion(id: String) -> Dictionary:
	return (_p["expansions"] as Dictionary).get(id, {})


## Opens expansion [param id] with materials, coins and the level.
func expand(id: String) -> Result:
	var e: Dictionary = expansion(id)
	if _state.expanded.has(id):
		return Result.MAX
	if _farm.level() < int(e["level"]):
		return Result.LOW_LEVEL
	if not _has_all(e["items"]):
		return Result.MISSING
	if _state.coins < int(e["coins"]):
		return Result.NOT_ENOUGH_COINS
	for id2: Variant in e["items"]:
		_take(str(id2), int((e["items"] as Dictionary)[id2]))
	_state.coins -= int(e["coins"])
	_state.expanded.append(id)
	_farm.add_xp(_farm.xp_for("build"))
	_changed()
	return Result.OK


# --- Tools ---

## Buys tool [param id] ("machado" or "picareta"); it is kept forever.
func buy_tool(id: String) -> Result:
	var tool: Dictionary = (_p["tools"] as Dictionary).get(id, {})
	if tool.is_empty():
		return Result.MISSING
	if _state.tools.has(id):
		return Result.MAX
	if _state.coins < int(tool["price"]):
		return Result.NOT_ENOUGH_COINS
	_state.coins -= int(tool["price"])
	_state.tools.append(id)
	_changed()
	return Result.OK


## Moves every running timer [param seconds] closer to its end (owner test mode).
func skip_time(seconds: float) -> void:
	for plot: Dictionary in _state.crop_plots:
		plot["ready_at"] = float(plot["ready_at"]) - seconds
	for id: Variant in _state.factories:
		for q: Variant in (_state.factories[id] as Dictionary)["queue"]:
			(q as Dictionary)["ready_at"] = float((q as Dictionary)["ready_at"]) - seconds
	for a: Dictionary in _state.animals:
		a["ready_at"] = float(a.get("ready_at", 0.0)) - seconds
	for s: Variant in stall():
		if not (s as Dictionary).is_empty():
			(s as Dictionary)["sell_at"] = float((s as Dictionary)["sell_at"]) - seconds
	for o: Dictionary in _state.order_board:
		o["wait_until"] = float(o["wait_until"]) - seconds
	tick()
	_changed()


# --- Every second ---

## Updates the stall sales, refills orders and lets the milking machine collect the milk.
func tick() -> void:
	var t: float = float(now.call())
	for s: Variant in stall():
		var slot: Dictionary = s
		if not slot.is_empty() and not bool(slot["sold"]) and float(slot["sell_at"]) <= t:
			slot["sold"] = true
			_changed()
	fill_orders()
	if _state.milker and ready_in("curral") > 0:
		collect_home("curral")


func _changed() -> void:
	_state.town_changed.emit()
