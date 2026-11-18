class_name Decor
extends RefCounted
## Decorating the house and yard (design/gdd/decoration.md): each slot holds one piece.
## Placing buys the piece for that slot; removing gives back refund_fraction of its
## price; placing over a piece swaps it (the old one is refunded first).
##
## Usage:
## [codeblock]
## var decor := Decor.new(data, state)
## if decor.place("casa_1", "vaso") == Decor.Result.OK: pass
## decor.remove("casa_1")
## [/codeblock]

## A slot changed (the view rebuilds that slot).
signal changed(slot_id: String)

enum Result { OK, UNKNOWN, LOCKED_BY_LEVEL, NOT_ENOUGH_COINS, SAME, EMPTY }

var _data: GameData
var _state: GameState


func _init(data: GameData, state: GameState) -> void:
	_data = data
	_state = state


## Coins returned when the piece in [param slot_id] is removed (0 when empty).
func refund(slot_id: String) -> int:
	var placed: GameData.ShopEntry = _data.decor_by_id(_state.decor.get(slot_id, ""))
	return 0 if placed == null else floori(float(placed.price) * _data.decor_refund)


## Why [param item_id] cannot go into [param slot_id] now, or OK. The refund of the piece
## already there counts toward the price.
func place_blocker(slot_id: String, item_id: String) -> Result:
	var item: GameData.ShopEntry = _data.decor_by_id(item_id)
	if item == null or not _data.decor_slots.has(slot_id):
		return Result.UNKNOWN
	if _state.decor.get(slot_id, "") == item_id:
		return Result.SAME
	if _state.level < item.level:
		return Result.LOCKED_BY_LEVEL
	if _state.coins + refund(slot_id) < item.price:
		return Result.NOT_ENOUGH_COINS
	return Result.OK


## Puts [param item_id] in [param slot_id], paying its price (minus the swap refund).
func place(slot_id: String, item_id: String) -> Result:
	var blocked: Result = place_blocker(slot_id, item_id)
	if blocked != Result.OK:
		return blocked
	_state.coins += refund(slot_id) - _data.decor_by_id(item_id).price
	_state.decor[slot_id] = item_id
	changed.emit(slot_id)
	return Result.OK


## Empties [param slot_id], refunding part of the price.
func remove(slot_id: String) -> Result:
	if not _state.decor.has(slot_id):
		return Result.EMPTY
	_state.coins += refund(slot_id)
	_state.decor.erase(slot_id)
	changed.emit(slot_id)
	return Result.OK


## The heaviest fish ever caught (species id, kg), for the trophy; ["", 0] when none.
func best_fish() -> Array:
	var best_id: String = ""
	var best_kg: float = 0.0
	for id: String in _state.book:
		if _state.book[id].best > best_kg:
			best_kg = _state.book[id].best
			best_id = id
	return [best_id, best_kg]
