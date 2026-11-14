extends RefCounted
## Input action names and their desktop keyboard bindings.
##
## Touch controls drive the same actions through Input.action_press(), so gameplay
## code only ever reads actions.

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const JUMP := &"jump"
const SHOOT := &"shoot"
const DASH := &"dash"
const SPECIAL := &"special"
const LOCK_AIM := &"lock_aim"
const PAUSE := &"pause"

const KEY_BINDINGS := {
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	MOVE_UP: [KEY_W, KEY_UP],
	MOVE_DOWN: [KEY_S, KEY_DOWN],
	JUMP: [KEY_SPACE, KEY_Z],
	SHOOT: [KEY_J, KEY_X],
	DASH: [KEY_SHIFT, KEY_C],
	SPECIAL: [KEY_K, KEY_V],
	LOCK_AIM: [KEY_L, KEY_CTRL],
	PAUSE: [KEY_ESCAPE, KEY_P],
}


## Adds every action (if missing) with its keyboard bindings.
static func register_all() -> void:
	for action: StringName in KEY_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for keycode: int in KEY_BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
