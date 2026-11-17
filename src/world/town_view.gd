class_name TownView
extends Node3D
## Draws the town lots (Stories 009-018): each lot shows its building when built and a building
## site with its name otherwise; smoke over the restaurant and workshop chimneys; a bobbing "!"
## over every neighbor house with an open fish request; glowing windows at night. It also keeps
## the [WorldGrid] in step with the fields lot (open inside once built).
##
## Reads [GameState] on [signal GameState.town_changed]; never changes game state.
##
## Usage:
## [codeblock]
## var view := TownView.new()
## add_child(view)
## view.setup(look, town_data, state, grid)
## view.set_lights(true)
## [/codeblock]

var _look: WorldLook
var _town: TownData
var _state: GameState
var _grid: WorldGrid
var _glass_material: StandardMaterial3D
var _glow: float = 0.0
var _built: Dictionary = {}
var _sites: Dictionary = {}
var _smokes: Dictionary = {}
var _markers: Dictionary = {}
var _marker_base: float = 0.0
var _marker_bob: float = 0.0
var _time: float = 0.0


## Builds every lot model and connects to the state.
func setup(look: WorldLook, town: TownData, state: GameState, grid: WorldGrid) -> void:
	_look = look
	_town = town
	_state = state
	_grid = grid
	var material: StandardMaterial3D = MeshBuilder.make_material(look.num("props", "roughness"))
	_glass_material = MeshBuilder.make_material(look.num("props", "roughness"))
	_glass_material.emission_enabled = true
	_glass_material.emission = look.color("estate", "glow_color")
	_glass_material.emission_energy_multiplier = 0.0
	_glow = look.num("daynight", "window_light_energy")
	_marker_base = look.num("town", "marker_height")
	_marker_bob = look.num("town", "marker_bob")
	var glass := MeshBuilder.new()
	for id: String in TownPlan.lot_ids(look):
		_built[id] = _instance(TownMeshes.building(look, id, glass), material)
		_sites[id] = _instance(TownMeshes.site(look, id), material)
		var label := Label3D.new()
		label.text = str(town.lot(id).get("name", id))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 64
		label.pixel_size = 0.01
		label.outline_size = 12
		label.modulate = look.color("hud", "text_color")
		var door: Vector2 = TownPlan.lot_door(look, id)
		label.position = Vector3(door.x + 0.9, 1.9, door.y)
		(_sites[id] as Node3D).add_child(label)
		var top: Vector3 = TownMeshes.chimney_top(look, id)
		if top != Vector3.INF:
			var smoke := ChimneySmoke.new()
			add_child(smoke)
			smoke.setup(look, top)
			_smokes[id] = smoke
	_instance(glass.build(), _glass_material)
	for entry: Variant in town.neighbors():
		var n: Dictionary = entry
		var marker := Label3D.new()
		marker.text = "!"
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 140
		marker.pixel_size = 0.01
		marker.outline_size = 24
		marker.modulate = look.color("town", "marker_color")
		var r: Rect2i = TownPlan.lot_rect(look, str(n["lot"]))
		marker.position = Vector3(float(r.position.x) + float(r.size.x) * 0.5, _marker_base + 1.0, float(r.position.y) + float(r.size.y) * 0.5)
		add_child(marker)
		_markers[str(n["id"])] = marker
	state.town_changed.connect(refresh)
	refresh()


## Shows built lots, sites, smoke and request markers as the state says.
func refresh() -> void:
	for id: String in _built:
		var built: bool = _state.is_built(id)
		(_built[id] as Node3D).visible = built
		(_sites[id] as Node3D).visible = not built
		if _smokes.has(id):
			(_smokes[id] as Node3D).visible = built
		TownPlan.apply_lot_state(_grid, _look, id, built)
	for id: String in _markers:
		var req: Dictionary = _state.requests.get(id, {})
		(_markers[id] as Node3D).visible = str(req.get("species", "")) != ""


## Window glow on or off (Story 008).
func set_lights(on: bool) -> void:
	_glass_material.emission_energy_multiplier = _glow if on else 0.0


func _process(delta: float) -> void:
	_time += delta
	for id: String in _markers:
		var marker: Label3D = _markers[id]
		if marker.visible:
			marker.position.y = _marker_base + 1.0 + sin(_time * 3.0) * _marker_bob


func _instance(mesh: ArrayMesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node
