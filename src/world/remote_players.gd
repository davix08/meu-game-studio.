class_name RemotePlayers
extends Node3D
## The other coop players in this world (design/gdd/coop-lan.md): one fisherman per
## remote peer, in that player's slot color, with a name tag. Walks toward each new
## position (so 10 updates a second look smooth) and snaps when far behind.
##
## Usage:
## [codeblock]
## var others := RemotePlayers.new()
## add_child(others)
## others.setup(look, grid, terrain, walk_speed, run_speed)
## net.player_joined.connect(others.add_player)
## [/codeblock]

## Vest colors by slot (slot 0 is the host). The local player keeps their own outfit.
const SLOT_VESTS: Array[String] = ["#c84a3a", "#3a7ac8", "#3ab06a", "#d0a030"]
## Farther than this (blocks) from the target: teleport instead of walking.
const SNAP_DISTANCE: float = 3.0
## Closer than this: stand still.
const ARRIVE_DISTANCE: float = 0.06
## Farther than this: run.
const RUN_DISTANCE: float = 0.8

var _look: WorldLook
var _grid: WorldGrid
var _terrain: LakeTerrain
var _walk: float = 1.0
var _run: float = 2.0
var _players: Dictionary[int, Fisherman] = {}
var _targets: Dictionary[int, PlayerSnapshot] = {}


## Keeps what new fishermen need.
func setup(look: WorldLook, grid: WorldGrid, terrain: LakeTerrain, walk_speed: float, run_speed: float) -> void:
	_look = look
	_grid = grid
	_terrain = terrain
	_walk = walk_speed
	_run = run_speed


## Adds the fisherman of [param peer_id] in [param slot]'s colors.
func add_player(peer_id: int, slot: int) -> void:
	if _players.has(peer_id):
		return
	var f := Fisherman.new()
	add_child(f)
	f.setup(_look, _grid, _terrain, _walk, _run)
	var vest := Color.html(SLOT_VESTS[slot % SLOT_VESTS.size()])
	# Vest and hat band in the slot color, so each friend reads apart at a glance.
	f.set_outfit({"vest": vest, "vest_edge": vest.darkened(0.3), "hat_band": vest, "shirt": vest.lightened(0.55)})
	f.set_rod_visible(false)
	var tag := Label3D.new()
	tag.text = Texts.fmt("coop_player", [slot + 1])
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 40
	tag.pixel_size = 0.012
	tag.outline_size = 14
	tag.outline_modulate = Color(0.1, 0.07, 0.05)
	tag.modulate = vest.lightened(0.35)
	tag.position = Vector3(0.0, 3.0, 0.0)
	f.add_child(tag)
	_players[peer_id] = f


## Removes the fisherman of [param peer_id].
func remove_player(peer_id: int) -> void:
	if _players.has(peer_id):
		_players[peer_id].queue_free()
		_players.erase(peer_id)
	_targets.erase(peer_id)


## Removes everyone (the session ended).
func clear() -> void:
	for id: int in _players.keys():
		remove_player(id)


## Number of remote fishermen shown.
func count() -> int:
	return _players.size()


## Applies a presence update from [param peer_id].
func apply(peer_id: int, snap: PlayerSnapshot) -> void:
	if not _players.has(peer_id):
		return
	var f: Fisherman = _players[peer_id]
	if not _targets.has(peer_id) or f.ground_pos.distance_to(snap.pos) > SNAP_DISTANCE:
		f.teleport(snap.pos)
	_targets[peer_id] = snap
	f.pose = snap.pose as Fisherman.Pose
	f.cast_progress = snap.cast_progress
	f.set_rod_visible(snap.has_rod)
	if snap.has_rod:
		f.set_rod_color(Color.html(snap.rod_color))


func _process(delta: float) -> void:
	for id: int in _targets:
		var f: Fisherman = _players.get(id)
		if f == null:
			continue
		var snap: PlayerSnapshot = _targets[id]
		var to: Vector2 = snap.pos - f.ground_pos
		var dist: float = to.length()
		if dist <= ARRIVE_DISTANCE:
			f.step(delta, Vector2.ZERO, false)
			f.rotation.y = lerp_angle(f.rotation.y, snap.yaw, 1.0 - exp(-10.0 * delta))
		else:
			f.step(delta, to, dist > RUN_DISTANCE)
			if f.ground_pos.distance_to(snap.pos) >= dist:
				f.teleport(snap.pos) # Blocked by a collider the sender walked around.
