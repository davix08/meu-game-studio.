class_name BossData
extends Resource
## Tunable values for a boss. Data lives in assets/data/bosses/.

@export var display_name: String = "Chefe"
@export var max_health: int = 1000
## Damage dealt to the player by attacks and contact.
@export var contact_damage: int = 1
@export var projectile_damage: int = 1
## Ordered from first (start_health_fraction 1.0) to last.
@export var phases: Array[BossPhaseData] = []
