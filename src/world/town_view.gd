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
var _locked: Dictionary = {}
var _prod: Production
var _ready: Dictionary = {}
var _zones: Dictionary = {}
var _ready_timer: float = 0.0


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
	if look.has("town", "locked_lots"):
		var locked: Dictionary = look.raw("town", "locked_lots")
		for id: Variant in locked:
			_locked[str(id)] = true
			var sign := _label(str(locked[id]), 64)
			var door: Vector2 = TownPlan.lot_door(look, str(id))
			sign.position = Vector3(door.x, 1.6, door.y)
			(_built[str(id)] as Node3D).add_child(sign)
	if look.has("town", "city_gate"):
		_instance(TownMeshes.city_gate(look), material)
		var city := _label(look.text("town", "city_label"), 60)
		var at: Array = look.raw("town", "city_sign")
		city.position = Vector3(float(at[0]) + 0.3, 3.4, float(at[1]))
		add_child(city)
	for entry: Variant in town.neighbors():
		var n: Dictionary = entry
		if not TownPlan.has_lot(look, str(n["lot"])):
			continue
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
	for id: String in _zones:
		(_zones[id] as Node3D).visible = not _state.expanded.has(id)
	for id: String in _built:
		var built: bool = _state.is_built(id) or _locked.has(id)
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


## Connects the real-time production (2026-11-21): green "!" over lots with something ready
## (finished factory products, animals to collect, a ripe crop, a sold stall slot), and the
## fences and signs of the expansion areas still closed.
func set_production(prod: Production) -> void:
	_prod = prod
	var material: StandardMaterial3D = MeshBuilder.make_material(_look.num("props", "roughness"))
	for id: String in TownPlan.lot_ids(_look):
		var mark := _label("!", 140)
		mark.modulate = _look.color("town", "ready_marker")
		mark.outline_size = 24
		var r: Rect2i = TownPlan.lot_rect(_look, id)
		mark.position = Vector3(float(r.position.x) + float(r.size.x) * 0.5, _marker_base + 1.0, float(r.position.y) + float(r.size.y) * 0.5)
		mark.visible = false
		add_child(mark)
		_ready[id] = mark
	for id: String in TownPlan.expansion_ids(_look):
		var holder := Node3D.new()
		add_child(holder)
		var r: Rect2i = TownPlan.expansion_rect(_look, id)
		var mb := MeshBuilder.new()
		var post: Color = _look.color("colors", "wood_dark")
		var x0: float = float(r.position.x) + 0.1
		var z0: float = float(r.position.y) + 0.1
		var x1: float = float(r.end.x) - 0.1
		var z1: float = float(r.end.y) - 0.1
		var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
		for k in 4:
			var a: Vector2 = corners[k]
			var b: Vector2 = corners[(k + 1) % 4]
			var n: int = maxi(1, int(a.distance_to(b) / 1.5))
			for j in n + 1:
				var q: Vector2 = a.lerp(b, float(j) / float(n))
				mb.add_box(Vector3(q.x, 0.5, q.y), Vector3(0.12, 1.0, 0.12), post)
			EstateMeshes._beam(mb, Vector3(a.x, 0.75, a.y), Vector3(b.x, 0.75, b.y), 0.05, _look.color("town", "flag_red"))
		var sign_at: Vector2 = TownPlan.expansion_sign(_look, id)
		mb.add_box(Vector3(sign_at.x, 0.7, sign_at.y), Vector3(0.12, 1.4, 0.12), post)
		mb.add_box(Vector3(sign_at.x, 1.3, sign_at.y), Vector3(1.0, 0.5, 0.08), _look.color("town", "sign_color"))
		var node := MeshInstance3D.new()
		node.mesh = mb.build()
		node.material_override = material
		holder.add_child(node)
		var label := _label(str(prod.expansion(id).get("name", id)), 56)
		label.position = Vector3(sign_at.x, 2.2, sign_at.y)
		holder.add_child(label)
		_zones[id] = holder
	refresh()


func _update_ready() -> void:
	for id: String in _ready:
		var on: bool = false
		if _state.is_built(id):
			if _prod.factory_ids().has(id):
				on = _prod.factory_done(id) > 0
			elif id == "barraca":
				on = _prod.stall_sold() > 0
			elif id == "plantacao":
				for i in _state.crop_plots.size():
					on = on or _prod.plot_stage(i) == 2
			elif id in ["galinheiro", "curral", "chiqueiro", "ovelhas"]:
				on = _prod.ready_in(id) > 0
		(_ready[id] as Node3D).visible = on


func _process(delta: float) -> void:
	_time += delta
	if _prod != null:
		_ready_timer -= delta
		if _ready_timer <= 0.0:
			_ready_timer = 1.0
			_update_ready()
		for id: String in _ready:
			var mark: Label3D = _ready[id]
			if mark.visible:
				mark.position.y = _marker_base + 1.0 + sin(_time * 3.0 + 1.0) * _marker_bob
	for id: String in _markers:
		var marker: Label3D = _markers[id]
		if marker.visible:
			marker.position.y = _marker_base + 1.0 + sin(_time * 3.0) * _marker_bob


func _label(text: String, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = size
	label.pixel_size = 0.01
	label.outline_size = 12
	label.modulate = _look.color("hud", "text_color")
	return label


func _instance(mesh: ArrayMesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node
