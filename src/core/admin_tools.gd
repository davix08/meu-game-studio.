class_name AdminTools
extends RefCounted
## The owner's test mode (2026-11-22). Two locks keep players out:
##   1. [method available] is false in release exports (OS.is_debug_build()), so the mode only
##      exists when the game runs from the editor or a debug export.
##   2. A password the owner creates in the game. Only a salted SHA-256 hash is kept, in
##      user://admin.json on that device; the password itself is never stored nor in the code.
##      Five wrong tries lock it for a minute.
## The cheats ([method give_coins] and friends) change [GameState] through the farm systems.
##
## Usage:
## [codeblock]
## if AdminTools.available() and AdminTools.check_password(typed):
##     admin.give_coins(100000)
## [/codeblock]

const FILE: String = "user://admin.json"
const MAX_TRIES: int = 5
const LOCK_SECONDS: float = 60.0

static var _tries: int = 0
static var _locked_until: float = 0.0

var _ctx: GameContext


## Builds the cheats over the game systems.
func _init(ctx: GameContext) -> void:
	_ctx = ctx


## True only in debug builds (editor or debug export); release exports have no admin mode.
static func available() -> bool:
	return OS.is_debug_build()


## True when a password was already created on this device.
static func has_password() -> bool:
	return FileAccess.file_exists(FILE)


## Creates the password (at least 4 characters). Returns false when too short or not saved.
static func create_password(password: String) -> bool:
	if password.length() < 4:
		return false
	var salt: String = Crypto.new().generate_random_bytes(16).hex_encode()
	var file: FileAccess = FileAccess.open(FILE, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"salt": salt, "hash": (salt + password).sha256_text()}))
	file.close()
	return true


## Seconds left of the lock after too many wrong tries (0 when not locked).
static func lock_left() -> int:
	return maxi(0, ceili(_locked_until - Time.get_unix_time_from_system()))


## True when [param password] matches the saved hash. Counts wrong tries and locks after five.
static func check_password(password: String) -> bool:
	if not available() or lock_left() > 0 or not has_password():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if not (parsed is Dictionary):
		return false
	var saved: Dictionary = parsed
	if (str(saved.get("salt", "")) + password).sha256_text() == str(saved.get("hash", "")):
		_tries = 0
		return true
	_tries += 1
	if _tries >= MAX_TRIES:
		_tries = 0
		_locked_until = Time.get_unix_time_from_system() + LOCK_SECONDS
	return false


## Deletes the saved password (only from inside the admin mode).
static func forget_password() -> void:
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))


# --- Cheats ---

## Adds coins.
func give_coins(amount: int) -> void:
	_ctx.state.coins += amount


## Adds [param amount] of every good (materials, crops, feeds, products), ignoring storage limits.
func give_all_goods(amount: int) -> void:
	for g: Variant in _ctx.town_data.goods():
		var id: String = str((g as Dictionary)["id"])
		_ctx.state.shed[id] = int(_ctx.state.shed.get(id, 0)) + amount
	_ctx.state.town_changed.emit()


## Adds farm experience up to the next level (or to the top with [param to_top]).
func farm_level_up(to_top: bool) -> void:
	var table: Array = _ctx.town_data.list("farm_life", "level_xp")
	var target: int = int(table[table.size() - 1]) if to_top else int(table[mini(_ctx.farm.level(), table.size() - 1)])
	_ctx.farm.add_xp(maxi(0, target - _ctx.state.farm_xp))


## Fills the energy.
func fill_energy() -> void:
	_ctx.state.energy = _ctx.data.fixed("energy_max")


## Gives the axe and the pickaxe.
func give_tools() -> void:
	for id: String in ["machado", "picareta"]:
		if not _ctx.state.tools.has(id):
			_ctx.state.tools.append(id)
	_ctx.state.town_changed.emit()


## Makes every running timer (crops, factories, animals, stall, orders) finish now.
func finish_timers() -> void:
	_ctx.production.skip_time(1.0e9)


## Raises the silo and the barn by five levels each.
func big_storage() -> void:
	for kind: String in ["silo", "barn"]:
		_ctx.state.storage_levels[kind] = int(_ctx.state.storage_levels.get(kind, 0)) + 5
	_ctx.state.town_changed.emit()
