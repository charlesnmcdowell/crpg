extends Node

signal scene_changed

enum GameState {
	MENU,
	EXPLORATION,
	COMBAT,
	CUTSCENE
}

var current_state: GameState = GameState.MENU
var player_data = {}
var party_members = []
var current_room = ""
var innkeeper_alive = true

var character_classes = {}
var enemy_data = {}
var ability_data = {}

func _ready():
	load_game_data()
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func load_game_data():
	# Load character classes
	var classes_file = FileAccess.open("res://data/character_classes.json", FileAccess.READ)
	if classes_file:
		var classes_json = classes_file.get_as_text()
		classes_file.close()
		character_classes = JSON.parse_string(classes_json)
	
	# Load enemy data
	var enemies_file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if enemies_file:
		var enemies_json = enemies_file.get_as_text()
		enemies_file.close()
		enemy_data = JSON.parse_string(enemies_json)
	
	# Load abilities data
	var abilities_file = FileAccess.open("res://data/abilities.json", FileAccess.READ)
	if abilities_file:
		var abilities_json = abilities_file.get_as_text()
		abilities_file.close()
		ability_data = JSON.parse_string(abilities_json)

func create_player_character(class_name: String, player_name: String = "") -> void:
	if class_name in character_classes:
		var class_data = character_classes[class_name]
		player_data = {
			"name": player_name if player_name != "" else class_name,
			"class": class_name,
			"level": 1,
			"hp": class_data["base_hp"],
			"max_hp": class_data["base_hp"],
			"attack": class_data["base_attack"],
			"ac": class_data["base_ac"],
			"abilities": class_data["abilities"].duplicate(),
			"status_effects": {}
		}

func create_companion(class_name: String):
	if class_name in character_classes:
		var class_data = character_classes[class_name]
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

func start_new_game():
	party_members.clear()
	current_room = "entrance"
	innkeeper_alive = true
	current_state = GameState.EXPLORATION
	change_scene("res://scenes/GameWorld.tscn")

func change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit()

func get_character_class_data(class_name: String):
	return character_classes.get(class_name, {})

func get_enemy_data(enemy_name: String):
	return enemy_data.get(enemy_name, {})

func get_ability_data(ability_name: String):
	return ability_data.get(ability_name, {})