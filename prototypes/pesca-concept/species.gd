# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
# Date: 2026-11-18
# Four original placeholder species. Hardcoded on purpose (prototype).
class_name Species
extends RefCounted

const LIST := [
	{"id": "lambari", "name": "Lambari-prata", "rarity": "Comum", "weight": 50.0,
		"strength": 0.32, "surge": 0.2, "size": Vector2(8, 16), "k": 0.012, "value": 4, "color": Color("c9d6de")},
	{"id": "tilapia", "name": "Tilápia-do-cais", "rarity": "Comum", "weight": 30.0,
		"strength": 0.5, "surge": 0.35, "size": Vector2(18, 34), "k": 0.016, "value": 10, "color": Color("8fa6a0")},
	{"id": "traira", "name": "Traíra-listrada", "rarity": "Incomum", "weight": 15.0,
		"strength": 0.68, "surge": 0.5, "size": Vector2(25, 48), "k": 0.011, "value": 22, "color": Color("6b7a3c")},
	{"id": "robalo", "name": "Robalo-dourado", "rarity": "Raro", "weight": 5.0,
		"strength": 0.85, "surge": 0.6, "size": Vector2(40, 80), "k": 0.010, "value": 60, "color": Color("e0b347")},
]


## Picks a species. Longer casts (power) and a perfect cast favour rarer fish.
static func pick(rng: RandomNumberGenerator, power: float, perfect: bool) -> Dictionary:
	var weights: Array[float] = []
	var total := 0.0
	for i in LIST.size():
		var w: float = LIST[i]["weight"] * (1.0 + power * 1.5 * i)
		if perfect and i >= 2:
			w *= 2.0
		weights.append(w)
		total += w
	var r := rng.randf() * total
	for i in LIST.size():
		r -= weights[i]
		if r <= 0.0:
			return LIST[i]
	return LIST[0]
