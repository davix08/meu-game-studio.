class_name LakeWater
extends MeshInstance3D
## The animated lake surface: one flat mesh at the water level that covers only the half-block
## quads where the terrain dips below the water. The mesh vertex color stores the depth (red
## channel, 0 at the shore, 1 at the deepest bed); [code]water.gdshader[/code] turns it into
## color, transparency, ripples, glints and shore foam. Draw calls: 1.
##
## Story 002 (design/game-brief.md, MVP feature 9).

const SHADER_PATH: String = "res://src/world/water.gdshader"


## Builds the water mesh over the lake of [param terrain] and applies the look from [param look].
func build(terrain: LakeTerrain, look: WorldLook) -> void:
	var level: float = look.num("terrain", "water_level")
	var deep_h: float = look.num("terrain", "deep_bed_height")
	var cols: int = terrain.cols
	var rows: int = terrain.rows
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var wet: PackedByteArray = PackedByteArray()
	vertices.resize(cols * rows)
	normals.resize(cols * rows)
	colors.resize(cols * rows)
	wet.resize(cols * rows)
	for j in rows:
		for i in cols:
			var n: int = j * cols + i
			var depth: float = (level - terrain.vertex_height(i, j)) / (level - deep_h)
			vertices[n] = Vector3(float(i) * LakeTerrain.STEP, level, float(j) * LakeTerrain.STEP)
			normals[n] = Vector3.UP
			colors[n] = Color(clampf(depth, 0.0, 1.0), 0.0, 0.0, 1.0)
			wet[n] = 1 if depth > 0.0 else 0
	var indices: PackedInt32Array = PackedInt32Array()
	for j in rows - 1:
		for i in cols - 1:
			var a: int = j * cols + i
			var b: int = a + 1
			var c: int = a + cols
			var d: int = c + 1
			if wet[a] + wet[b] + wet[c] + wet[d] == 0:
				continue
			indices.append(a)
			indices.append(b)
			indices.append(c)
			indices.append(b)
			indices.append(d)
			indices.append(c)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var surface := ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = surface

	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	for key: String in ["shallow_color", "deep_color", "foam_color", "glint_color"]:
		material.set_shader_parameter(key, look.color("water", key))
	for key: String in ["alpha_shallow", "alpha_deep", "wave_height", "wave_speed", "wave_scale", "foam_width", "glint_strength"]:
		material.set_shader_parameter(key, look.num("water", key))
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
