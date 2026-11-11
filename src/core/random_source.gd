class_name RandomSource
extends RefCounted
## Seeded random number generator (mulberry32), bit-identical to the 2D prototype's rng().
##
## Every gameplay random draw goes through one injected instance, so a run is
## repeatable from its seed. Never call the global randf() in game logic.
## Not thread-safe: each instance belongs to one game simulation.
##
## Usage:
## [codeblock]
## var rng := RandomSource.new(1)
## var roll: float = rng.next_float()  # 0.0 <= roll < 1.0
## [/codeblock]

const _MASK_32: int = 0xFFFFFFFF
const _MASK_16: int = 0xFFFF

var _state: int = 0


## Creates a generator from [param seed_value] (only its low 32 bits are used).
func _init(seed_value: int = 1) -> void:
	_state = seed_value & _MASK_32


## Returns the next number in [0, 1), the same sequence as mulberry32 in JavaScript.
func next_float() -> float:
	_state = (_state + 0x6D2B79F5) & _MASK_32
	var t: int = _imul(_state ^ (_state >> 15), _state | 1)
	t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _MASK_32)) & _MASK_32
	return float((t ^ (t >> 14)) & _MASK_32) / 4294967296.0


## 32-bit wrapping multiply (JavaScript Math.imul) on unsigned 32-bit ints,
## split in 16-bit halves so the 64-bit product never overflows.
static func _imul(a: int, b: int) -> int:
	var low: int = (a & _MASK_16) * b
	var high: int = (((a >> 16) * b) & _MASK_16) << 16
	return (low + high) & _MASK_32
