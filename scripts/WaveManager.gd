extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared
signal encounter_failed(reason: String)

var current_wave: int = 0
var max_waves: int = 3
var wave_active: bool = false
var innkeeper_unit: Unit = null

# Wave definitions: each wave is an array of enemy keys from enemies.json
var wave_definitions = [
	# Wave 1: Scouts
	[
		{"key": "Goblin Melee", "pos": Vector2(600, 300)},
		{"key": "Goblin Archer", "pos": Vector2(650, 250)},
	],
	# Wave 2: Horde
	[
		{"key": "Goblin Melee", "pos": Vector2(580, 280)},
		{"key": "Goblin Melee", "pos": Vector2(620, 320)},
		{"key": "Goblin Archer", "pos": Vector2(660, 260)},
		{"key": "Goblin Archer", "pos": Vector2(640, 340)},
	],
	# Wave 3: Leader + guards
	[
		{"key": "Goblin Leader", "pos": Vector2(620, 300)},
		{"key": "Goblin Melee", "pos": Vector2(580, 260)},
		{"key": "Goblin Melee", "pos": Vector2(580, 340)},
	],
]

var active_enemies: Array[Unit] = []
var unit_scene: PackedScene = null

func _ready():
	unit_scene = preload("res://scenes/Unit.tscn")

func start_encounter(innkeeper: Unit):
	innkeeper_unit = innkeeper
	current_wave = 0
	spawn_next_wave()

func spawn_next_wave():
	if current_wave >= max_waves:
		all_waves_cleared.emit()
		return
	
	var wave_data = wave_definitions[current_wave]
	active_enemies.clear()
	
	wave_started.emit(current_wave + 1)
	
	for enemy_def in wave_data:
		var enemy_key = enemy_def["key"]
		var spawn_pos = enemy_def["pos"]
		var enemy_data = GameManager.get_enemy_data(enemy_key)
		
		if enemy_data.is_empty():
			continue
		
		var enemy_unit: Unit = unit_scene.instantiate()
		get_parent().add_child(enemy_unit)
		enemy_unit.global_position = spawn_pos
		
		enemy_unit.unit_name = enemy_data["name"]
		enemy_unit.max_hp = enemy_data["hp"]
		enemy_unit.hp = enemy_data["hp"]
		enemy_unit.attack_stat = enemy_data["attack"]
		enemy_unit.ac = enemy_data["ac"]
		enemy_unit.abilities = enemy_data.get("abilities", [])
		enemy_unit.is_enemy = true
		enemy_unit.is_ai = true
		enemy_unit.ai_type = enemy_data.get("ai_type", "melee")
		
		enemy_unit.unit_died.connect(_on_enemy_died)
		active_enemies.append(enemy_unit)
	
	wave_active = true

func _on_enemy_died(unit: Unit):
	active_enemies.erase(unit)
	
	if active_enemies.size() == 0 and wave_active:
		wave_active = false
		wave_cleared.emit(current_wave + 1)
		current_wave += 1
		
		# Short delay before next wave
		await get_tree().create_timer(2.0).timeout
		spawn_next_wave()

func check_fail_conditions(party: Array) -> String:
	# Check innkeeper
	if innkeeper_unit and not innkeeper_unit.is_alive():
		return "innkeeper_died"
	
	# Check party wipe
	var any_alive = false
	for unit in party:
		if unit.is_alive():
			any_alive = true
			break
	
	if not any_alive:
		return "party_wipe"
	
	return ""

func get_all_enemies() -> Array[Unit]:
	return active_enemies

func is_encounter_active() -> bool:
	return wave_active or current_wave < max_waves
