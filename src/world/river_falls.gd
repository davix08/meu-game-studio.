class_name RiverFalls
extends Node3D
## The high ground where the river is born (Story 005): three stepped rock ledges past the
## north-east edge of the map, a channel of water on each ledge, three animated waterfalls and
## foam where they land; plus the pier details (bait crate, a rod leaning on the last post, rope
## to the boat). Scenery only: the ledges stand outside the [WorldGrid], so nothing here changes
## collision or fishing. Positions follow the river start in the "town" data.
##
## Usage:
## [codeblock]
## var falls := RiverFalls.new()
## add_child(falls)
## falls.build(look)
## [/codeblock]

const SHADER_PATH: String = "res://src/world/waterfall.gdshader"
const STEPS: int = 3
const STEP_RISE: float = 1.3
const STEP_DEPTH: float = 3.0


## Builds the ledges, falls and pier details.
func build(look: WorldLook) -> void:
	var points: Array = look.raw("town", "river")
	var cx: float = float(points[0][0])
	var half: float = look.num("town", "river_radius")
	var rock := MeshBuilder.new()
	var water := MeshBuilder.new()
	var dark: Color = look.color("town", "cliff_dark")
	var light: Color = look.color("town", "cliff_light")
	var pool: Color = look.color("water", "shallow_color")
	for s in STEPS:
		var top: float = STEP_RISE * float(s + 1)
		var z1: float = -0.4 - STEP_DEPTH * float(s)
		var z0: float = z1 - STEP_DEPTH
		var w: float = 7.0 - float(s)
		EstateMeshes._box(rock, cx - w, -0.5, z0 - (6.0 if s == STEPS - 1 else 0.0), cx - half, top, z1, dark.lerp(light, float(s) * 0.3))
		EstateMeshes._box(rock, cx + half, -0.5, z0 - (6.0 if s == STEPS - 1 else 0.0), cx + w, top, z1, dark.lerp(light, float(s) * 0.3))
		EstateMeshes._box(rock, cx - half, -0.5, z0, cx + half, top - 0.25, z1, dark)
		for k in 4:
			var bx: float = cx + (float(k) - 1.5) * 1.6
			rock.add_ellipsoid(Vector3(bx, top + 0.1, z1 - 0.3 - float(k % 2) * 1.6), Vector3(0.6, 0.45, 0.6), dark, light, 7, 4, true)
		water.add_quad(Vector3(cx - half, top - 0.2, z0), Vector3(cx + half, top - 0.2, z0), Vector3(cx + half, top - 0.2, z1), Vector3(cx - half, top - 0.2, z1), pool, Vector3.UP)
	var rock_node := MeshInstance3D.new()
	rock_node.mesh = rock.build()
	rock_node.material_override = MeshBuilder.make_material(look.num("props", "roughness"))
	add_child(rock_node)
	var pool_node := MeshInstance3D.new()
	pool_node.mesh = water.build()
	pool_node.material_override = MeshBuilder.make_material(0.2)
	add_child(pool_node)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	material.set_shader_parameter("water_color", look.color("town", "fall_color"))
	for s in STEPS:
		var top: float = STEP_RISE * float(s + 1)
		var z: float = -0.4 - STEP_DEPTH * float(s) + 0.05
		var fall := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(half * 2.0 - 0.3, STEP_RISE + 0.1)
		fall.mesh = quad
		fall.material_override = material
		fall.position = Vector3(cx, top - STEP_RISE * 0.5 - 0.15, z)
		fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fall)
		var foam := MeshBuilder.new()
		for k in 5:
			foam.add_ellipsoid(Vector3(cx + (float(k) - 2.0) * 0.45, top - STEP_RISE - 0.1, z + 0.35), Vector3(0.35, 0.18, 0.3), look.color("water", "foam_color"), look.color("water", "foam_color"), 6, 3, true)
		var foam_node := MeshInstance3D.new()
		foam_node.mesh = foam.build()
		foam_node.material_override = MeshBuilder.make_material(0.5)
		add_child(foam_node)
	_pier_details(look)


func _pier_details(look: WorldLook) -> void:
	var mb := MeshBuilder.new()
	var deck: float = look.num("wood", "deck_height")
	var x: float = float(WorldGrid.PIER_X) + 0.45
	var z: float = float(WorldGrid.PIER_Y1) + 0.5
	mb.add_box(Vector3(x, deck + 0.22, z), Vector3(0.55, 0.42, 0.42), look.color("colors", "wood_b"))
	mb.add_box(Vector3(x, deck + 0.45, z), Vector3(0.58, 0.05, 0.45), look.color("colors", "wood_dark"))
	for k in 3:
		mb.add_ellipsoid(Vector3(x - 0.15 + float(k) * 0.15, deck + 0.5, z), Vector3(0.06, 0.04, 0.06), look.color("estate", "veg_orange"), look.color("estate", "veg_orange"), 5, 3, true)
	var post := Vector3(float(WorldGrid.PIER_X) + 1.85, deck, float(WorldGrid.PIER_Y1) + 0.85)
	EstateMeshes._beam(mb, post + Vector3(0.0, 0.0, 0.0), post + Vector3(-0.35, 1.6, -0.5), 0.04, look.color("estate", "hub"))
	mb.add_box(post + Vector3(-0.05, 0.35, -0.08), Vector3(0.08, 0.08, 0.06), look.color("colors", "wood_dark"))
	var boat := Vector3(look.num("boat", "x"), deck - 0.1, look.num("boat", "z"))
	EstateMeshes._beam(mb, post + Vector3(0.0, 0.3, 0.0), boat, 0.025, look.color("estate", "straw"))
	var node := MeshInstance3D.new()
	node.mesh = mb.build()
	node.material_override = MeshBuilder.make_material(look.num("props", "roughness"))
	add_child(node)
