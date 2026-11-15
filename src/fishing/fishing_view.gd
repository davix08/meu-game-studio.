class_name FishingView
extends Node3D
## The 3D side of a cast: the bobber (arc flight, bob, nibble dip, bite sink, fight shake), the
## fishing line (ImmediateMesh strip from the rod tip to the bobber, redrawn every frame),
## ripples and splashes, the "!" over the fisherman on a bite, and the fisherman's fishing pose.
## It only reads the [FishingMachine] and reacts to its signals; it holds no fishing rules.
##
## Machine positions are in 2D pixels (x, z); the view converts them to meters (16 px = 1 m) and
## puts the bobber on the water surface height given to [method setup].
##
## Story 003 (design/game-brief.md, MVP feature 10). All sizes, heights and colors come from the
## "fishing" group of world_look.json.
##
## Usage:
## [codeblock]
## var view := FishingView.new()
## add_child(view)
## view.setup(look, data, machine, fisherman, life, -0.1)
## [/codeblock]

const _KEYS: Array[String] = [
	"arc_height", "bobber_radius", "bobber_float", "bobber_bob_amount", "bobber_bob_freq", "nibble_dip", "bite_dip",
	"fight_shake", "fight_shake_freq", "line_segments", "line_sag", "line_sag_fight", "ripple_count", "ripple_life",
	"ripple_grow", "ripple_radius", "ripple_width", "ripple_flatten", "wait_ripple_seconds", "fight_ripple_seconds",
	"splash_amount", "splash_life", "splash_speed", "splash_size", "splash_gravity", "bang_height", "bang_font_size",
	"bang_pixel_size", "bang_blink_freq",
]

var _k: Dictionary[String, float] = {}
var _data: GameData
var _machine: FishingMachine
var _fisherman: Fisherman
var _life: WaterLife
var _water_y: float = 0.0
var _bobber: Node3D
var _line: MeshInstance3D
var _imm: ImmediateMesh
var _line_material: StandardMaterial3D
var _splash: CPUParticles3D
var _bang: Label3D
var _ripples: Array[MeshInstance3D] = []
var _ripple_materials: Array[StandardMaterial3D] = []
var _ripple_age: PackedFloat32Array = PackedFloat32Array()
var _ripple_color: Color = Color.WHITE
var _start: Vector3 = Vector3.ZERO
var _bobber_pos: Vector3 = Vector3.ZERO
var _ripple_timer: float = 0.0
var _time: float = 0.0


## Reads the tuning and builds the bobber, line, ripples, splash and "!" nodes, then connects to
## [param machine]. [param water_y] is the water surface height in meters.
func setup(look: WorldLook, data: GameData, machine: FishingMachine, fisherman: Fisherman, life: WaterLife, water_y: float) -> void:
	_data = data
	_machine = machine
	_fisherman = fisherman
	_life = life
	_water_y = water_y
	for key: String in _KEYS:
		_k[key] = look.num("fishing", key)
	_ripple_color = look.color("fishing", "ripple_color")
	_build_bobber(look)
	_build_line(look)
	_build_ripples()
	_build_splash(look)
	_bang = Label3D.new()
	_bang.text = str(JSON.parse_string(FileAccess.get_file_as_string(FishingHud.TEXTS_PATH)).get("bite_mark", "!"))
	_bang.font_size = int(_k["bang_font_size"])
	_bang.pixel_size = _k["bang_pixel_size"]
	_bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bang.modulate = look.color("fishing", "bang_color")
	_bang.no_depth_test = true
	_bang.visible = false
	add_child(_bang)
	machine.phase_changed.connect(_on_phase_changed)
	machine.nibbled.connect(_on_nibbled)
	machine.fish_landed.connect(_on_fish_landed)


