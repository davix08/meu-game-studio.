class_name NetSession
extends Node
## Same-Wi-Fi coop for up to 4 players (design/gdd/coop-lan.md): one phone hosts, the
## others join by the room list (LAN beacon) or by IP. Each player keeps their own game
## (money, bag, guide); the session shares presence (position, pose, rod) and catches.
##
## Must sit at the same node path on every peer (the main scene adds it as "Net").
## Usage:
## [codeblock]
## var net := NetSession.new()
## net.name = "Net"
## add_child(net)
## net.host()                      # or net.join("192.168.0.12")
## net.send_state(snapshot)        # every frame; throttled to send_hz
## net.remote_state.connect(func(id, snap): ...)
## [/codeblock]

## A player arrived (on every peer, for every other player). [param slot] 0..3 is stable
## for the session and picks the player's vest color.
signal player_joined(peer_id: int, slot: int)
## A player left or dropped.
signal player_left(peer_id: int)
## A player's presence update.
signal remote_state(peer_id: int, snapshot: PlayerSnapshot)
## A player landed a fish: species id, weight kg, length cm.
signal remote_catch(peer_id: int, species_id: String, weight: float, length: float)
## This device joined a room (client) or opened one (host).
signal session_started
## The session ended: left, host closed, or the connection failed.
signal session_ended(reason: String)

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4
## Presence updates per second.
const SEND_HZ: float = 10.0

## Peer id -> slot 0..3 (host is slot 0). Kept in step on every peer by the host.
var slots: Dictionary[int, int] = {}

var _send_left: float = 0.0
## This device's peer id while in a room (1 for the host), cached because the peer
## cannot be asked once the connection is gone.
var _my_id: int = 0
var _peer: ENetMultiplayerPeer


## True while in a room (hosting or joined).
func is_active() -> bool:
	return _peer != null and _peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


## True when this device hosts the room.
func is_host() -> bool:
	return is_active() and multiplayer.is_server()


## Players in the room, this device included.
func player_count() -> int:
	return slots.size()


## Opens a room on [param port]. Returns OK or the ENet error.
func host(port: int = DEFAULT_PORT) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	_use(peer)
	_my_id = 1
	slots = {1: 0}
	session_started.emit()
	return OK


## Joins the room at [param address]. Returns OK when the attempt started;
## [signal session_started] or [signal session_ended] tells how it went.
func join(address: String, port: int = DEFAULT_PORT) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		return err
	_use(peer)
	return OK


## Leaves the room (the host closing it ends it for everyone).
func leave() -> void:
	if _peer == null:
		return
	_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	for id: int in slots.keys():
		if id != _my_id:
			player_left.emit(id)
	slots.clear()
	_my_id = 0
	session_ended.emit("left")


## Sends this player's presence, at most [constant SEND_HZ] times a second.
func send_state(snapshot: PlayerSnapshot, delta: float) -> void:
	if not is_active() or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_send_left -= delta
	if _send_left > 0.0:
		return
	_send_left = 1.0 / SEND_HZ
	_rpc_state.rpc(snapshot.to_wire())


## Tells the room this player landed a fish.
func send_catch(species_id: String, weight: float, length: float) -> void:
	if is_active() and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_rpc_catch.rpc(species_id, weight, length)


## This device's slot (0 when alone).
func my_slot() -> int:
	return slots.get(_my_id, 0)


func _use(peer: ENetMultiplayerPeer) -> void:
	_peer = peer
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.connected_to_server.connect(_on_connected)
		multiplayer.connection_failed.connect(_on_failed)
		multiplayer.server_disconnected.connect(_on_server_gone)


func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var used: Array = slots.values()
	var slot: int = 0
	while used.has(slot):
		slot += 1
	slots[id] = slot
	player_joined.emit(id, slot)
	_rpc_slots.rpc(slots)


func _on_peer_disconnected(id: int) -> void:
	if slots.has(id):
		slots.erase(id)
		player_left.emit(id)
		if multiplayer.is_server():
			_rpc_slots.rpc(slots)


func _on_connected() -> void:
	_my_id = multiplayer.get_unique_id()
	session_started.emit()


func _on_failed() -> void:
	multiplayer.multiplayer_peer = null
	_peer = null
	slots.clear()
	session_ended.emit("failed")


func _on_server_gone() -> void:
	for id: int in slots.keys():
		if id != _my_id:
			player_left.emit(id)
	_my_id = 0
	multiplayer.multiplayer_peer = null
	_peer = null
	slots.clear()
	session_ended.emit("host_left")


@rpc("authority", "call_remote", "reliable")
func _rpc_slots(new_slots: Dictionary) -> void:
	var me: int = _my_id
	for id: int in slots.keys():
		if not new_slots.has(id) and id != me:
			slots.erase(id)
			player_left.emit(id)
	for id: Variant in new_slots:
		var pid: int = int(id)
		var slot: int = clampi(int(new_slots[id]), 0, MAX_PLAYERS - 1)
		if not slots.has(pid):
			slots[pid] = slot
			if pid != me:
				player_joined.emit(pid, slot)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_state(wire: Array) -> void:
	var snap: PlayerSnapshot = PlayerSnapshot.from_wire(wire)
	if snap != null:
		remote_state.emit(multiplayer.get_remote_sender_id(), snap)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_catch(species_id: String, weight: float, length: float) -> void:
	remote_catch.emit(multiplayer.get_remote_sender_id(), species_id, weight, length)
