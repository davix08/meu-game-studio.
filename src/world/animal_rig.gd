class_name AnimalRig
extends Node3D
## An animated animal from the owner's model cut into parts ([method AnimalModels.rig_parts]):
## body, head with neck, tail and four legs, each on its own pivot. The animations follow the
## owner's animation sheets (2026-11-22): idle (breathing, tail swish, looking around), walk,
## trot, gallop (front and back legs in pairs, body rocking), graze (head down, chewing),
## sleep (lying down, legs folded) and rear (one-shot: up on the back legs, front legs kicking).
## Turns, speeds and amplitudes: "animal_rigs.anim" in world_look.json.
##
## Usage:
## [codeblock]
## var cow: AnimalRig = AnimalRig.create(look, "vaca", true)  # faces +x
## add_child(cow)
## cow.state = AnimalRig.State.GRAZE
## horse.set_motion(true, true)  # gallop
## horse.play_rear()
## [/codeblock]

enum State { IDLE, WALK, TROT, GALLOP, GRAZE, SLEEP }

## What the animal does now (the rear is a one-shot on top of it).
var state: State = State.IDLE
var _inner: Node3D
var _rear_pivot: Node3D
var _frame: Node3D
var _body: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Dictionary = {}
var _belly: float = 0.5
var _t: float = 0.0
var _phase: float = 0.0
var _rear_t: float = -1.0
var _k: Dictionary = {}
var _lie: float = 0.0


## Builds the animal [param id] facing +x ([param face_x]) or +z, or null without its model.
static func create(look: WorldLook, id: String, face_x: bool) -> AnimalRig:
	var data: Dictionary = AnimalModels.rig_parts(look, id)
	if data.is_empty():
		return null
	var rig := AnimalRig.new()
	rig._setup(look, id, data, face_x)
	return rig


func _setup(look: WorldLook, id: String, data: Dictionary, face_x: bool) -> void:
	var cfg: Dictionary = look.raw("animal_rigs", id)
	_belly = float(cfg["belly_y"])
	_k = look.raw("animal_rigs", "anim")
	_t = randf() * 10.0
	_inner = Node3D.new()
	_inner.rotation.y = PI * 0.5 if face_x else 0.0
	add_child(_inner)
	# Rear: the whole animal turns around the back hips.
	var back_z: float = (float((cfg["back_z"] as Array)[0]) + float((cfg["back_z"] as Array)[1])) * 0.5
	_rear_pivot = Node3D.new()
	_rear_pivot.position = Vector3(0.0, 0.0, back_z)
	_inner.add_child(_rear_pivot)
	_frame = Node3D.new()
	_frame.position = Vector3(0.0, 0.0, -back_z)
	_rear_pivot.add_child(_frame)
	var parts: Dictionary = data["parts"]
	var pivots: Dictionary = data["pivots"]
	var material: Material = data["material"]
	_body = _part(_frame, parts, pivots, "body", material)
	_head = _part(_body, parts, pivots, "head", material, pivots["body"])
	_tail = _part(_body, parts, pivots, "tail", material, pivots["body"])
	for leg: String in ["fl", "fr", "bl", "br"]:
		_legs[leg] = _part(_body, parts, pivots, leg, material, pivots["body"])


func _part(parent: Node3D, parts: Dictionary, pivots: Dictionary, name: String, material: Material, parent_pivot: Vector3 = Vector3.ZERO) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = (pivots.get(name, Vector3.ZERO) as Vector3) - parent_pivot
	parent.add_child(pivot)
	if parts.has(name):
		var node := MeshInstance3D.new()
		node.mesh = parts[name]
		node.material_override = material
		pivot.add_child(node)
	return pivot


## Walking or still: WALK / GALLOP ([param fast]) while moving, IDLE when stopped (grazing and
## sleeping stay as they are until moving).
func set_motion(moving: bool, fast: bool) -> void:
	if moving:
		state = State.GALLOP if fast else State.WALK
	elif state == State.WALK or state == State.TROT or state == State.GALLOP:
		state = State.IDLE


## Rears up once (about [code]rear_seconds[/code]).
func play_rear() -> void:
	_rear_t = 0.0


