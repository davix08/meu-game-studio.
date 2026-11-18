class_name DecorView
extends Node3D
## Shows the decorations placed in each slot (design/gdd/decoration.md), and a faint
## ring on empty slots so the player knows where pieces go. The trophy shows the
## heaviest fish caught, in its species color, scaled by its size.
##
## Usage:
## [codeblock]
## view.setup(data, state, decor, terrain)
## [/codeblock]

## Pieces over their modeled size, so they read on a phone screen next to the buildings.
const PIECE_SCALE: float = 1.5

var _data: GameData
var _state: GameState
var _decor: Decor
var _terrain: LakeTerrain
var _material: StandardMaterial3D
var _nodes: Dictionary[String, Node3D] = {}


## Builds every slot and rebuilds them when a slot changes or a fish is caught (trophy).
func setup(data: GameData, state: GameState, decor: Decor, terrain: LakeTerrain) -> void:
	_data = data
	_state = state
	_decor = decor
	_terrain = terrain
	_material = MeshBuilder.make_material(0.85)
	decor.changed.connect(_rebuild)
	state.fish_caught.connect(func(_f: GameState.Catch, _n: bool, _r: bool) -> void: refresh())
	refresh()


## Rebuilds all slots (after a load, or when the trophy fish changed).
func refresh() -> void:
	for slot_id: String in _data.decor_slots:
		_rebuild(slot_id)


func _rebuild(slot_id: String) -> void:
	if _nodes.has(slot_id):
		_nodes[slot_id].queue_free()
	var at: Vector2 = _data.decor_slots[slot_id]
	var node := MeshInstance3D.new()
	node.mesh = _mesh(_state.decor.get(slot_id, ""))
	node.material_override = _material
	node.scale = Vector3.ONE * PIECE_SCALE
	node.position = Vector3(at.x, _terrain.ground_height_at(at.x, at.y), at.y)
	add_child(node)
	_nodes[slot_id] = node


func _mesh(item_id: String) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var item: GameData.ShopEntry = _data.decor_by_id(item_id)
	var col: Color = Color.html(item.color) if item != null else Color.WHITE
	var wood := Color(0.55, 0.38, 0.22)
	match item_id:
		"vaso":
			mb.add_cone(Vector3.ZERO, 0.22, 0.3, 0.35, Color(0.7, 0.36, 0.22), Color(0.8, 0.45, 0.28), 8, true, true)
			for i: int in 5:
				var a: float = TAU * float(i) / 5.0
				mb.add_ellipsoid(Vector3(cos(a) * 0.14, 0.48, sin(a) * 0.14), Vector3(0.09, 0.08, 0.09), col, col.lightened(0.2), 6, 4, true)
			mb.add_ellipsoid(Vector3(0.0, 0.42, 0.0), Vector3(0.2, 0.08, 0.2), Color(0.3, 0.6, 0.3), Color(0.4, 0.7, 0.35), 8, 4, true)
		"arbusto":
			mb.add_ellipsoid(Vector3(0.0, 0.35, 0.0), Vector3(0.38, 0.36, 0.38), col.darkened(0.2), col.lightened(0.1), 9, 6, false)
		"lanterna":
			mb.add_cone(Vector3.ZERO, 0.05, 0.05, 1.3, Color(0.2, 0.2, 0.22), Color(0.25, 0.25, 0.28), 6, true)
			mb.add_box(Vector3(0.0, 1.38, 0.0), Vector3(0.2, 0.22, 0.2), col)
			mb.add_cone(Vector3(0.0, 1.49, 0.0), 0.16, 0.0, 0.14, Color(0.2, 0.2, 0.22), Color(0.2, 0.2, 0.22), 4)
		"banco":
			mb.add_box(Vector3(0.0, 0.32, 0.0), Vector3(1.0, 0.07, 0.34), col)
			mb.add_box(Vector3(0.0, 0.58, -0.15), Vector3(1.0, 0.25, 0.05), col)
			for x: float in [-0.42, 0.42]:
				mb.add_box(Vector3(x, 0.16, 0.0), Vector3(0.07, 0.32, 0.3), wood)
		"bandeira":
			mb.add_cone(Vector3.ZERO, 0.035, 0.035, 1.6, Color(0.85, 0.85, 0.85), Color.WHITE, 6, true)
			mb.add_box(Vector3(0.25, 1.4, 0.0), Vector3(0.48, 0.3, 0.02), col)
		"estatua":
			mb.add_box(Vector3(0.0, 0.2, 0.0), Vector3(0.5, 0.4, 0.5), col.darkened(0.15))
			mb.add_ellipsoid(Vector3(0.0, 0.75, 0.0), Vector3(0.14, 0.32, 0.12), col, col.lightened(0.1), 8, 5, true)
			mb.add_triangle(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.25, 0.18), Vector3(0.0, 1.25, -0.18), col.darkened(0.1))
		"trofeu":
			mb.add_box(Vector3(0.0, 0.5, 0.0), Vector3(0.08, 1.0, 0.08), wood)
			mb.add_box(Vector3(0.0, 1.05, 0.0), Vector3(0.7, 0.45, 0.06), wood.lightened(0.15))
			var best: Array = _decor.best_fish()
			if str(best[0]) != "":
				var fish_col: Color = FishIcon.body_color(str(best[0]))
				var sp: GameData.Species = _data.species_by_id(str(best[0]))
				var k: float = clampf(_state.book[str(best[0])].longest / 60.0, 0.4, 1.0)
				mb.add_ellipsoid(Vector3(0.0, 1.05, 0.06), Vector3(0.26 * k, 0.12 * k, 0.04), fish_col.darkened(0.15), fish_col.lightened(0.15), 8, 5, true)
				mb.add_triangle(Vector3(0.22 * k, 1.05, 0.07), Vector3(0.34 * k, 1.15, 0.07), Vector3(0.34 * k, 0.95, 0.07), fish_col.darkened(0.3))
				mb.add_box(Vector3(0.0, 0.86, 0.04), Vector3(0.3, 0.06, 0.02), Color.html(_data.rarity_colors[sp.rarity]))
		_:
			# Empty slot: a faint ring of pebbles marking where a piece can go.
			for i: int in 8:
				var a: float = TAU * float(i) / 8.0
				mb.add_ellipsoid(Vector3(cos(a) * 0.32, 0.02, sin(a) * 0.32), Vector3(0.05, 0.03, 0.05), Color(0.85, 0.82, 0.72), Color(0.92, 0.9, 0.8), 5, 3, true)
	return mb.build()
