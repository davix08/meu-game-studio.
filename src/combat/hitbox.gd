class_name Hitbox
extends Area2D
## Area that deals damage to overlapping [Hurtbox]es (the "DamageDealer").
##
## Checks overlaps every physics frame, so contact damage keeps applying while the
## target stays inside (the target's i-frames limit the rate).

## Emitted when this hitbox removed health from a hurtbox.
signal hit_landed(hurtbox: Hurtbox, amount: int)

## Damage per hit.
@export var damage: int = 1
## If true, stops dealing damage after the first successful hit.
@export var one_shot: bool = false
## Minimum seconds between two hits on the same hurtbox (beams, contact damage).
@export var rehit_interval: float = 0.5
## When false, the hitbox deals no damage (e.g. boss during intro).
@export var active: bool = true

var _spent: bool = false
var _last_hit_time: Dictionary = {}


func _ready() -> void:
	monitoring = true
	# Monitorable so the player's parry area can detect parryable projectiles.
	monitorable = true


func _physics_process(_delta: float) -> void:
	if not active or _spent:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	for area: Area2D in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null:
			continue
		var id: int = hurtbox.get_instance_id()
		if _last_hit_time.has(id) and now - float(_last_hit_time[id]) < rehit_interval:
			continue
		_last_hit_time[id] = now
		if hurtbox.receive_hit(self):
			hit_landed.emit(hurtbox, damage)
			_on_hit_landed(hurtbox)
			if one_shot:
				_spent = true
				return


## Override hook called after a successful hit.
func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	pass
