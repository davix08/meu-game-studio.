class_name GameState
extends RefCounted
## The player's progress: everything the save file keeps, plus the resting flag.
##
## Pure data with change signals. Systems ([Economy], [Progression], [GameClock],
## [Energy], [FishingMachine]) change it; the 3D scenes and the UI listen to the
## signals. Not thread-safe: one simulation thread owns it.
##
## Usage:
## [codeblock]
## var data := GameData.load_from_dir()
## var state := GameState.create_new(data)
## state.coins_changed.connect(func(coins: int) -> void: print(coins))
## state.coins += 10
## [/codeblock]

## Coins changed (any reason: sale, purchase, level reward).
signal coins_changed(new_coins: int)
## Energy changed.
signal energy_changed(new_energy: float)
## The player reached [param new_level] and was paid [param reward] coins.
signal level_up(new_level: int, reward: int)
## A fish went into the bag. [param is_new]: first of its species; [param is_record]: heaviest so far.
signal fish_caught(fish: Catch, is_new: bool, is_record: bool)
## A new day began (manual or automatic sleep). The world puts the player back at the spawn.
signal day_started(new_day: int, auto: bool)
## Something in the town changed (storage, goods, plots, animals, lots, clothes, restaurant).
## The 3D views and open screens refresh on it. Emitted by the town systems (Stories 010-018).
signal town_changed
## The city reached [param new_level] and paid [param reward] coins (Story 018).
signal city_level_up(new_level: int, reward: int)

## Map id for the outdoor lake map (the only one where fishing is allowed).
const MAP_OUTDOOR: String = "out"
## Map id for the house interior.
const MAP_INDOOR: String = "in"
## Inside the barn (2026-11-22).
const MAP_BARN: String = "barn"


## One caught fish in the bag.
class Catch:
	extends RefCounted
	## Species id.
	var id: String = ""
	## Weight in kg, rounded to the configured decimals.
	var weight: float = 0.0
	## Sale value in coins.
	var value: int = 0


## The collection book entry of one discovered species.
class BookEntry:
	extends RefCounted
	## How many were caught.
	var count: int = 0
	## Heaviest catch in kg.
	var best: float = 0.0


## Coins.
var coins: int = 0:
	set(new_value):
		coins = new_value
		coins_changed.emit(coins)
## Player level, 1-based.
var level: int = 1
## Day number, 1-based.
var day: int = 1
## Game minutes since midnight of the current day (passes 1440 after midnight until the day ends).
var minutes: float = 0.0
## Energy, 0..energy_max.
var energy: float = 0.0:
	set(new_value):
		energy = new_value
		energy_changed.emit(energy)
## Fish in the bag.
var bag: Array[Catch] = []
## Collection book: species id -> entry. Its size is the number discovered.
var book: Dictionary[String, BookEntry] = {}
## Ids of owned rods.
var rods_owned: PackedStringArray = PackedStringArray()
## Equipped rod id.
var rod: String = ""
## Ids of owned baits.
var baits_owned: PackedStringArray = PackedStringArray()
## Equipped bait id.
var bait: String = ""
## Snacks owned.
var snacks: int = 0
## Luck baits owned.
var luck_baits: int = 0
## Game minutes of luck bait effect left.
var luck_left: float = 0.0
## Current map: [constant MAP_OUTDOOR], [constant MAP_INDOOR] (the house) or [constant MAP_BARN].
var map: String = MAP_OUTDOOR
## Lifetime fish caught.
var stats_caught: int = 0
## Lifetime coins earned from sales.
var stats_earned: int = 0
## Player position in world units. Set by the 3D world (story 002); saved and loaded here.
var position: Vector3 = Vector3.ZERO
## Player facing, as saved by the 2D (0 down, 1 up, 2 left, 3 right). Interpreted by the 3D world.
var dir: int = 0
## True while resting (energy regenerates, time runs faster). Not saved, as in the 2D.
var resting: bool = false

