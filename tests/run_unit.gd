extends SceneTree
## Runs every tests/unit/**/*_test.gd suite (MiniSuite) and exits 1 when a test fails
## or a suite cannot load, 0 otherwise. 0 suites found is reported and exits 1: an empty
## run is not a pass.


func _init() -> void:
	var files: PackedStringArray = PackedStringArray()
	_collect("res://tests/unit", files)
	var ran: int = 0
	var failed: int = 0
	for path: String in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("LOAD FAIL %s" % path)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var suite: Object = script.new()
			suite.call(name)
			ran += 1
			var fails: PackedStringArray = suite.get("failures")
			if fails.is_empty():
				print("PASS %s::%s" % [path.get_file(), name])
			else:
				failed += 1
				print("FAIL %s::%s\n  - %s" % [path.get_file(), name, "\n  - ".join(fails)])
	print("%d tests run, %d failed, %d suites" % [ran, failed, files.size()])
	quit(1 if failed > 0 or ran == 0 else 0)


func _collect(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.ends_with("_test.gd"):
			out.append(dir_path.path_join(file))
