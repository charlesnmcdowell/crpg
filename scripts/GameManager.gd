extends Node

signal scene_changed

enum GameState { MENU, EXPLORATION, COMBAT }

var current_state: GameState = GameState.MENU
var player_data: Dictionary = {}
var current_room: String = "entrance"

func _ready() -> void:
	player_data = {
		"name": "Warrior",
		"class": "Warrior",
		"level": 1,
		"hp": 20,
		"max_hp": 20,
		"attack": 8,
		"ac": 14
	}
	print("GameManager ready - Player: Warrior")

func start_new_game() -> void:
	current_room = "entrance"
	current_state = GameState.EXPLORATION
	change_scene("res://scenes/GameWorld.tscn")

func change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene missing: " + scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit()
