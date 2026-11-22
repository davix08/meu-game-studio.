class_name AnimalModels
extends RefCounted
## The owner's 3D animal models (2026-11-22, assets/animals/): the cow (with its own texture)
## and the horse (painted from the owner's reference picture into vertex colors). Each .glb is
## one mesh; [method mesh] turns it to face the wanted way, scales it to the height in
## world_look.json ("animal_models" group) and puts its feet on y = 0, centered on x and z,
## keeping its material (or a vertex-color material when it has none). Cached per id and facing.
##
## Usage:
## [codeblock]
## var cow: ArrayMesh = AnimalModels.mesh(look, "vaca", true)   # faces +x
## var horse: ArrayMesh = AnimalModels.mesh(look, "cavalo", false)  # faces +z
## [/codeblock]

const GROUP: String = "animal_models"

static var _cache: Dictionary = {}


## The model [param id] as one mesh facing +x ([param face_x]) or +z, or null when the file is
## missing or has no mesh (the caller then keeps its block model).
static func mesh(look: WorldLook, id: String, face_x: bool) -> ArrayMesh:
	var key: String = "%s:%s" % [id, face_x]
	if _cache.has(key):
		return _cache[key]
	var out: ArrayMesh = _build(look, id, face_x)
	_cache[key] = out
	return out


