class_name Economy
extends RefCounted
## Selling the bag, buying and equipping gear, using items (2D economy.js).
##
## Every action returns a [enum Result]; the UI turns it into text. Not thread-safe.
##
## Usage:
## [codeblock]
## var economy := Economy.new(data, state)
## if economy.buy_gear(Economy.GearKind.ROD, "fibra") == Economy.Result.NOT_ENOUGH_COINS:
##     show_message("Moedas insuficientes.")
## [/codeblock]

## The bag was sold: [param count] fish for [param coins].
signal fish_sold(count: int, coins: int)

## Outcome of a shop or item action.
enum Result {
	OK, ## Done: sold, bought, eaten or used.
	EQUIPPED, ## Already owned: it is now equipped.
	EMPTY_BAG, ## Nothing to sell.
	LOCKED_BY_LEVEL, ## The player's level is below the entry's level.
	NOT_ENOUGH_COINS, ## Too poor.
	NONE_OWNED, ## No snack or luck bait to use.
	ENERGY_FULL, ## A snack would be wasted.
}

## Which gear list a purchase targets.
enum GearKind { ROD, BAIT }

var _data: GameData
var _state: GameState


## Builds the economy over [param data] and [param state].
func _init(data: GameData, state: GameState) -> void:
	_data = data
	_state = state


## Sells every fish in the bag.
func sell_all() -> Result:
	if _state.bag.is_empty():
		return Result.EMPTY_BAG
	var value: int = _state.bag_value()
	var count: int = _state.bag.size()
	_state.coins += value
	_state.bag.clear()
	_state.stats_earned += value
	fish_sold.emit(count, value)
	return Result.OK


## Buys a rod or bait and equips it; an owned one is just equipped.
func buy_gear(kind: GearKind, id: String) -> Result:
	var owned: PackedStringArray = _state.rods_owned if kind == GearKind.ROD else _state.baits_owned
	if owned.has(id):
		_equip(kind, id)
		return Result.EQUIPPED
	var entry: GameData.ShopEntry
	if kind == GearKind.ROD:
		entry = _data.rod_by_id(id)
	else:
		entry = _data.bait_by_id(id)
	var blocked: Result = _purchase_blocker(entry)
	if blocked != Result.OK:
		return blocked
	_state.coins -= entry.price
	owned.append(id)
	if kind == GearKind.ROD:
		_state.rods_owned = owned
	else:
		_state.baits_owned = owned
	_equip(kind, id)
	return Result.OK


## Buys one consumable item (a snack or a luck bait).
func buy_item(id: String) -> Result:
	var item: GameData.Item = _data.item_by_id(id)
	var blocked: Result = _purchase_blocker(item)
	if blocked != Result.OK:
		return blocked
	_state.coins -= item.price
	if item.effect == "snack":
		_state.snacks += 1
	else:
		_state.luck_baits += 1
	return Result.OK


## Eats a snack: +snack_energy, capped at energy_max.
func eat_snack() -> Result:
	if _state.snacks <= 0:
		return Result.NONE_OWNED
	var energy_max: float = _data.fixed("energy_max")
	if _state.energy >= energy_max:
		return Result.ENERGY_FULL
	_state.snacks -= 1
	_state.energy = minf(energy_max, _state.energy + _data.tune("snack_energy"))
	return Result.OK


## Uses a luck bait: adds luck_minutes of better rare odds.
func use_luck() -> Result:
	if _state.luck_baits <= 0:
		return Result.NONE_OWNED
	_state.luck_baits -= 1
	_state.luck_left += _data.tune("luck_minutes")
	return Result.OK


func _purchase_blocker(entry: GameData.ShopEntry) -> Result:
	if _state.level < entry.level:
		return Result.LOCKED_BY_LEVEL
	if _state.coins < entry.price:
		return Result.NOT_ENOUGH_COINS
	return Result.OK


func _equip(kind: GearKind, id: String) -> void:
	if kind == GearKind.ROD:
		_state.rod = id
	else:
		_state.bait = id
