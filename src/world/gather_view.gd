class_name GatherView
extends Node3D
## The gathering spots in the world (design/gdd/gathering-crafting.md): a branch, a
## fiber tuft or a worm mound, each with a small glowing mote bobbing above it so the
## player sees what can be picked up. Gathered spots hide until they come back.
##
## Usage:
## [codeblock]
## var view := GatherView.new()
## add_child(view)
## view.setup(data, gathering, terrain)
## [/codeblock]

## Mote height above the ground and bob amplitude, in meters.
const MOTE_HEIGHT: float = 0.8
## Size of the props over their modeled size (readable on a phone screen).
const PROP_SCALE: float = 1.6
const MOTE_BOB: float = 0.08
const MOTE_SPEED: float = 2.4
## How often spots that came back are shown again, in real seconds.
const REFRESH_SECONDS: float = 1.0

var _data: GameData
var _gathering: Gathering
var _nodes: Dictionary[String, Node3D] = {}
var _motes: Array[Node3D] = []
var _time: float = 0.0
var _refresh_left: float = 0.0


## Builds one prop per spot of [param data] on [param terrain]'s ground.
func setup(data: GameData, gathering: Gathering, terrain: LakeTerrain) -> void:
	_data = data
	_gathering = gathering
	var material := MeshBuilder.make_material(0.9)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.95, 0.6)
	for n: GameData.GatherNode in data.gather_nodes:
		var root := Node3D.new()
		root.position = Vector3(n.pos.x, terrain.ground_height_at(n.pos.x, n.pos.y), n.pos.y)
		var prop := MeshInstance3D.new()
		prop.mesh = _prop_mesh(n.kind, Color.html(data.material_by_id(n.kind).color))
		prop.material_override = material
		prop.scale = Vector3.ONE * PROP_SCALE
		root.add_child(prop)
		var mote := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.2
		mote.mesh = sphere
		mote.material_override = glow
		mote.position.y = MOTE_HEIGHT
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mote)
		_motes.append(mote)
		add_child(root)
		_nodes[n.id] = root
	gathering.node_gathered.connect(func(_id: String) -> void: refresh())
	refresh()


## Shows the spots that can be gathered now and hides the others.
func refresh() -> void:
	for id: String in _nodes:
		_nodes[id].visible = _gathering.is_available(id)


func _process(delta: float) -> void:
	_time += delta
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()
	for i: int in _motes.size():
		_motes[i].position.y = MOTE_HEIGHT + sin(_time * MOTE_SPEED + float(i)) * MOTE_BOB


func _prop_mesh(kind: String, color: Color) -> ArrayMesh:
	var mb := MeshBuilder.new()
	match kind:
		"galho":
			mb.add_box(Vector3(0.0, 0.05, 0.0), Vector3(0.7, 0.07, 0.08), color)
			mb.add_box(Vector3(0.15, 0.06, 0.1), Vector3(0.25, 0.05, 0.05), color.darkened(0.15))
		"fibra":
			for i: int in 5:
				var a: float = TAU * float(i) / 5.0
				mb.add_cone(Vector3(cos(a) * 0.08, 0.0, sin(a) * 0.08), 0.04, 0.0, 0.32 + 0.06 * float(i % 2), color.darkened(0.2), color.lightened(0.15), 4)
		_:
			mb.add_ellipsoid(Vector3(0.0, 0.03, 0.0), Vector3(0.22, 0.08, 0.18), Color(0.42, 0.3, 0.2), Color(0.5, 0.36, 0.24), 8, 4, true)
			mb.add_box(Vector3(0.05, 0.1, 0.0), Vector3(0.16, 0.04, 0.04), color)
	return mb.build()
