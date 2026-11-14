class_name LevelManager
extends Node2D
## Runs a boss fight from intro to result (the "LevelManager").
##
## States: INTRO -> FIGHT -> VICTORY | DEFEAT. Wires the player and the boss,
## owns the announcer text and the pause / defeat menus.

enum State { INTRO, FIGHT, VICTORY, DEFEAT }

const RESULTS_SCENE := "res://src/ui/results/results_screen.tscn"
const TITLE_SCENE := "res://src/ui/title/title_screen.tscn"

@export var intro_ready_time: float = 1.2
@export var intro_go_time: float = 0.6
@export var victory_slowmo_time: float = 1.6

@onready var player: Player = $Player
@onready var boss: Boss = $Boss
@onready var projectiles: Node2D = $Projectiles
@onready var hud: Hud = $Hud

var state: State = State.INTRO
var elapsed: float = 0.0


func _ready() -> void:
	player.weapon.projectile_parent = projectiles
	boss.projectile_parent = projectiles
	boss.target = player
	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.pause_requested.connect(_on_pause_requested)
	hud.retry_pressed.connect(_retry)
	hud.quit_pressed.connect(_quit_to_title)
	_run_intro()


func _process(delta: float) -> void:
	if state == State.FIGHT:
		elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and state == State.FIGHT:
		_on_pause_requested()


func _run_intro() -> void:
	state = State.INTRO
	hud.announce("PREPARE-SE")
	await get_tree().create_timer(intro_ready_time, false).timeout
	hud.announce("LUTE!")
	await get_tree().create_timer(intro_go_time, false).timeout
	hud.announce("")
	state = State.FIGHT
	player.controls_enabled = true
	boss.start_fight()


func _on_boss_defeated() -> void:
	if state != State.FIGHT:
		return
	state = State.VICTORY
	player.controls_enabled = false
	_clear_projectiles()
	hud.announce("VITORIA!")
	Engine.time_scale = 0.35
	await get_tree().create_timer(victory_slowmo_time, false, false, true).timeout
	Engine.time_scale = 1.0
	GameSettings.last_result = {
		"boss": boss.data.display_name,
		"time": elapsed,
		"health": player.health.current_health,
		"max_health": player.health.max_health,
		"parries": player.parry_count,
		"super_cards": player.super_meter.full_cards(),
	}
	get_tree().change_scene_to_file(RESULTS_SCENE)


func _on_player_died() -> void:
	if state != State.FIGHT:
		return
	state = State.DEFEAT
	boss.stop_fight()
	hud.announce("VOCE CAIU")
	await get_tree().create_timer(1.4, false).timeout
	hud.show_defeat_menu(1.0 - boss.health.fraction(), boss.data.display_name)


func _on_pause_requested() -> void:
	if state != State.FIGHT or get_tree().paused:
		return
	get_tree().paused = true
	hud.show_pause_menu()


func _clear_projectiles() -> void:
	for child: Node in projectiles.get_children():
		child.queue_free()


func _retry() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _quit_to_title() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(TITLE_SCENE)
