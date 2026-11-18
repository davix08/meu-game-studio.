class_name LanBeacon
extends Node
## Finds coop rooms on the same Wi-Fi (design/gdd/coop-lan.md). The host broadcasts a
## small UDP packet every second; joiners listen and keep a list of rooms seen in the
## last few seconds. Joining by typed IP works without it (some routers block broadcast).
##
## Usage:
## [codeblock]
## beacon.advertise("Sala de Ana", 2)   # host, while the room is open
## beacon.listen()                      # joiner, while the room list is on screen
## beacon.rooms_changed.connect(func(): print(beacon.rooms))
## beacon.stop()
## [/codeblock]

## The room list changed (a room appeared, updated or went quiet).
signal rooms_changed

const PORT: int = 7779
## Packet prefix, so other apps' broadcasts on the port are ignored.
const MAGIC: String = "MYSTICTIDES1"
const INTERVAL: float = 1.0
## A room not heard from for this long is dropped from the list.
const TIMEOUT: float = 4.0

## Rooms heard: ip -> {"name": String, "players": int, "port": int, "seen": float}.
var rooms: Dictionary[String, Dictionary] = {}

var _udp: PacketPeerUDP
var _advertising: bool = false
var _name: String = ""
var _players: int = 1
var _game_port: int = NetSession.DEFAULT_PORT
var _left: float = 0.0
var _clock: float = 0.0


## Starts broadcasting this device's room. Call again to update the player count.
func advertise(room_name: String, players: int, game_port: int = NetSession.DEFAULT_PORT) -> void:
	_name = room_name
	_players = players
	_game_port = game_port
	if _advertising:
		return
	stop()
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	_udp.set_dest_address("255.255.255.255", PORT)
	_advertising = true
	_left = 0.0


## Starts listening for rooms. Returns OK or the bind error.
func listen() -> Error:
	stop()
	_udp = PacketPeerUDP.new()
	var err: Error = _udp.bind(PORT)
	if err != OK:
		_udp = null
	return err


## Stops broadcasting or listening and forgets the rooms.
func stop() -> void:
	if _udp != null:
		_udp.close()
	_udp = null
	_advertising = false
	if not rooms.is_empty():
		rooms.clear()
		rooms_changed.emit()


## The packet a host sends, e.g. "MYSTICTIDES1|Sala de Ana|2|7777".
static func encode(room_name: String, players: int, game_port: int) -> PackedByteArray:
	return ("%s|%s|%d|%d" % [MAGIC, room_name.replace("|", " "), players, game_port]).to_utf8_buffer()


## Parses a packet: {"name", "players", "port"}, or {} when it is not ours or is malformed.
static func decode(packet: PackedByteArray) -> Dictionary:
	var parts: PackedStringArray = packet.get_string_from_utf8().split("|")
	if parts.size() != 4 or parts[0] != MAGIC or not parts[2].is_valid_int() or not parts[3].is_valid_int():
		return {}
	var port: int = parts[3].to_int()
	if port < 1 or port > 65535:
		return {}
	return {"name": parts[1].left(32), "players": clampi(parts[2].to_int(), 1, NetSession.MAX_PLAYERS), "port": port}


func _process(delta: float) -> void:
	_clock += delta
	if _udp == null:
		return
	if _advertising:
		_left -= delta
		if _left <= 0.0:
			_left = INTERVAL
			_udp.put_packet(encode(_name, _players, _game_port))
		return
	var changed: bool = false
	while _udp.get_available_packet_count() > 0:
		var packet: PackedByteArray = _udp.get_packet()
		var info: Dictionary = decode(packet)
		if info.is_empty():
			continue
		var ip: String = _udp.get_packet_ip()
		info["seen"] = _clock
		changed = changed or not rooms.has(ip) or int(rooms[ip]["players"]) != int(info["players"])
		rooms[ip] = info
	for ip: String in rooms.keys():
		if _clock - float(rooms[ip]["seen"]) > TIMEOUT:
			rooms.erase(ip)
			changed = true
	if changed:
		rooms_changed.emit()


## This device's Wi-Fi address (IPv4, private range), or "" when none is found.
static func local_ip() -> String:
	for a: String in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10.") or (a.begins_with("172.") and a.split(".").size() == 4 and int(a.split(".")[1]) >= 16 and int(a.split(".")[1]) <= 31):
			return a
	return ""
