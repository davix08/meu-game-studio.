class_name ChimneySmoke
extends Node3D
## A few smoke puffs that rise, drift and shrink above a chimney (no transparency needed).
## Sizes and speeds from the "smoke" group of world_look.json. Used by the restaurant and the
## workshop (Stories 011 and 014).
##
## Usage:
## [codeblock]
## var smoke := ChimneySmoke.new()
## add_child(smoke)
## smoke.setup(look, Vector3(60.0, 4.6, 5.3))
## [/codeblock]

var _puffs: Array[MeshInstance3D] = []
var _rise: float = 0.0
var _speed: float = 0.0
var _size: float = 0.0
var _drift: float = 0.0
var _time: float = 0.0


## Creates the puffs at [param origin] (world position of the chimney top).
func setup(look: WorldLook, origin: Vector3) -> void:
	position = origin
	_rise = look.num("smoke", "rise")
	_speed = look.num("smoke", "speed")
	_size = look.num("smoke", "size")
	_drift = look.num("smoke", "drift")
	var color: Color = look.color("colors", "smoke")
	var builder := MeshBuilder.new()
	builder.add_ellipsoid(Vector3.ZERO, Vector3(1.0, 0.85, 1.0), color, color, 8, 5, true)
	var puff_mesh: ArrayMesh = builder.build()
	var material: StandardMaterial3D = MeshBuilder.make_material(look.num("props", "roughness"))
	for i in look.integer("smoke", "count"):
		var puff := MeshInstance3D.new()
		puff.mesh = puff_mesh
		puff.material_override = material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		_puffs.append(puff)


func _process(delta: float) -> void:
	if _puffs.is_empty() or not visible:
		return
	_time += delta * _speed
	for i in _puffs.size():
		var t: float = fmod(_time + float(i) / float(_puffs.size()), 1.0)
		var puff: MeshInstance3D = _puffs[i]
		puff.position = Vector3(t * _drift + sin(t * 6.0 + float(i)) * 0.15, t * _rise, 0.0)
		puff.scale = Vector3.ONE * maxf(sin(t * PI) * _size, 0.001)
