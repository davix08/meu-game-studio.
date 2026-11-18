# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
# Date: 2026-11-18
# The tension fight, as pure logic so it can be simulated headless.
#   d        : fish distance, 1.0 = where it was hooked, 0 = landed, >= ESCAPE_D = gone
#   tension  : line tension, >= 1.0 for BREAK_TIME seconds snaps the line
#   stamina  : fish energy 1 -> 0; a tired fish pulls less
class_name Fight
extends RefCounted

const REEL_SPEED := 0.15
const BREAK_TIME := 0.35
const ESCAPE_D := 1.3
const TENSION_RATE := 2.4

var strength := 0.5
var surge_rate := 0.3
var d := 1.0
var tension := 0.0
var stamina := 1.0
var over := 0.0 # seconds spent at/over the break limit
var surge_t := 0.0
var pull := 0.0
var result := "" # "", "caught", "broke", "escaped"
var _rng: RandomNumberGenerator


func _init(p_strength: float, p_surge_rate: float, rng: RandomNumberGenerator) -> void:
	strength = p_strength
	surge_rate = p_surge_rate
	_rng = rng


func surging() -> bool:
	return surge_t > 0.0


func step(dt: float, reeling: bool) -> String:
	if result != "":
		return result
	if surge_t > 0.0:
		surge_t -= dt
	elif _rng.randf() < surge_rate * dt:
		surge_t = _rng.randf_range(0.5, 1.1)
	pull = strength * (1.9 if surge_t > 0.0 else 1.0) * (0.35 + 0.65 * stamina)
	var target := (0.2 + pull * 0.95) if reeling else pull * 0.25
	tension = move_toward(tension, target, TENSION_RATE * dt)
	if reeling:
		d -= REEL_SPEED * maxf(0.08, 1.0 - 0.55 * pull) * dt
	else:
		d += pull * 0.07 * dt
	if tension > 0.35:
		stamina = maxf(0.0, stamina - 0.07 * tension * dt)
	if tension >= 1.0:
		over += dt
	else:
		over = maxf(0.0, over - dt * 0.5)
	if over >= BREAK_TIME:
		result = "broke"
	elif d <= 0.0:
		result = "caught"
	elif d >= ESCAPE_D:
		result = "escaped"
	return result
