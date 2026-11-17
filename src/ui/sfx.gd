class_name Sfx
extends Node
## Small sound effects made in code (Story 006, so the Sound setting does something real): each
## sound is a short tone sliding from one pitch to another, generated once as an
## [AudioStreamWAV] and played from a small pool of players. The sound setting mutes the master
## bus. Pitches and lengths come from the "sfx" group of world_look.json as [from_hz, seconds, to_hz].
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


## Generates the tones and the player pool.
func setup(look: WorldLook) -> void:
	var rate: int = look.integer("sfx", "mix_rate")
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
