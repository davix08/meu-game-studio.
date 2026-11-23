extends SceneTree
## Makes the light versions of the heavy models (2026-11-22, phones stuttered while walking):
## the owner's cow and horse (about 50 000 triangles each) and the farmer's baked parts (54 000
## in all) are simplified with Godot's mesh simplifier (ImporterMesh.generate_lods) to about
## `ratio` of their triangles, keeping the same vertices (colors, UVs) and look.
## Usage: godot --headless --path <project> -s res://tools/asset-pipeline/bake_low_poly.gd

const RATIO := 0.12

func _init() -> void:
	var look := WorldLook.load_file()
	AnimalModels._use_full = true
	for id: String in ["vaca", "cavalo"]:
		var src: ArrayMesh = AnimalModels._build(look, id, false)
		var low: ArrayMesh = _simplify(src, RATIO)
		low.surface_set_material(0, src.surface_get_material(0))
		print(id, " ", _tris(src), " -> ", _tris(low), " ", ResourceSaver.save(low, "res://assets/animals/%s_leve.res" % id, ResourceSaver.FLAG_COMPRESS))
	var dir := "res://assets/characters/fazendeiro_partes"
	DirAccess.make_dir_recursive_absolute(dir + "_leve")
	for part: String in ["hat", "head", "torso", "arm_l", "arm_r", "leg_l", "leg_r", "boot_l", "boot_r"]:
		var path: String = "%s/%s.res" % [dir, part]
		if not ResourceLoader.exists(path):
			continue
		var m: ArrayMesh = load(path)
		var low2: ArrayMesh = _simplify(m, 0.18)
		print(part, " ", _tris(m), " -> ", _tris(low2), " ", ResourceSaver.save(low2, "%s_leve/%s.res" % [dir, part], ResourceSaver.FLAG_COMPRESS))
	quit()


func _tris(m: Mesh) -> int:
	var a: Array = m.surface_get_arrays(0)
	return (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


func _simplify(src: Mesh, ratio: float) -> ArrayMesh:
	var arrays: Array = src.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_INDEX] == null:
		var n: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var idx := PackedInt32Array()
		idx.resize(n)
		for i in n:
			idx[i] = i
		arrays[Mesh.ARRAY_INDEX] = idx
	# Merge vertices at the same position first so the simplifier can collapse edges.
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.index()
	arrays = st.commit_to_arrays()
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	im.generate_lods(25.0, 60.0, [])
	var target: int = int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() * ratio)
	var best: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for l in im.get_surface_lod_count(0):
		var ids: PackedInt32Array = im.get_surface_lod_indices(0, l)
		if absi(ids.size() - target) < absi(best.size() - target):
			best = ids
	arrays[Mesh.ARRAY_INDEX] = best
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out
