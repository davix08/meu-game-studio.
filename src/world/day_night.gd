class_name DayNight
extends Node3D
## Day and night in 3D (Story 008): from the game clock it moves the sun (pitch, color, energy),
## tints the sky, the ambient light and the fog through the keyframes of the "daynight" group of
## world_look.json (morning, warm late afternoon, blue night, dawn), lights the windows and lamps
## at dusk, and lets fireflies float around the fisherman at night. One directional light only.
##
## Usage:
## [codeblock]
## var cycle := DayNight.new()
## add_child(cycle)
## cycle.setup(look, world, fisherman)
## cycle.lights_changed.connect(func(on: bool) -> void: town_view.set_lights(on))
## cycle.update(state.minutes)   # every frame
## [/codeblock]

## The window and lamp lights turned on (dusk) or off (morning).
signal lights_changed(on: bool)

var _world: LakeWorld
var _target: Node3D
var _hours: Array = []
var _sun_energy: Array = []
var _sun_pitch: Array = []
var _sun_colors: Array[Color] = []
var _sky_top: Array[Color] = []
var _sky_horizon: Array[Color] = []
var _ambient: Array[Color] = []
var _ambient_energy: Array = []
var _fog: Array[Color] = []
var _yaw: float = 0.0
var _on_hour: float = 18.6
var _off_hour: float = 6.2
var _lights: bool = false
var _first: bool = true
var _flies: MultiMeshInstance3D
var _fly_seeds: PackedVector3Array = PackedVector3Array()
var _fly_area: float = 10.0
var _fly_height: float = 1.0
var _time: float = 0.0


## Reads the keyframes and builds the fireflies around [param target].
func setup(look: WorldLook, world: LakeWorld, target: Node3D) -> void:
	_world = world
	_target = target
	_hours = look.raw("daynight", "hours")
	_sun_energy = look.raw("daynight", "sun_energy")
	_sun_pitch = look.raw("daynight", "sun_pitch")
	_sun_colors = look.color_list("daynight", "sun_colors")
	_sky_top = look.color_list("daynight", "sky_top")
	_sky_horizon = look.color_list("daynight", "sky_horizon")
	_ambient = look.color_list("daynight", "ambient")
	_ambient_energy = look.raw("daynight", "ambient_energy")
	_fog = look.color_list("daynight", "fog")
	_yaw = look.num("daynight", "sun_yaw")
	_on_hour = look.num("daynight", "lights_on_hour")
	_off_hour = look.num("daynight", "lights_off_hour")
	_fly_area = look.num("daynight", "firefly_area")
	_fly_height = look.num("daynight", "firefly_height")
	var count: int = look.integer("daynight", "fireflies")
	var mb := MeshBuilder.new()
	var color: Color = look.color("daynight", "firefly_color")
	var size: float = look.num("daynight", "firefly_size")
	mb.add_ellipsoid(Vector3.ZERO, Vector3.ONE * size, color, color, 5, 3, true)
	var material: StandardMaterial3D = MeshBuilder.make_material(1.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mb.build()
	multi.instance_count = count
	_flies = MultiMeshInstance3D.new()
	_flies.multimesh = multi
	_flies.material_override = material
	_flies.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flies.visible = false
	add_child(_flies)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in count:
		_fly_seeds.append(Vector3(rng.randf_range(-1.0, 1.0), rng.randf(), rng.randf() * TAU))


## True while the lights are on (night).
func is_night() -> bool:
	return _lights


## Applies the light of game [param minutes] (past midnight values wrap).
func update(minutes: float) -> void:
	var hour: float = fmod(minutes / 60.0, 24.0)
	var i: int = 0
	while i < _hours.size() - 2 and hour >= float(_hours[i + 1]):
		i += 1
	var h0: float = float(_hours[i])
	var h1: float = float(_hours[i + 1])
	var t: float = clampf((hour - h0) / maxf(h1 - h0, 0.001), 0.0, 1.0)
	var sun: DirectionalLight3D = _world.sun
	sun.light_energy = lerpf(float(_sun_energy[i]), float(_sun_energy[i + 1]), t)
	sun.light_color = _sun_colors[i].lerp(_sun_colors[i + 1], t)
	sun.rotation_degrees = Vector3(-lerpf(float(_sun_pitch[i]), float(_sun_pitch[i + 1]), t), _yaw + (hour - 12.0) * 6.0, 0.0)
	_world.sky_material.sky_top_color = _sky_top[i].lerp(_sky_top[i + 1], t)
	_world.sky_material.sky_horizon_color = _sky_horizon[i].lerp(_sky_horizon[i + 1], t)
	_world.sky_material.ground_horizon_color = _sky_horizon[i].lerp(_sky_horizon[i + 1], t).darkened(0.1)
	var env: Environment = _world.environment
	env.ambient_light_color = _ambient[i].lerp(_ambient[i + 1], t)
	env.ambient_light_energy = lerpf(float(_ambient_energy[i]), float(_ambient_energy[i + 1]), t)
	env.fog_light_color = _fog[i].lerp(_fog[i + 1], t)
	var on: bool = hour >= _on_hour or hour < _off_hour
	if on != _lights or _first:
		_first = false
		_lights = on
		_flies.visible = on
		lights_changed.emit(on)


func _process(delta: float) -> void:
	if not _flies.visible:
		return
	_time += delta
	var center: Vector3 = _target.position
	var multi: MultiMesh = _flies.multimesh
	for i in _fly_seeds.size():
		var s: Vector3 = _fly_seeds[i]
		var a: float = s.z + _time * (0.3 + s.y * 0.4)
		var p := Vector3(center.x + sin(a) * _fly_area * (0.3 + absf(s.x) * 0.7), _fly_height * (0.4 + s.y) + sin(_time * 2.0 + s.z) * 0.2, center.z + cos(a * 0.8 + s.x) * _fly_area * (0.3 + s.y * 0.7))
		var glow: float = 0.6 + 0.4 * sin(_time * 5.0 + s.z * 3.0)
		multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * glow), p))
