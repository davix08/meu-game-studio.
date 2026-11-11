class_name LakeWorld
extends Node3D
## The whole 3D world of Lago Esmeralda, assembled in code: logical grid, terrain, water,
## props, one warm directional light with soft shadow, late-afternoon sky, ambient light and
## light fog, plus the optional chimney smoke. No day/night cycle (a later story).
##
## Story 002 (design/game-brief.md, MVP feature 9). Performance knobs (shadow atlas size,
## MSAA, render scale) come from world_look.json.
##
## Usage:
## [codeblock]
## var world := LakeWorld.new()
## add_child(world)
## world.build(look)
## var y: float = world.terrain.ground_height_at(9.5, 7.6)
## [/codeblock]

## The logical grid: the only source of collision and water truth.
var grid: WorldGrid
## The ground, for height queries.
var terrain: LakeTerrain
## The fishing question interface over [member grid] (positions in 2D pixel units).
var query: LakeWorldQuery

var _smoke: Array[MeshInstance3D] = []
var _smoke_origin: Vector3 = Vector3.ZERO
var _smoke_rise: float = 0.0
var _smoke_speed: float = 0.0
var _smoke_size: float = 0.0
var _smoke_drift: float = 0.0
var _smoke_time: float = 0.0


## Builds the grid, the 3D scene content, the light and the environment.
func build(look: WorldLook) -> void:
	grid = WorldGrid.new()
	query = LakeWorldQuery.new(grid)
	terrain = LakeTerrain.new()
	add_child(terrain)
	terrain.build(grid, look)
	var water := LakeWater.new()
	add_child(water)
	water.build(terrain, look)
	var props := LakeProps.new()
	add_child(props)
	props.build(grid, terrain, look)
	_build_light(look)
	_build_environment(look)
	_build_smoke(look)


func _process(delta: float) -> void:
	if _smoke.is_empty():
		return
	_smoke_time += delta * _smoke_speed
	for i in _smoke.size():
		var t: float = fmod(_smoke_time + float(i) / float(_smoke.size()), 1.0)
		var puff: MeshInstance3D = _smoke[i]
		puff.position = _smoke_origin + Vector3(t * _smoke_drift + sin(t * 6.0 + float(i)) * 0.15, t * _smoke_rise, 0.0)
		# Grows then shrinks to nothing, so no transparency is needed.
		puff.scale = Vector3.ONE * (sin(t * PI) * _smoke_size)


func _build_light(look: WorldLook) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = look.color("light", "color")
	sun.light_energy = look.num("light", "energy")
	sun.rotation_degrees = Vector3(-look.num("light", "pitch_degrees"), look.num("light", "yaw_degrees"), 0.0)
	sun.shadow_enabled = look.integer("light", "shadow_enabled") == 1
	sun.shadow_blur = look.num("light", "shadow_blur")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = look.num("light", "shadow_max_distance")
	add_child(sun)
	RenderingServer.directional_shadow_atlas_set_size(look.integer("light", "shadow_atlas_size"), false)


func _build_environment(look: WorldLook) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = look.color("environment", "sky_top_color")
	sky_material.sky_horizon_color = look.color("environment", "sky_horizon_color")
	sky_material.ground_horizon_color = look.color("environment", "ground_horizon_color")
	sky_material.ground_bottom_color = look.color("environment", "ground_bottom_color")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = look.color("environment", "ambient_color")
	env.ambient_light_energy = look.num("environment", "ambient_energy")
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.fog_enabled = true
	env.fog_light_color = look.color("environment", "fog_color")
	env.fog_density = look.num("environment", "fog_density")
	env.fog_sky_affect = look.num("environment", "fog_sky_affect")
	var holder := WorldEnvironment.new()
	holder.environment = env
	add_child(holder)


## Chimney smoke: a few puffs that rise, drift and shrink (optional; count 0 turns it off).
func _build_smoke(look: WorldLook) -> void:
	var count: int = look.integer("smoke", "count")
	if count <= 0:
		return
	_smoke_origin = PropMeshes.chimney_top(look)
	_smoke_rise = look.num("smoke", "rise")
	_smoke_speed = look.num("smoke", "speed")
	_smoke_size = look.num("smoke", "size")
	_smoke_drift = look.num("smoke", "drift")
	var puff_color: Color = look.color("colors", "smoke")
	var builder := MeshBuilder.new()
	builder.add_ellipsoid(Vector3.ZERO, Vector3(1.0, 0.85, 1.0), puff_color, puff_color, 8, 5, true)
	var puff_mesh: ArrayMesh = builder.build()
	var material: StandardMaterial3D = MeshBuilder.make_material(look.num("props", "roughness"))
	for i in count:
		var puff := MeshInstance3D.new()
		puff.mesh = puff_mesh
		puff.material_override = material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		_smoke.append(puff)