## True while rearing.
func rearing() -> bool:
	return _rear_t >= 0.0


func _process(delta: float) -> void:
	if _body == null or not is_visible_in_tree():
		return
	_t += delta
	var f: float = 0.0
	var amp: float = 0.0
	match state:
		State.WALK:
			f = float(_k["walk_freq"])
			amp = float(_k["walk_leg"])
		State.TROT:
			f = float(_k["trot_freq"])
			amp = float(_k["trot_leg"])
		State.GALLOP:
			f = float(_k["gallop_freq"])
			amp = float(_k["gallop_leg"])
	_phase += delta * f
	var s: float = sin(_phase)
	var blend: float = 1.0 - exp(-14.0 * delta)
	_lie = move_toward(_lie, 1.0 if state == State.SLEEP else 0.0, delta * 1.2)
	# Legs: diagonal pairs for walk and trot, front and back pairs for the gallop.
	var target: Dictionary = {"fl": 0.0, "fr": 0.0, "bl": 0.0, "br": 0.0}
	if state == State.GALLOP:
		target = {"fl": sin(_phase) * amp, "fr": sin(_phase + 0.5) * amp, "bl": sin(_phase + PI) * amp, "br": sin(_phase + PI + 0.5) * amp}
	elif amp > 0.0:
		target = {"fl": s * amp, "br": s * amp, "fr": -s * amp, "bl": -s * amp}
	# Lying down: front legs fold back, back legs fold forward.
	var fold: float = float(_k["sleep_fold"]) * _lie
	for leg: String in _legs:
		var node: Node3D = _legs[leg]
		var goal: float = float(target[leg]) + (fold if leg.begins_with("f") else -fold)
		node.rotation.x = lerpf(node.rotation.x, goal, blend)
	# Body: bob, rock (gallop), breathing, lowered when lying.
	var bob: float = absf(cos(_phase)) * float(_k["bob"]) * (2.0 if state == State.GALLOP else 1.0) * (1.0 if amp > 0.0 else 0.0)
	_body.position.y = bob - _belly * float(_k["sleep_drop"]) * _lie
	_body.rotation.x = lerpf(_body.rotation.x, (sin(_phase * 1.0) * float(_k["gallop_rock"]) if state == State.GALLOP else 0.0), blend)
	_body.scale = Vector3(1.0, 1.0 + sin(_t * 1.4) * 0.012, 1.0)
	# Head: down to graze (chewing), low when sleeping, nod while walking, look around at idle.
	var head_x: float = 0.0
	var head_y: float = 0.0
	match state:
		State.GRAZE:
			head_x = float(_k["graze_head"]) + sin(_t * 6.0) * 0.04
		State.SLEEP:
			head_x = float(_k["graze_head"]) * 0.4
		State.IDLE:
			head_x = sin(_t * 0.7) * 0.05
			head_y = sin(_t * 0.31) * 0.25
		_:
			head_x = sin(_phase * 2.0) * 0.06
	_head.rotation.x = lerpf(_head.rotation.x, head_x, 1.0 - exp(-5.0 * delta))
	_head.rotation.y = lerpf(_head.rotation.y, head_y, 1.0 - exp(-3.0 * delta))
	# Tail: slow swish, faster when moving, still when sleeping.
	_tail.rotation.z = sin(_t * (5.0 if amp > 0.0 else 1.6)) * float(_k["tail_swish"]) * (1.0 - _lie)
	_tail.rotation.x = (0.35 if state == State.GALLOP else 0.0)
	# Rear: up on the back legs, front legs kicking, then down.
	if _rear_t >= 0.0:
		_rear_t += delta
		var total: float = float(_k["rear_seconds"])
		var k: float = sin(clampf(_rear_t / total, 0.0, 1.0) * PI)
		_rear_pivot.rotation.x = -float(_k["rear_angle"]) * k
		for leg: String in ["fl", "fr"]:
			(_legs[leg] as Node3D).rotation.x = -0.9 * k + sin(_rear_t * 14.0 + (0.0 if leg == "fl" else 1.5)) * 0.4 * k
		_head.rotation.x = -0.3 * k
		if _rear_t >= total:
			_rear_t = -1.0
			_rear_pivot.rotation.x = 0.0
