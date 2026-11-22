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
	var m: ArrayMesh = mesh(look, "cavalo", false)
	if m == null:
		return VoxelModels.horse(look, fallback_coat, fallback_material)
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.mesh = m
	root.add_child(body)
	return root
