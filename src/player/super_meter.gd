class_name SuperMeter
extends RefCounted
## Super meter logic: filled by dealing damage and parrying, spent on EX/super.
##
## Value is measured in cards (0..max_cards, fractional).

var max_cards: int
var cards_per_damage: float
var cards_per_parry: float
var value: float = 0.0


func _init(p_max_cards: int = 5, p_cards_per_damage: float = 0.012, p_cards_per_parry: float = 1.0) -> void:
	max_cards = p_max_cards
	cards_per_damage = p_cards_per_damage
	cards_per_parry = p_cards_per_parry


## Adds meter for [param damage] points dealt.
func add_damage(damage: int) -> void:
	_add(float(damage) * cards_per_damage)


## Adds meter for one parry.
func add_parry() -> void:
	_add(cards_per_parry)


## Number of complete cards available.
func full_cards() -> int:
	return int(floor(value + 0.0001))


## True when the meter is completely full (super available).
func is_full() -> bool:
	return value >= float(max_cards) - 0.0001


## Spends [param cards] whole cards. Returns false (and spends nothing) if short.
func spend(cards: int) -> bool:
	if full_cards() < cards:
		return false
	value = maxf(0.0, value - float(cards))
	return true


func _add(amount: float) -> void:
	value = clampf(value + amount, 0.0, float(max_cards))