func _process(delta: float) -> void:
	_time += delta
	_update_ripples(delta)
	var phase: FishingMachine.Phase = _machine.phase
	_fisherman.cast_progress = _machine.cast_progress
	match phase:
		FishingMachine.Phase.IDLE:
			_fisherman.pose = Fisherman.Pose.NONE
		FishingMachine.Phase.CAST:
			_fisherman.pose = Fisherman.Pose.CAST
		FishingMachine.Phase.WAIT, FishingMachine.Phase.BITE:
			_fisherman.pose = Fisherman.Pose.WAIT
		FishingMachine.Phase.FIGHT:
			_fisherman.pose = Fisherman.Pose.FIGHT
		FishingMachine.Phase.CAUGHT:
			_fisherman.pose = Fisherman.Pose.LAND
	if phase != FishingMachine.Phase.IDLE:
		_fisherman.face_toward(_target_world())
	var shown: bool = phase != FishingMachine.Phase.IDLE and phase != FishingMachine.Phase.CAUGHT
	_bobber.visible = shown
	_line.visible = shown
	_bang.visible = phase == FishingMachine.Phase.BITE and sin(_time * _k["bang_blink_freq"]) > 0.0
	_bang.position = _fisherman.position + Vector3.UP * _k["bang_height"]
	if not shown:
		return
	var rest: Vector3 = _target_world() + Vector3.UP * _k["bobber_float"]
	match phase:
		FishingMachine.Phase.CAST:
			_bobber_pos = _start.lerp(rest, _machine.cast_progress)
			_bobber_pos.y += sin(_machine.cast_progress * PI) * _k["arc_height"]
		FishingMachine.Phase.WAIT:
			_bobber_pos = rest + Vector3.UP * sin(_time * _k["bobber_bob_freq"]) * _k["bobber_bob_amount"]
			if _machine.nibble_left > 0.0:
				_bobber_pos.y -= _k["nibble_dip"]
		FishingMachine.Phase.BITE:
			_bobber_pos = rest + Vector3.DOWN * _k["bite_dip"]
		FishingMachine.Phase.FIGHT:
			var shake: float = _k["fight_shake"]
			_bobber_pos = rest + Vector3(sin(_time * _k["fight_shake_freq"]), 0.0, cos(_time * _k["fight_shake_freq"] * 1.3)) * shake
			_bobber_pos.y -= _k["bite_dip"] * 0.5
	_bobber.position = _bobber_pos
	if phase != FishingMachine.Phase.CAST:
		_ripple_timer -= delta
		if _ripple_timer <= 0.0:
			var fighting: bool = phase != FishingMachine.Phase.WAIT
			_ripple_timer = _k["fight_ripple_seconds"] if fighting else _k["wait_ripple_seconds"]
			_spawn_ripple(_target_world())
			if phase == FishingMachine.Phase.FIGHT:
				_burst(_target_world())
	_draw_line(phase == FishingMachine.Phase.FIGHT)


func _on_phase_changed(new_phase: FishingMachine.Phase) -> void:
	match new_phase:
		FishingMachine.Phase.CAST:
			_start = _fisherman.get_rod_tip()
			_bobber_pos = _start
		FishingMachine.Phase.WAIT:
			_ripple_timer = _k["wait_ripple_seconds"]
			_burst(_target_world())
			_life.scare(_machine.target)
		FishingMachine.Phase.BITE, FishingMachine.Phase.FIGHT, FishingMachine.Phase.CAUGHT:
			_ripple_timer = _k["fight_ripple_seconds"]
			_burst(_target_world())


func _on_nibbled() -> void:
	_spawn_ripple(_target_world())


func _on_fish_landed(fish: GameState.Catch) -> void:
	_fisherman.catch_color = Color.html(_data.rarity_colors[_data.species_by_id(fish.id).rarity])


## Where the bobber lands, in meters on the water surface.
func _target_world() -> Vector3:
	return Vector3(_machine.target.x, 0.0, _machine.target.z) / WorldGrid.PIXELS_PER_BLOCK + Vector3.UP * _water_y


func _burst(pos: Vector3) -> void:
	_spawn_ripple(pos)
	_splash.position = pos
	_splash.restart()


