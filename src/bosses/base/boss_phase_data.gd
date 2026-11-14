class_name BossPhaseData
extends Resource
## One phase of a boss fight. A phase starts when the boss's health fraction
## drops to or below [member start_health_fraction].

@export var display_name: String = "Fase"
## 1.0 for the first phase, then e.g. 0.66 and 0.33.
@export_range(0.0, 1.0) var start_health_fraction: float = 1.0
## Attack ids performed in order, looping. Each id maps to a method in the boss script.
@export var attacks: PackedStringArray = PackedStringArray()
## Seconds of rest between two attacks.
@export var attack_cooldown: float = 1.6
## Speed multiplier for this phase's projectiles.
@export var projectile_speed_scale: float = 1.0
## Every Nth projectile of a volley is parryable (0 = none).
@export var parryable_every: int = 3
## Tint applied to the boss visual during this phase.
@export var tint: Color = Color.WHITE
