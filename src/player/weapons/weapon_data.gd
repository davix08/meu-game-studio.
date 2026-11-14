class_name WeaponData
extends Resource
## Tunable values for one player weapon. Data lives in assets/data/player/.

@export var display_name: String = "Lanca de Luz"
@export_group("Normal shot")
@export var damage: int = 4
## Seconds between shots.
@export var fire_interval: float = 0.11
@export var projectile_speed: float = 1700.0
@export var projectile_radius: float = 9.0
@export var projectile_lifetime: float = 1.0
## Max random vertical offset (pixels) so a stream of shots reads as a spray.
@export var spread_pixels: float = 6.0
@export var color: Color = Color(0.75, 0.9, 1.0)

@export_group("EX shot (1 card)")
@export var ex_damage: int = 28
@export var ex_speed: float = 1100.0
@export var ex_radius: float = 26.0
@export var ex_color: Color = Color(0.55, 0.8, 1.0)

@export_group("Super (full meter)")
## Damage per tick while the super beam is active.
@export var super_tick_damage: int = 12
@export var super_tick_interval: float = 0.08
@export var super_duration: float = 1.1
@export var super_length: float = 1400.0
@export var super_width: float = 90.0
@export var super_color: Color = Color(1.0, 0.95, 0.7)
