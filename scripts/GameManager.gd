extends Node

signal scene_changed

enum GameState { MENU, EXPLORATION, COMBAT, CUTSCENE }

var current_state: GameState = GameState.MENU
var player_data: Dictionary = {}
var party_members: Array = []
var current_room: String = ""
var innkeeper_alive: bool = true

var character_classes: Dictionary = {}
var enemy_data: Dictionary = {}
var ability_data: Dictionary = {}

func _ready() -> void:
	load_game_data()
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func load_game_data() -> void:
	# Load character classes
	var classes_file := FileAccess.open("res://data/character_classes.json", FileAccess.READ)
	if classes_file:
		var classes_json := classes_file.get_as_text()
		classes_file.close()
		character_classes = JSON.parse_string(classes_json)
	
	# Load enemy data
	var enemies_file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if enemies_file:
		var enemies_json := enemies_file.get_as_text()
		enemies_file.close()
		enemy_data = JSON.parse_string(enemies_json)
	
	# Load abilities data
	var abilities_file := FileAccess.open("res://data/abilities.json", FileAccess.READ)
	if abilities_file:
		var abilities_json := abilities_file.get_as_text()
		abilities_file.close()
		ability_data = JSON.parse_string(abilities_json)

func create_player_character(class_name: String, player_name: String = "") -> void:
	if character_classes.has(class_name):
		var class_data: Dictionary = character_classes[class_name]
		player_data = {
			"name": (player_name != "" ? player_name : class_name),
			"class": class_name,
			"level": 1,
			"hp": class_data["base_hp"],
			"max_hp": class_data["base_hp"],
			"attack": class_data["base_attack"],
			"ac": class_data["base_ac"],
			"abilities": class_data["abilities"].duplicate(),
			"status_effects": {}
		}

func create_companion(class_name: String) -> Dictionary:
	if character_classes.has(class_name):
		var class_data: Dictionary = character_classes[class_name]
		return {
			"name": class_data["name"],
			"class": class_name,
			"level": 1,
			"hp": class_data["base_hp"],
			"max_hp": class_data["base_hp"],
			"attack": class_data["base_attack"],
			"ac": class_data["base_ac"],
			"abilities": class_data["abilities"].duplicate(),
			"status_effects": {},
			"is_ai": true,
			"ai_type": class_data["ai_type"]
		}
	return {}

func start_new_game() -> void:
	party_members.clear()
	current_room = "entrance"
	innkeeper_alive = true
	current_state = GameState.EXPLORATION
	change_scene("res://scenes/GameWorld.tscn")

func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit()

func get_character_class_data(class_name: String) -> Dictionary:
	return character_classes.get(class_name, {})

func get_enemy_data(enemy_name: String) -> Dictionary:
	return enemy_data.get(enemy_name, {})

func get_ability_data(ability_name: String) -> Dictionary:
	return ability_data.get(ability_name, {})
