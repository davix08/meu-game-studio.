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

## Map id for the outdoor lake map (the only one where fishing is allowed).
const MAP_OUTDOOR: String = "out"
## Map id for the house interior.
const MAP_INDOOR: String = "in"


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
## Current map: [constant MAP_OUTDOOR] or [constant MAP_INDOOR].
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


## Total sale value of the bag.
func bag_value() -> int:
	var total: int = 0
	for fish: Catch in bag:
		total += fish.value
	return total


## Number of species discovered (entries in the book).
func discovered() -> int:
	return book.size()
