class_name Sfx
extends Node
## Small sound effects made in code (Story 006, so the Sound setting does something real): each
## sound is a short tone sliding from one pitch to another, generated once as an
## [AudioStreamWAV] and played from a small pool of players. The sound setting mutes the master
## bus. Pitches and lengths come from the "sfx" group of world_look.json as [from_hz, seconds, to_hz].
## 2026-11-22: also sound files (assets/audio, made by tools/asset-pipeline/make_sounds.py) named
## in "sfx.files": animals, truck engine and horn, doors, splashes, swimming, reel, hooves; sounds
## placed in the world ([method play_at], heard louder near the farmer) and ambience loops
## ([method set_loop]: farm birds and wind, lake water).
##
## Usage:
## [codeblock]
## var sfx := Sfx.new()
## add_child(sfx)
## sfx.setup(look)
## sfx.play(&"coin")
## sfx.set_enabled(false)
## [/codeblock]

const NAMES: Array[StringName] = [&"click", &"coin", &"cast", &"bite", &"catch", &"level", &"error"]

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _players_3d: Array[AudioStreamPlayer3D] = []
var _next_3d: int = 0
var _loops: Dictionary = {}
var _look: WorldLook


## Generates the tones and the player pool.
func setup(look: WorldLook) -> void:
	_look = look
	var rate: int = look.integer("sfx", "mix_rate")
	if look.has("sfx", "files"):
		var files: Dictionary = look.raw("sfx", "files")
		for key: Variant in files:
			var path: String = str(files[key])
			if ResourceLoader.exists(path):
				_streams[StringName(str(key))] = load(path)
	for i in look.integer("sfx", "players_3d") if look.has("sfx", "players_3d") else 0:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = look.num("sfx", "unit_size")
		p3.max_distance = look.num("sfx", "max_distance")
		p3.volume_db = look.num("sfx", "volume_db")
		add_child(p3)
		_players_3d.append(p3)
	for sound: StringName in NAMES:
		var spec: Array = look.raw("sfx", String(sound))
		_streams[sound] = _tone(rate, float(spec[0]), float(spec[1]), float(spec[2]))
	for i in look.integer("sfx", "players"):
		var player := AudioStreamPlayer.new()
		player.volume_db = look.num("sfx", "volume_db")
		add_child(player)
		_players.append(player)


## Plays [param sound] (one of [constant NAMES]).
func play(sound: StringName) -> void:
	if _players.is_empty() or not _streams.has(sound):
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[sound]
	player.play()


## Plays [param sound] at [param pos] in the world (louder when the farmer is near), with
## [param boost_db] added. Falls back to the plain player when there are no 3D players.
func play_at(sound: StringName, pos: Vector3, boost_db: float = 0.0) -> void:
	if not _streams.has(sound):
		return
	if _players_3d.is_empty():
		play(sound)
		return
	var p3: AudioStreamPlayer3D = _players_3d[_next_3d]
	_next_3d = (_next_3d + 1) % _players_3d.size()
	p3.stream = _streams[sound]
	p3.global_position = pos
	p3.volume_db = _look.num("sfx", "volume_db") + boost_db
	p3.pitch_scale = randf_range(0.93, 1.07)
	p3.play()


## A 3D player of [param sound] to attach to something that moves (the truck engine); with
## [param loop] it starts again when it ends.
func make_player_3d(sound: StringName, loop: bool) -> AudioStreamPlayer3D:
	var p3 := AudioStreamPlayer3D.new()
	p3.stream = _streams.get(sound)
	p3.unit_size = _look.num("sfx", "unit_size")
	p3.max_distance = _look.num("sfx", "max_distance")
	p3.volume_db = _look.num("sfx", "volume_db")
	if loop:
		p3.finished.connect(p3.play)
	return p3


## Ambience loop [param sound] at [param volume_db] (silent and stopped at -60 dB or less).
func set_loop(sound: StringName, volume_db: float) -> void:
	if not _streams.has(sound):
		return
	if not _loops.has(sound):
		var p := AudioStreamPlayer.new()
		p.stream = _streams[sound]
		p.finished.connect(p.play)
		add_child(p)
		_loops[sound] = p
	var player: AudioStreamPlayer = _loops[sound]
	player.volume_db = lerpf(player.volume_db, volume_db, 0.2) if player.playing else volume_db
	if volume_db <= -60.0:
		player.stop()
	elif not player.playing:
		player.play()


## Turns all sound on or off (mutes the master bus).
func set_enabled(on: bool) -> void:
	AudioServer.set_bus_mute(0, not on)


func _tone(rate: int, from_hz: float, seconds: float, to_hz: float) -> AudioStreamWAV:
	var count: int = int(float(rate) * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase: float = 0.0
	var end_hz: float = to_hz if to_hz > 0.0 else from_hz
	for i in count:
		var t: float = float(i) / float(maxi(count - 1, 1))
		phase += TAU * lerpf(from_hz, end_hz, t) / float(rate)
		var envelope: float = minf(1.0, t * 20.0) * (1.0 - t)
		var sample: int = int(sin(phase) * envelope * 0.6 * 32767.0)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
