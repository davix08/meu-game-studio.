class_name MeshBuilder
extends RefCounted
## Collects triangles with vertex colors and builds one [ArrayMesh]. All the 3D models of
## Story 002 (trees, house, pier, fisherman...) are made with it, so each model is one draw call.
##
## Triangle winding is chosen automatically from the side that must be visible (the
## "outward" hint, or the vertex normals), so callers never have to get winding right.
##
## Usage:
## [codeblock]
## var mb := MeshBuilder.new()
## mb.add_box(Vector3(0, 0.5, 0), Vector3(1, 1, 1), Color.RED)
## var mesh: ArrayMesh = mb.build()
## [/codeblock]

var _vertices: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _indices: PackedInt32Array = PackedInt32Array()
## Per-vertex face coordinates in meters (UV) and the face size (UV2), filled by
## [method add_box] only; the pixel furniture shader draws edges and pixels from them.
var _uvs: PackedVector2Array = PackedVector2Array()
var _uv2s: PackedVector2Array = PackedVector2Array()
var _has_uv: bool = false


## A material that shows the vertex colors, lit, with no specular and no face culling (so a
## wrong winding can never make a model disappear).
static func make_material(roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = roughness
	return mat


## Adds a flat triangle. When [param outward] is not zero, the triangle faces that way.
func add_triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, outward: Vector3 = Vector3.ZERO) -> void:
	var normal: Vector3 = (c - a).cross(b - a)
	if outward != Vector3.ZERO and normal.dot(outward) < 0.0:
		var swap: Vector3 = b
		b = c
		c = swap
		normal = (c - a).cross(b - a)
	normal = normal.normalized()
	var first: int = _vertices.size()
	_add_vertex(a, normal, color)
	_add_vertex(b, normal, color)
	_add_vertex(c, normal, color)
	_indices.append(first)
	_indices.append(first + 1)
	_indices.append(first + 2)


## Adds a flat quad; the four corners go around the quad in order.
func add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, outward: Vector3 = Vector3.ZERO) -> void:
	add_triangle(a, b, c, color, outward)
	add_triangle(a, c, d, color, outward)


## Adds an axis-aligned box.
func add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var lo: Vector3 = center - size * 0.5
	var hi: Vector3 = center + size * 0.5
	var p000 := Vector3(lo.x, lo.y, lo.z)
	var p001 := Vector3(lo.x, lo.y, hi.z)
	var p010 := Vector3(lo.x, hi.y, lo.z)
	var p011 := Vector3(lo.x, hi.y, hi.z)
	var p100 := Vector3(hi.x, lo.y, lo.z)
	var p101 := Vector3(hi.x, lo.y, hi.z)
	var p110 := Vector3(hi.x, hi.y, lo.z)
	var p111 := Vector3(hi.x, hi.y, hi.z)
	var faces: Array = [
		[p100, p110, p111, p101, Vector3.RIGHT, 2, 1], [p000, p001, p011, p010, Vector3.LEFT, 2, 1],
		[p010, p011, p111, p110, Vector3.UP, 0, 2], [p000, p100, p101, p001, Vector3.DOWN, 0, 2],
		[p001, p101, p111, p011, Vector3.BACK, 0, 1], [p000, p010, p110, p100, Vector3.FORWARD, 0, 1],
	]
	_has_uv = true
	for f: Array in faces:
		var first: int = _vertices.size()
		add_quad(f[0], f[1], f[2], f[3], color, f[4])
		var u: int = f[5]
		var v: int = f[6]
		var face_size := Vector2(size[u], size[v])
		for i in range(first, _vertices.size()):
			var local: Vector3 = _vertices[i] - lo
			_uvs[i] = Vector2(local[u], local[v])
			_uv2s[i] = face_size


## Adds a smooth-shaded vertical cone or cylinder (a frustum) standing on [param base]. The
## color goes from [param color_bottom] to [param color_top]. Optional flat caps.
func add_cone(base: Vector3, radius_bottom: float, radius_top: float, height: float, color_bottom: Color, color_top: Color, segments: int, cap_top: bool = false, cap_bottom: bool = false) -> void:
	var slope: float = (radius_bottom - radius_top) / maxf(height, 0.0001)
	var first: int = _vertices.size()
	for s in range(segments + 1):
		var phi: float = TAU * float(s) / float(segments)
		var dir := Vector3(cos(phi), 0.0, sin(phi))
		var normal: Vector3 = Vector3(dir.x, slope, dir.z).normalized()
		_add_vertex(base + dir * radius_bottom, normal, color_bottom)
		_add_vertex(base + dir * radius_top + Vector3(0.0, height, 0.0), normal, color_top)
	for s in range(segments):
		var i: int = first + s * 2
		_add_indexed(i, i + 2, i + 3)
		_add_indexed(i, i + 3, i + 1)
	if cap_top and radius_top > 0.0:
		_add_disc(base + Vector3(0.0, height, 0.0), radius_top, color_top, Vector3.UP, segments)
	if cap_bottom and radius_bottom > 0.0:
		_add_disc(base, radius_bottom, color_bottom, Vector3.DOWN, segments)