func _spawn_ripple(pos: Vector3) -> void:
	for i: int in range(_ripples.size()):
		if _ripple_age[i] >= _k["ripple_life"]:
			_ripple_age[i] = 0.0
			_ripples[i].position = pos + Vector3.UP * 0.02
			return


func _update_ripples(delta: float) -> void:
	for i: int in range(_ripples.size()):
		if _ripple_age[i] >= _k["ripple_life"]:
			_ripples[i].visible = false
			continue
		_ripple_age[i] += delta
		var t: float = clampf(_ripple_age[i] / _k["ripple_life"], 0.0, 1.0)
		var grow: float = 1.0 + t * _k["ripple_grow"]
		_ripples[i].visible = t < 1.0
		_ripples[i].scale = Vector3(grow, _k["ripple_flatten"], grow)
		_ripple_materials[i].albedo_color = Color(_ripple_color, _ripple_color.a * (1.0 - t))


## Rod tip to bobber: a short strip with a downward sag (almost straight while fighting).
func _draw_line(taut: bool) -> void:
	_imm.clear_surfaces()
	var from: Vector3 = _fisherman.get_rod_tip()
	var sag: float = _k["line_sag_fight"] if taut else _k["line_sag"]
	var segments: int = int(_k["line_segments"])
	_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _line_material)
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = from.lerp(_bobber_pos, t)
		point.y -= sag * 4.0 * t * (1.0 - t)
		_imm.surface_add_vertex(point)
	_imm.surface_end()


func _build_bobber(look: WorldLook) -> void:
	_bobber = Node3D.new()
	_bobber.visible = false
	add_child(_bobber)
	var radius: float = _k["bobber_radius"]
	var red := SphereMesh.new()
	red.radius = radius
	red.height = radius * 2.0
	red.radial_segments = 10
	red.rings = 5
	var white := SphereMesh.new()
	white.radius = radius * 0.92
	white.height = radius * 1.84
	white.radial_segments = 10
	white.rings = 5
	_add_bobber_part(red, look.color("fishing", "bobber_red"), Vector3(0.0, radius * 0.35, 0.0))
	_add_bobber_part(white, look.color("fishing", "bobber_white"), Vector3(0.0, -radius * 0.45, 0.0))


func _add_bobber_part(part: SphereMesh, color: Color, pos: Vector3) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	var node := MeshInstance3D.new()
	node.mesh = part
	node.material_override = material
	node.position = pos
	_bobber.add_child(node)


func _build_line(look: WorldLook) -> void:
	_imm = ImmediateMesh.new()
	_line_material = StandardMaterial3D.new()
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.albedo_color = look.color("fishing", "line_color")
	_line = MeshInstance3D.new()
	_line.mesh = _imm
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.visible = false
	add_child(_line)


func _build_ripples() -> void:
	var torus := TorusMesh.new()
	torus.outer_radius = _k["ripple_radius"]
	torus.inner_radius = _k["ripple_radius"] - _k["ripple_width"]
	for i: int in range(int(_k["ripple_count"])):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = _ripple_color
		var node := MeshInstance3D.new()
		node.mesh = torus
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visible = false
		add_child(node)
		_ripples.append(node)
		_ripple_materials.append(material)
		_ripple_age.append(_k["ripple_life"])


func _build_splash(look: WorldLook) -> void:
	var drop := SphereMesh.new()
	drop.radius = _k["splash_size"]
	drop.height = _k["splash_size"] * 2.0
	drop.radial_segments = 6
	drop.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = look.color("fishing", "splash_color")
	drop.material = material
	_splash = CPUParticles3D.new()
	_splash.mesh = drop
	_splash.one_shot = true
	_splash.emitting = false
	_splash.explosiveness = 1.0
	_splash.amount = int(_k["splash_amount"])
	_splash.lifetime = _k["splash_life"]
	_splash.direction = Vector3.UP
	_splash.spread = 40.0
	_splash.initial_velocity_min = _k["splash_speed"] * 0.6
	_splash.initial_velocity_max = _k["splash_speed"]
	_splash.gravity = Vector3(0.0, -_k["splash_gravity"], 0.0)
	add_child(_splash)
