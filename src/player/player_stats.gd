class_name PlayerStats
extends Resource
## Tunable player values. Edit assets/data/player/player_stats.tres, not code.

@export_group("Health")
@export var max_health: int = 3
## Seconds of invulnerability after taking a hit.
@export var invulnerability_time: float = 1.2
## Seconds the player loses control after a hit.
@export var hit_stun_time: float = 0.3
@export var hit_knockback: Vector2 = Vector2(260.0, -380.0)

@export_group("Movement")
@export var move_speed: float = 420.0
@export var gravity: float = 2600.0
@export var max_fall_speed: float = 1400.0
@export var jump_velocity: float = -980.0
## Vertical speed multiplier applied when jump is released while rising.
@export var jump_cut_multiplier: float = 0.45
## Seconds after leaving a ledge during which a jump still works.
@export var coyote_time: float = 0.1
## Seconds a jump press is remembered before landing.
@export var jump_buffer_time: float = 0.12

@export_group("Dash")
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.22
@export var dash_cooldown: float = 0.25

@export_group("Parry")
## Seconds after pressing jump in the air during which a parry can connect.
@export var parry_window: float = 0.18
@export var parry_bounce_velocity: float = -900.0
## Seconds of invulnerability granted by a successful parry.
@export var parry_invulnerability: float = 0.35

@export_group("Super meter")
@export var max_cards: int = 5
## Meter (in cards) gained per point of damage dealt.
@export var cards_per_damage: float = 0.012
## Meter (in cards) gained per parry.
@export var cards_per_parry: float = 1.0
