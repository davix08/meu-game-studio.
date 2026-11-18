extends SceneTree
## One side of the two-process coop test (design/gdd/coop-lan.md AC). Run by
## tests/integration/net/run_coop_test.sh: a host and a client on 127.0.0.1 exchange
## presence and a catch, and each checks what it received. Exit 0 = pass, 1 = fail.

const PORT: int = 7801
const TIMEOUT: float = 20.0

var _role: String = ""
var _net: NetSession
var _got_state: PlayerSnapshot = null
var _got_catch: Array = []
var _joined: Array = []
var _started: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_role = args[0] if args.size() > 0 else ""
	_net = NetSession.new()
	_net.name = "Net"
	root.add_child(_net)
	_net.remote_state.connect(func(_id: int, s: PlayerSnapshot) -> void: _got_state = s)
	_net.remote_catch.connect(func(_id: int, sp: String, w: float, l: float) -> void: _got_catch = [sp, w, l])
	_net.player_joined.connect(func(id: int, slot: int) -> void: _joined.append([id, slot]))
	_net.session_started.connect(func() -> void: _started = true)
	_run.call_deferred()


func _run() -> void:
	await process_frame # The session node must be in the tree to reach the multiplayer API.
	var err: Error = _net.host(PORT) if _role == "host" else _net.join("127.0.0.1", PORT)
	if err != OK:
		_finish(false, "start failed: %d" % err)
		return
	var t: float = 0.0
	var mine := PlayerSnapshot.new()
	mine.pos = Vector2(10.5, 20.25) if _role == "host" else Vector2(30.5, 5.75)
	mine.has_rod = true
	mine.rod_color = "#5ab0d8"
	var sent_catch: bool = false
	while t < TIMEOUT:
		await process_frame
		var dt: float = get_root().get_process_delta_time()
		t += dt
		if not _started:
			continue
		_net.send_state(mine, 1.0)
		if not sent_catch and (_role == "client" or _got_catch.size() > 0):
			_net.send_catch("carpa" if _role == "client" else "tilapia", 4.51, 63.0)
			sent_catch = true
		if _got_state != null and _got_catch.size() > 0 and _joined.size() > 0:
			var want: Vector2 = Vector2(30.5, 5.75) if _role == "host" else Vector2(10.5, 20.25)
			var want_sp: String = "carpa" if _role == "host" else "tilapia"
			var ok: bool = _got_state.pos == want and _got_state.rod_color == "#5ab0d8" and _got_catch[0] == want_sp and is_equal_approx(_got_catch[1], 4.51)
			var slot_ok: bool = _role == "host" and _joined[0][1] == 1 or _role == "client" and _net.my_slot() == 1 and _joined[0][1] == 0
			# Give the other side time to receive our catch before closing.
			for i: int in 30:
				_net.send_state(mine, 1.0)
				await process_frame
			_finish(ok and slot_ok, "state=%s catch=%s joined=%s my_slot=%d" % [_got_state.pos, str(_got_catch), str(_joined), _net.my_slot()])
			return
	_finish(false, "timeout: started=%s state=%s catch=%s joined=%s" % [_started, _got_state != null, str(_got_catch), str(_joined)])


func _finish(ok: bool, detail: String) -> void:
	print("%s %s: %s" % ["PASS" if ok else "FAIL", _role, detail])
	quit(0 if ok else 1)