## Adds an ellipsoid. Smooth shading gives round foliage; flat shading gives faceted rocks.
## The color goes from [param color_low] (bottom) to [param color_high] (top).
func add_ellipsoid(center: Vector3, radii: Vector3, color_low: Color, color_high: Color, segments: int, rings: int, smooth: bool) -> void:
	var units: Array[Vector3] = []
	for r in range(rings + 1):
		var theta: float = PI * float(r) / float(rings)
		for s in range(segments + 1):
			var phi: float = TAU * float(s) / float(segments)
			units.append(Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)))
	var row: int = segments + 1
	if smooth:
		var first: int = _vertices.size()
		for unit: Vector3 in units:
			var normal: Vector3 = (unit / radii).normalized()
			_add_vertex(center + unit * radii, normal, color_low.lerp(color_high, (unit.y + 1.0) * 0.5))
		for r in range(rings):
			for s in range(segments):
				var i: int = first + r * row + s
				_add_indexed(i, i + 1, i + row + 1)
				_add_indexed(i, i + row + 1, i + row)
	else:
		for r in range(rings):
			for s in range(segments):
				var i: int = r * row + s
				var u00: Vector3 = units[i]
				var u01: Vector3 = units[i + 1]
				var u11: Vector3 = units[i + row + 1]
				var u10: Vector3 = units[i + row]
				var mid_y: float = (u00.y + u11.y) * 0.5
				var color: Color = color_low.lerp(color_high, (mid_y + 1.0) * 0.5)
				var outward: Vector3 = (u00 + u01 + u11 + u10) / radii
				add_quad(center + u00 * radii, center + u01 * radii, center + u11 * radii, center + u10 * radii, color, outward)


## Adds everything of [param other], moved by [param xform] (to lay a shape on its side).
func append_transformed(other: MeshBuilder, xform: Transform3D) -> void:
	var first: int = _vertices.size()
	for i in other._vertices.size():
		_vertices.append(xform * other._vertices[i])
		_normals.append((xform.basis * other._normals[i]).normalized())
		_colors.append(other._colors[i])
		_uvs.append(other._uvs[i])
		_uv2s.append(other._uv2s[i])
	_has_uv = _has_uv or other._has_uv
	for index: int in other._indices:
		_indices.append(first + index)


## Builds the mesh from everything added so far.
func build() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	if _has_uv:
		arrays[Mesh.ARRAY_TEX_UV] = _uvs
		arrays[Mesh.ARRAY_TEX_UV2] = _uv2s
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_vertex(pos: Vector3, normal: Vector3, color: Color) -> int:
	_vertices.append(pos)
	_normals.append(normal)
	_colors.append(color)
	_uvs.append(Vector2.ZERO)
	_uv2s.append(Vector2.ZERO)
	return _vertices.size() - 1


## Adds a triangle between existing vertices, flipping it so it faces along the vertex normals.
func _add_indexed(i0: int, i1: int, i2: int) -> void:
	var front: Vector3 = (_vertices[i2] - _vertices[i0]).cross(_vertices[i1] - _vertices[i0])
	var wanted: Vector3 = _normals[i0] + _normals[i1] + _normals[i2]
	if front.dot(wanted) < 0.0:
		var swap: int = i1
		i1 = i2
		i2 = swap
	_indices.append(i0)
	_indices.append(i1)
	_indices.append(i2)


func _add_disc(center: Vector3, radius: float, color: Color, normal: Vector3, segments: int) -> void:
	var hub: int = _add_vertex(center, normal, color)
	var first: int = _vertices.size()
	for s in range(segments + 1):
		var phi: float = TAU * float(s) / float(segments)
		_add_vertex(center + Vector3(cos(phi), 0.0, sin(phi)) * radius, normal, color)
	for s in range(segments):
		_add_indexed(hub, first + s, first + s + 1)
