class_name Gathering
extends RefCounted
## Gathering spots and the bench (design/gdd/gathering-crafting.md).
##
## A spot gives its material and disappears until gather_respawn minutes of game time
## pass. A recipe consumes materials and makes a material, a rod (owned and equipped)
## or a bait (owned and equipped). Pure logic: the world view reads [method is_available].
##
## Usage:
## [codeblock]
## var g := Gathering.new(data, state)
## if g.gather("galho_1") == Gathering.Result.OK: pass
## g.craft("vara_artesanal")
## [/codeblock]

## A material count changed (gathered or crafted).
signal materials_changed
## A spot was gathered (the view hides it).
signal node_gathered(node_id: String)

## Outcome of [method gather] and [method craft].
enum Result {
	OK,
	GONE, ## The spot was gathered and has not come back yet.
	UNKNOWN, ## No spot or recipe with that id.
	MISSING, ## Not enough materials.
	OWNED, ## The rod or bait is already owned.
}

var _data: GameData
var _state: GameState


## Builds it over [param data] and the player's [param state].
func _init(data: GameData, state: GameState) -> void:
	_data = data
	_state = state


## True when spot [param node_id] can be gathered now. A spot whose time has come is freed.
func is_available(node_id: String) -> bool:
	if not _state.gathered.has(node_id):
		return true
	if _state.total_minutes() >= _state.gathered[node_id]:
		_state.gathered.erase(node_id)
		return true
	return false


## Gathers spot [param node_id]: adds its material and starts its respawn timer.
func gather(node_id: String) -> Result:
	var node: GameData.GatherNode = _node(node_id)
	if node == null:
		return Result.UNKNOWN
	if not is_available(node_id):
		return Result.GONE
	_state.materials[node.kind] = _state.material_count(node.kind) + _data.gather_amount[node.kind]
	_state.gathered[node_id] = _state.total_minutes() + _data.gather_respawn[node.kind]
	node_gathered.emit(node_id)
	materials_changed.emit()
	return Result.OK


## Why [param recipe_id] cannot be made now, or [constant Result.OK].
func craft_blocker(recipe_id: String) -> Result:
	var recipe: GameData.Recipe = _recipe(recipe_id)
	if recipe == null:
		return Result.UNKNOWN
	if recipe.gives_kind == "rod" and _state.rods_owned.has(recipe.gives_id):
		return Result.OWNED
	if recipe.gives_kind == "bait" and _state.baits_owned.has(recipe.gives_id):
		return Result.OWNED
	for id: String in recipe.needs:
		if _state.material_count(id) < recipe.needs[id]:
			return Result.MISSING
	return Result.OK


## Makes [param recipe_id]: consumes its materials and gives (and equips) what it makes.
func craft(recipe_id: String) -> Result:
	var blocked: Result = craft_blocker(recipe_id)
	if blocked != Result.OK:
		return blocked
	var recipe: GameData.Recipe = _recipe(recipe_id)
	for id: String in recipe.needs:
		_state.materials[id] = _state.material_count(id) - recipe.needs[id]
	match recipe.gives_kind:
		"material":
			_state.materials[recipe.gives_id] = _state.material_count(recipe.gives_id) + recipe.gives_amount
		"rod":
			var owned: PackedStringArray = _state.rods_owned
			owned.append(recipe.gives_id)
			_state.rods_owned = owned
			_state.rod = recipe.gives_id
		"bait":
			var owned_baits: PackedStringArray = _state.baits_owned
			owned_baits.append(recipe.gives_id)
			_state.baits_owned = owned_baits
			_state.bait = recipe.gives_id
	materials_changed.emit()
	return Result.OK


func _node(node_id: String) -> GameData.GatherNode:
	for n: GameData.GatherNode in _data.gather_nodes:
		if n.id == node_id:
			return n
	return null


func _recipe(recipe_id: String) -> GameData.Recipe:
	for r: GameData.Recipe in _data.recipes:
		if r.id == recipe_id:
			return r
	return null