# --- Town (Stories 010-018). Saved by [SaveGame] format 3. ---
## Fish kept in the warehouse (Story 010).
var storage: Array[Catch] = []
## Warehouse expansions bought.
var storage_upgrades: int = 0
## Workshop level of each rod id (missing = 0) (Story 011).
var rod_levels: Dictionary[String, int] = {}
## Countable goods: crops, eggs, milk, wool, seeds, feed (good id -> count).
var goods: Dictionary[String, int] = {}
## Neighbor requests: neighbor id -> {"species", "count", "ready_day", "done"} (Story 012).
var requests: Dictionary = {}
## Farm plots in plot order: {"crop": "" or crop id, "days": int, "watered": bool} (Story 015).
var plots: Array[Dictionary] = []
## Game minutes left of the garden bait (a crop used as bait).
var garden_bait_left: float = 0.0
## Animals: {"kind": animal id, "joy": float} (Story 016).
var animals: Array[Dictionary] = []
## Feed units in the trough of each ranch home (home id -> units).
var troughs: Dictionary[String, int] = {}
## Products waiting to be collected at each home: home id -> {good id: count}.
var pending: Dictionary = {}
## Clothing pieces owned (Story 017).
var clothes_owned: PackedStringArray = PackedStringArray()
## Equipped piece per slot ("hat", "shirt", "boots" -> piece id).
var outfit: Dictionary[String, String] = {}
## Lot ids built (Story 018).
var lots_built: PackedStringArray = PackedStringArray()
## City level, 1-based.
var city_level: int = 1
## Recent deliveries to neighbors, decaying every day (feeds the satisfaction).
var request_score: float = 0.0
## How well the restaurant fed the neighbors lately, 0..1.
var food_score: float = 0.5
## Restaurant dishes on sale: {"name": String, "value": int} (Story 014).
var dishes: Array[Dictionary] = []
## Drinks left today.
var drinks: int = 0
## Coins the restaurant made today.
var sales_today: int = 0
## Meals the neighbors wanted today and how many found a dish.
var meals_wanted: int = 0
var meals_served: int = 0
## Neighbor walkers: id -> {"x": float, "z": float, "step": int} (Story 013).
var npcs: Dictionary = {}
# --- Farm (2026-11-19 farm map). Saved by [SaveGame] format 4. ---
## Farm experience; the farm level comes from it ([Farm.level]).
var farm_xp: int = 0
## Goods kept in the shed (galpão): good id -> count. The bag holds [member goods].
var shed: Dictionary = {}
## Paid orders waiting for the truck: {"dest": "galpao" or a home id, "items": {id: count}}.
var orders: Array[Dictionary] = []
## Boxes left by the truck, waiting to be opened: {"dest", "items"}.
var boxes: Array[Dictionary] = []
## Trees and rocks cut: placement index (as text) -> day they grow back.
var chopped: Dictionary = {}
## The milking machine is installed: milk goes to the bucket by itself.
var milker: bool = false
## The farmer holds the fishing rod (false: walking with it put away).
var rod_out: bool = true

# --- Real-time production (2026-11-21). Saved by [SaveGame] format 4 (new keys). ---
## Field plots: {"crop": crop id or "", "ready_at": Unix time}.
var crop_plots: Array[Dictionary] = []
## The starting crops were given.
var prod_started: bool = false
## Upgrades bought: "silo" / "barn" -> count.
var storage_levels: Dictionary = {}
## Factories: id -> {"slots": int, "queue": [{"item", "out", "xp", "ready_at"}]}.
var factories: Dictionary = {}
## Order board: {"items": {id: count}, "coins", "xp", "wait_until"}.
var order_board: Array[Dictionary] = []
## Roadside stall slots: {} or {"item", "count", "price", "sell_at", "sold"}.
var stall: Array = []
## Tools owned ("machado", "picareta"): needed to cut trees and break rocks.
var tools: PackedStringArray = PackedStringArray()
## Buildings placed by the player: id -> [x, y, w, h, door side] (2026-11-22).
var placed: Dictionary = {}
## Land expansions opened.
var expanded: PackedStringArray = PackedStringArray()
## Settings: sound on, FPS counter shown (Story 006).
var sound_on: bool = true
var show_fps: bool = false


## A new game, as the 2D freshState builds it, from config.json values.
##
## [codeblock]
## var state := GameState.create_new(GameData.load_from_dir())
## [/codeblock]
static func create_new(data: GameData) -> GameState:
	var state := GameState.new()
	state.coins = int(data.tune("start_coins"))
	state.level = int(data.fixed("start_level"))
	state.day = int(data.fixed("start_day"))
	state.minutes = data.tune("day_start")
	state.energy = data.fixed("energy_max")
	state.rod = data.fixed_text("start_rod")
	state.rods_owned = PackedStringArray([state.rod])
	state.bait = data.fixed_text("start_bait")
	state.baits_owned = PackedStringArray([state.bait])
	state.snacks = int(data.fixed("start_snacks"))
	return state


## Fills the town part of a new game from [param town] (lots built at the start, start animals,
## default clothes, a full trough day 1). Call once after [method create_new].
func init_town(town: TownData) -> void:
	for lot: Variant in town.lots():
		var l: Dictionary = lot
		if bool(l.get("start_built", false)):
			lots_built.append(str(l["id"]))
	for kind: Variant in town.list("ranch", "start_animals"):
		animals.append({"kind": str(kind), "joy": town.num("ranch", "joy_start")})
	for slot: String in ["hat", "shirt", "boots"]:
		var first: Dictionary = town.clothes(slot)[0]
		clothes_owned.append(str(first["id"]))
		outfit[slot] = str(first["id"])
	food_score = town.num("city", "food_start")
	drinks = int(town.num("restaurant", "drinks_per_day"))


## Count of a good.
func good_count(id: String) -> int:
	return goods.get(id, 0)


## Adds [param amount] (may be negative) of a good, never below 0.
func add_good(id: String, amount: int) -> void:
	goods[id] = maxi(0, good_count(id) + amount)


## True when the lot [param id] is built.
func is_built(id: String) -> bool:
	return lots_built.has(id)


## Total sale value of the bag.
func bag_value() -> int:
	var total: int = 0
	for fish: Catch in bag:
		total += fish.value
	return total


## Number of species discovered (entries in the book).
func discovered() -> int:
	return book.size()
