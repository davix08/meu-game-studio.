extends MiniSuite
## Coop wire formats (design/gdd/coop-lan.md): presence snapshots and room beacons.


func test_snapshot_round_trip_keeps_every_field() -> void:
	var s := PlayerSnapshot.new()
	s.pos = Vector2(12.5, 7.25)
	s.yaw = 1.5
	s.pose = Fisherman.Pose.FIGHT
	s.cast_progress = 0.4
	s.has_rod = true
	s.rod_color = "#c8a45a"
	var back: PlayerSnapshot = PlayerSnapshot.from_wire(s.to_wire())
	assert_true(back != null, "decoded")
	assert_eq(back.pos, s.pos, "pos")
	assert_eq(back.yaw, s.yaw, "yaw")
	assert_eq(back.pose, s.pose, "pose")
	assert_eq(back.cast_progress, s.cast_progress, "cast progress")
	assert_true(back.has_rod, "has rod")
	assert_eq(back.rod_color, "#c8a45a", "rod color")


func test_snapshot_without_rod_sends_empty_color() -> void:
	var s := PlayerSnapshot.new()
	s.rod_color = "#ffffff"
	var back: PlayerSnapshot = PlayerSnapshot.from_wire(s.to_wire())
	assert_true(not back.has_rod, "no rod")


func test_malformed_snapshots_are_rejected() -> void:
	assert_true(PlayerSnapshot.from_wire(null) == null, "null")
	assert_true(PlayerSnapshot.from_wire([1, 2, 3]) == null, "too short")
	assert_true(PlayerSnapshot.from_wire(["a", 0, 0, 0, 0, ""]) == null, "string position")
	assert_true(PlayerSnapshot.from_wire([0, 0, 0, 0, 0, 5]) == null, "number color")
	assert_true(PlayerSnapshot.from_wire([0, 0, 0, 0, 0, "not a color"]) == null, "bad color")


func test_snapshot_clamps_pose_and_cast_progress() -> void:
	var back: PlayerSnapshot = PlayerSnapshot.from_wire([0, 0, 0, 99, 7.0, ""])
	assert_eq(back.pose, Fisherman.Pose.size() - 1, "pose clamped")
	assert_eq(back.cast_progress, 1.0, "cast clamped")


func test_beacon_round_trip() -> void:
	var info: Dictionary = LanBeacon.decode(LanBeacon.encode("Sala 192.168.0.5", 3, 7777))
	assert_eq(info.get("name"), "Sala 192.168.0.5", "name")
	assert_eq(info.get("players"), 3, "players")
	assert_eq(info.get("port"), 7777, "port")


func test_beacon_rejects_foreign_and_malformed_packets() -> void:
	assert_true(LanBeacon.decode("OTHERAPP|x|1|7777".to_utf8_buffer()).is_empty(), "other app")
	assert_true(LanBeacon.decode("MYSTICTIDES1|x|one|7777".to_utf8_buffer()).is_empty(), "bad players")
	assert_true(LanBeacon.decode("MYSTICTIDES1|x|1|99999".to_utf8_buffer()).is_empty(), "bad port")
	assert_true(LanBeacon.decode(PackedByteArray()).is_empty(), "empty")


func test_beacon_name_cannot_inject_fields() -> void:
	var info: Dictionary = LanBeacon.decode(LanBeacon.encode("a|9|1", 2, 7777))
	assert_eq(info.get("players"), 2, "players not overridden")