static func _build(look: WorldLook, id: String, face_x: bool) -> ArrayMesh:
	if not look.has(GROUP, id):
		return null
	var d: Dictionary = look.raw(GROUP, id)
	var path: String = str(d.get("path", ""))
	if not ResourceLoader.exists(path):
		push_warning("AnimalModels: missing %s" % path)
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var root: Node = scene.instantiate()
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		root.free()
		return null
	var mi: MeshInstance3D = found[0]
	var src: Mesh = mi.mesh
	var material: Material = mi.get_active_material(0)
	# Transform of the mesh inside the file, then the turn to face +z (yaw_degrees) and +x.
	var xform: Transform3D = Transform3D.IDENTITY
	var n: Node = mi
	while n != null and n is Node3D:
		xform = (n as Node3D).transform * xform
		n = n.get_parent()
	root.free()
	var yaw: float = deg_to_rad(float(d.get("yaw_degrees", 0.0))) + (PI * 0.5 if face_x else 0.0)
	var basis: Basis = Basis(Vector3.UP, yaw) * xform.basis
	var arrays: Array = src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for i in verts.size():
		var v: Vector3 = basis * verts[i]
		lo = lo.min(v)
		hi = hi.max(v)
	var s: float = float(d.get("height", 1.0)) / maxf(hi.y - lo.y, 0.001)
	var shift := Vector3(-(lo.x + hi.x) * 0.5, -lo.y, -(lo.z + hi.z) * 0.5)
	for i in verts.size():
		verts[i] = (basis * verts[i] + shift) * s
	arrays[Mesh.ARRAY_VERTEX] = verts
	if arrays[Mesh.ARRAY_NORMAL] != null:
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in normals.size():
			normals[i] = (basis * normals[i]).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = null
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var has_texture: bool = material is BaseMaterial3D and (material as BaseMaterial3D).albedo_texture != null
	if not has_texture and arrays[Mesh.ARRAY_COLOR] != null:
		var vc := StandardMaterial3D.new()
		vc.vertex_color_use_as_albedo = true
		vc.roughness = 0.9
		material = vc
	if material is BaseMaterial3D:
		# glTF files that do not say "metallic" are fully metallic, which renders black under
		# the farm sky: the animals are matte.
		material = (material as BaseMaterial3D).duplicate()
		(material as BaseMaterial3D).metallic = 0.0
		(material as BaseMaterial3D).roughness = 0.9
		(material as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	out.surface_set_material(0, material)
	return out


## A horse node from the owner's model: child 0 is the mesh (faces +z), animated by the caller.
## Falls back to the block horse of [VoxelModels] when the file is missing.
static func horse_node(look: WorldLook, fallback_coat: Color, fallback_material: Material) -> Node3D:
	var rig: AnimalRig = AnimalRig.create(look, "cavalo", false)
	if rig != null:
		return rig
	var m: ArrayMesh = mesh(look, "cavalo", false)
	if m == null:
		return VoxelModels.horse(look, fallback_coat, fallback_material)
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.mesh = m
	root.add_child(body)
	return root


## The model [param id] (facing +z) cut into animated parts by the "animal_rigs" data: body,
## head (with the neck), tail and four legs (fl, fr, bl, br). Each triangle goes to the part of
## its center. Returns {"parts": {name: ArrayMesh}, "pivots": {name: Vector3}, "material"}; the
## part meshes are relative to their pivot. {} when the model or its rig data is missing.
static func rig_parts(look: WorldLook, id: String) -> Dictionary:
	var key: String = "rig:" + id
	if _cache.has(key):
		return _cache[key]
	var out: Dictionary = {}
	var whole: ArrayMesh = mesh(look, id, false)
	if whole != null and look.has("animal_rigs", id):
		out = _cut(whole, look.raw("animal_rigs", id))
	_cache[key] = out
	return out


static func _cut(whole: ArrayMesh, rig: Dictionary) -> Dictionary:
	var arrays: Array = whole.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		indices.resize(verts.size())
		for i in verts.size():
			indices[i] = i
	var belly: float = float(rig["belly_y"])
	var front: Array = rig["front_z"]
	var back: Array = rig["back_z"]
	var head_z: float = float(rig["head_z"])
	var head_y: float = float(rig["head_y"])
	var tail_z: float = float(rig["tail_z"])
	var tail_y: float = float(rig.get("tail_max_y", 99.0))
	var names: Array[String] = ["body", "head", "tail", "fl", "fr", "bl", "br"]
	var tris: Dictionary = {}
	var sums: Dictionary = {}
	for n: String in names:
		tris[n] = PackedInt32Array()
		sums[n] = Vector4.ZERO
	for t in range(0, indices.size() - 2, 3):
		var c: Vector3 = (verts[indices[t]] + verts[indices[t + 1]] + verts[indices[t + 2]]) / 3.0
		var part: String = "body"
		if c.y < belly and c.z > float(front[0]) and c.z < float(front[1]):
			part = "fl" if c.x > 0.0 else "fr"
		elif c.y < belly and c.z > float(back[0]) and c.z < float(back[1]):
			part = "bl" if c.x > 0.0 else "br"
		elif c.z > head_z and c.y > head_y:
			part = "head"
		elif c.z < tail_z and c.y < tail_y:
			part = "tail"
		var list: PackedInt32Array = tris[part]
		list.append(t)
		tris[part] = list
		var sum: Vector4 = sums[part]
		sums[part] = sum + Vector4(c.x, c.y, c.z, 1.0)
	var hp: Array = rig["head_pivot"]
	var tp: Array = rig["tail_pivot"]
	var pivots: Dictionary = {"body": Vector3.ZERO, "head": Vector3(0.0, float(hp[0]), float(hp[1])), "tail": Vector3(0.0, float(tp[0]), float(tp[1]))}
	for leg: String in ["fl", "fr", "bl", "br"]:
		var s: Vector4 = sums[leg]
		var mean := Vector3(s.x, s.y, s.z) / maxf(s.w, 1.0)
		pivots[leg] = Vector3(mean.x, belly, mean.z)
	var parts: Dictionary = {}
	var remap := PackedInt32Array()
	remap.resize(verts.size())
	for n: String in names:
		var list: PackedInt32Array = tris[n]
		if list.is_empty():
			continue
		remap.fill(-1)
		var pivot: Vector3 = pivots[n]
		var outs: Array = []
		outs.resize(Mesh.ARRAY_MAX)
		var pv := PackedVector3Array()
		var pi := PackedInt32Array()
		var extra: Dictionary = {}
		for slot: int in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_COLOR]:
			if arrays[slot] != null:
				extra[slot] = []
		for t: int in list:
			for k in 3:
				var v: int = indices[t + k]
				if remap[v] < 0:
					remap[v] = pv.size()
					pv.append(verts[v] - pivot)
					for slot: int in extra:
						(extra[slot] as Array).append(arrays[slot][v])
				pi.append(remap[v])
		outs[Mesh.ARRAY_VERTEX] = pv
		outs[Mesh.ARRAY_INDEX] = pi
		if extra.has(Mesh.ARRAY_NORMAL):
			outs[Mesh.ARRAY_NORMAL] = PackedVector3Array(extra[Mesh.ARRAY_NORMAL])
		if extra.has(Mesh.ARRAY_TEX_UV):
			outs[Mesh.ARRAY_TEX_UV] = PackedVector2Array(extra[Mesh.ARRAY_TEX_UV])
		if extra.has(Mesh.ARRAY_COLOR):
			outs[Mesh.ARRAY_COLOR] = PackedColorArray(extra[Mesh.ARRAY_COLOR])
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, outs)
		parts[n] = m
	return {"parts": parts, "pivots": pivots, "material": whole.surface_get_material(0)}
