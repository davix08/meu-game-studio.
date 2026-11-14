extends Node
## Player options and cross-scene data (autoload "GameSettings").
##
## Also registers the input actions at startup so the project file stays readable
## and the keyboard bindings used for desktop testing live next to the touch ones.

const InputActions := preload("res://src/autoload/input_actions.gd")

## Fire continuously without holding the shoot button (recommended on touch).
var auto_fire: bool = true
## Force the on-screen controls even without a touchscreen (desktop testing).
var force_touch_controls: bool = false
## Result of the last fight, read by the results screen.
var last_result: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputActions.register_all()


func _notification(what: int) -> void:
	# Mobile: pause when the app goes to background or loses focus.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		EventBus.pause_requested.emit()


## True when the on-screen touch controls should be shown.
func wants_touch_controls() -> bool:
	return force_touch_controls or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
