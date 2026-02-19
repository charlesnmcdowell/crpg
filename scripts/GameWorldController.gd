extends Node2D

enum Phase { EXPLORATION, COMBAT_SETUP, PLAYER_TURN, AI_TURN, WAVE_TRANSITION, ENDED }

var phase: Phase = Phase.EXPLORATION
var turn_queue: Array[Unit] = []
var current_turn_index: int = 0
var turn_number: int = 0
var player_unit: Unit = null
var party: Array[Unit] = []
var innkeeper: Unit = null
var selected_unit: Unit = null
var pending_action: String = ""  # "attack", "ability_0", "ability_1", "ability_2"
var companions_joined: bool = false

@onready var hud: CanvasLayer = $HUD
@onready var wave_manager: Node = $WaveManager
@onready var tilemap: TileMap = $TileMap
@onready var camera: Camera2D = $Camera2D

var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")

func _ready():
	# Connect HUD signals
	hud.attack_pressed.connect(_on_attack_pressed)
	hud.ability_pressed.connect(_on_ability_pressed)
	hud.end_turn_pressed.connect(_on_end_turn_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	
	# Connect wave manager signals
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	
	# Spawn player
	spawn_player()
	
	# Spawn innkeeper in common room
	spawn_innkeeper()
	
	hud.add_combat_log_entry("You enter the inn...")
	hud.add_combat_log_entry("Explore the rooms. Head to the common room.")

func spawn_player():
	player_unit = unit_scene.instantiate()
	add_child(player_unit)
	player_unit.global_position = Vector2(200, 400)  # Entrance area
	
	player_unit.unit_name = GameManager.player_data.get("name", "Hero")
	player_unit.unit_class = GameManager.player_data.get("class", "Warrior")
	player_unit.max_hp = GameManager.player_data.get("max_hp", 25)
	player_unit.hp = GameManager.player_data.get("hp", 25)
	player_unit.attack_stat = GameManager.player_data.get("attack", 14)
	player_unit.ac = GameManager.player_data.get("ac", 14)
	player_unit.abilities = GameManager.player_data.get("abilities", [])
	player_unit.is_enemy = false
	player_unit.is_ai = false
	
	player_unit.unit_selected.connect(_on_unit_selected)
	party.append(player_unit)
	
	# Set ability names on HUD
	hud.set_ability_names(player_unit.abilities)
	hud.update_unit_info(player_unit.unit_name, player_unit.hp, player_unit.max_hp, player_unit.unit_class)
	
	# Camera follows player
	camera.global_position = player_unit.global_position

func spawn_innkeeper():
	innkeeper = unit_scene.instantiate()
	add_child(innkeeper)
	innkeeper.global_position = Vector2(400, 300)  # Common room
	
	var innkeeper_data = GameManager.get_enemy_data("Innkeeper")
	innkeeper.unit_name = innkeeper_data.get("name", "Innkeeper")
	innkeeper.max_hp = innkeeper_data.get("hp", 8)
	innkeeper.hp = innkeeper_data.get("hp", 8)
	innkeeper.attack_stat = innkeeper_data.get("attack", 10)
	innkeeper.ac = innkeeper_data.get("ac", 10)
	innkeeper.is_enemy = false
	innkeeper.is_ai = true
	innkeeper.ai_type = "civilian"
	innkeeper.unit_selected.connect(_on_unit_selected)

func spawn_companions():
	if companions_joined:
		return
	companions_joined = true
	
	# Healer companion
	var healer_data = GameManager.create_companion("Healer")
	var healer = unit_scene.instantiate()
	add_child(healer)
	healer.global_position = Vector2(380, 340)
	healer.apply_data(healer_data)
	healer.unit_selected.connect(_on_unit_selected)
	party.append(healer)
	
	# Rogue companion
	var rogue_data = GameManager.create_companion("Rogue")
	var rogue = unit_scene.instantiate()
	add_child(rogue)
	rogue.global_position = Vector2(420, 340)
	rogue.apply_data(rogue_data)
	rogue.unit_selected.connect(_on_unit_selected)
	party.append(rogue)
	
	hud.add_combat_log_entry("A Healer and Rogue join your party!")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		
		match phase:
			Phase.EXPLORATION:
				_handle_exploration_click(click_pos)
			Phase.PLAYER_TURN:
				_handle_combat_click(click_pos)

func _handle_exploration_click(pos: Vector2):
	# Move player to clicked position
	if player_unit and player_unit.is_alive():
		player_unit.move_target = pos
		player_unit.is_moving = true
		camera.global_position = pos
		
		# Check if entering common room area (trigger encounter)
		if pos.x > 350 and pos.x < 500 and pos.y > 250 and pos.y < 400:
			if not companions_joined:
				spawn_companions()
				# Short delay then start combat
				await get_tree().create_timer(1.5).timeout
				start_combat()

func _handle_combat_click(pos: Vector2):
	if pending_action == "":
		return
	
	# Check if clicked on an enemy unit
	var target = _get_unit_at_position(pos)
	
	if target and target.is_enemy and target.is_alive():
		execute_player_action(target)
	elif pending_action == "" or pending_action == "move":
		# Move player
		var current_unit = turn_queue[current_turn_index]
		if current_unit == player_unit and not current_unit.has_moved:
			current_unit.move_to(pos)

func start_combat():
	phase = Phase.COMBAT_SETUP
	hud.set_combat_mode(true)
	hud.clear_combat_log()
	hud.add_combat_log_entry("=== COMBAT BEGINS ===")
	hud.add_combat_log_entry("Goblins burst through the inn door!")
	
	# Start wave 1
	wave_manager.start_encounter(innkeeper)

func _on_wave_started(wave_num: int):
	hud.add_combat_log_entry("")
	hud.add_combat_log_entry("--- Wave %d ---" % wave_num)
	
	match wave_num:
		1: hud.add_combat_log_entry("Goblin scouts appear!")
		2: hud.add_combat_log_entry("A horde of goblins charges in!")
		3: hud.add_combat_log_entry("The Goblin Chief arrives!")
	
	# Build turn order
	_build_turn_order()
	turn_number = 0
	_start_next_turn()

func _build_turn_order():
	turn_queue.clear()
	
	# Add party
	for unit in party:
		if unit.is_alive():
			turn_queue.append(unit)
	
	# Add innkeeper
	if innkeeper.is_alive():
		turn_queue.append(innkeeper)
	
	# Add enemies
	for enemy in wave_manager.get_all_enemies():
		if enemy.is_alive():
			turn_queue.append(enemy)
	
	# Roll initiative (d20 + bonus)
	var init_rolls = []
	for unit in turn_queue:
		var bonus = 0
		match unit.unit_class:
			"Rogue": bonus = 3
			"Ranger": bonus = 2
			"Wizard": bonus = 1
		var roll = randi_range(1, 20) + bonus
		init_rolls.append({"unit": unit, "roll": roll})
		hud.add_combat_log_entry("%s rolls %d initiative" % [unit.unit_name, roll])
	
	init_rolls.sort_custom(func(a, b): return a["roll"] > b["roll"])
	turn_queue.clear()
	for item in init_rolls:
		turn_queue.append(item["unit"])
	
	current_turn_index = 0
	hud.update_initiative_display(turn_queue, current_turn_index)

func _start_next_turn():
	# Check fail conditions
	var fail = wave_manager.check_fail_conditions(party)
	if fail != "":
		_end_game(false, fail)
		return
	
	# Skip dead units
	while current_turn_index < turn_queue.size() and not turn_queue[current_turn_index].is_alive():
		current_turn_index += 1
	
	if current_turn_index >= turn_queue.size():
		# Full round complete
		current_turn_index = 0
		turn_number += 1
		
		# Process status effect ticks
		for unit in turn_queue:
			if unit.is_alive():
				_tick_status_effects(unit)
		
		# Check if all enemies dead (wave cleared handled by WaveManager)
		_start_next_turn()
		return
	
	var current_unit = turn_queue[current_turn_index]
	current_unit.reset_turn()
	
	hud.update_turn_info(current_unit.unit_name, turn_number)
	hud.update_initiative_display(turn_queue, current_turn_index)
	
	if not current_unit.can_act():
		hud.add_combat_log_entry(current_unit.unit_name + " is incapacitated!")
		await get_tree().create_timer(0.5).timeout
		_end_current_turn()
		return
	
	if current_unit == player_unit:
		phase = Phase.PLAYER_TURN
		hud.set_abilities_enabled(true)
		hud.add_combat_log_entry(">> Your turn! <<")
	else:
		phase = Phase.AI_TURN
		hud.set_abilities_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_execute_ai_turn(current_unit)

func _execute_ai_turn(unit: Unit):
	if unit.ai_type == "civilian":
		# Innkeeper cowers
		hud.add_combat_log_entry(unit.unit_name + " cowers in fear!")
		await get_tree().create_timer(0.5).timeout
		_end_current_turn()
		return
	
	var allies: Array = []
	var enemies: Array = []
	
	if unit.is_enemy:
		allies = wave_manager.get_all_enemies().filter(func(u): return u.is_alive() and u != unit)
		enemies = party.filter(func(u): return u.is_alive())
		# Include innkeeper as target
		if innkeeper.is_alive():
			enemies.append(innkeeper)
	else:
		allies = party.filter(func(u): return u.is_alive() and u != unit)
		enemies = wave_manager.get_all_enemies().filter(func(u): return u.is_alive())
	
	var action = CompanionAI.take_turn(unit, allies, enemies, null)
	
	match action["type"]:
		"attack":
			if action.get("target"):
				_do_attack(unit, action["target"])
		"ability":
			if action.get("target") and action.get("ability"):
				_do_ability(unit, action["ability"], action["target"])
		_:
			hud.add_combat_log_entry(unit.unit_name + " does nothing.")
	
	await get_tree().create_timer(0.8).timeout
	_end_current_turn()

func _do_attack(attacker: Unit, target: Unit):
	var roll = randi_range(1, 20)
	var total = roll + max(0, attacker.attack_stat - 10)
	var is_crit = roll == 20
	var is_fumble = roll == 1
	
	if is_fumble:
		hud.add_combat_log_entry("%s fumbles! (rolled 1)" % attacker.unit_name)
		return
	
	if total >= target.ac or is_crit:
		var damage = randi_range(1, 6) + max(0, attacker.attack_stat - 10)
		if is_crit:
			damage *= 2
			hud.add_combat_log_entry("CRITICAL HIT!")
		
		hud.add_combat_log_entry("%s hits %s for %d damage! (d20=%d, total=%d vs AC %d)" % [
			attacker.unit_name, target.unit_name, damage, roll, total, target.ac
		])
		var died = await target.take_damage(damage)
		if died:
			hud.add_combat_log_entry("%s is defeated!" % target.unit_name)
	else:
		hud.add_combat_log_entry("%s misses %s! (d20=%d, total=%d vs AC %d)" % [
			attacker.unit_name, target.unit_name, roll, total, target.ac
		])

func _do_ability(user: Unit, ability_name: String, target: Unit):
	var ability = GameManager.get_ability_data(ability_name)
	if ability.is_empty():
		_do_attack(user, target)
		return
	
	hud.add_combat_log_entry("%s uses %s!" % [user.unit_name, ability_name])
	
	match ability["type"]:
		"damage":
			var damage = randi_range(ability["min_value"], ability["max_value"])
			hud.add_combat_log_entry("%s takes %d damage!" % [target.unit_name, damage])
			var died = await target.take_damage(damage)
			if died:
				hud.add_combat_log_entry("%s is defeated!" % target.unit_name)
		"heal":
			var amount = randi_range(ability["min_value"], ability["max_value"])
			target.heal(amount)
			hud.add_combat_log_entry("%s heals %d HP!" % [target.unit_name, amount])
		"status":
			var status = ability.get("status", "")
			var duration = ability.get("duration", 1)
			target.status_effects[status] = duration
			hud.add_combat_log_entry("%s is affected by %s for %d turns!" % [target.unit_name, status, duration])
		"buff":
			hud.add_combat_log_entry("%s is empowered!" % target.unit_name)
			target.ac += ability.get("bonus", 1)

func _tick_status_effects(unit: Unit):
	var to_remove = []
	for effect in unit.status_effects:
		unit.status_effects[effect] -= 1
		if unit.status_effects[effect] <= 0:
			to_remove.append(effect)
			hud.add_combat_log_entry("%s recovers from %s!" % [unit.unit_name, effect])
	for effect in to_remove:
		unit.status_effects.erase(effect)

func _end_current_turn():
	current_turn_index += 1
	_start_next_turn()

func execute_player_action(target: Unit):
	if phase != Phase.PLAYER_TURN:
		return
	
	hud.set_abilities_enabled(false)
	
	match pending_action:
		"attack":
			await _do_attack(player_unit, target)
		"ability_0":
			if player_unit.abilities.size() > 0:
				await _do_ability(player_unit, player_unit.abilities[0], target)
		"ability_1":
			if player_unit.abilities.size() > 1:
				await _do_ability(player_unit, player_unit.abilities[1], target)
		"ability_2":
			if player_unit.abilities.size() > 2:
				await _do_ability(player_unit, player_unit.abilities[2], target)
	
	pending_action = ""
	player_unit.has_acted = true
	_end_current_turn()

func _on_attack_pressed():
	if phase == Phase.PLAYER_TURN:
		pending_action = "attack"
		hud.add_combat_log_entry("Select a target to attack...")

func _on_ability_pressed(index: int):
	if phase == Phase.PLAYER_TURN:
		pending_action = "ability_%d" % index
		var ability_name = player_unit.abilities[index] if index < player_unit.abilities.size() else "Unknown"
		hud.add_combat_log_entry("Select a target for %s..." % ability_name)

func _on_end_turn_pressed():
	if phase == Phase.PLAYER_TURN:
		hud.add_combat_log_entry("You end your turn.")
		pending_action = ""
		_end_current_turn()

func _on_pause_pressed():
	hud.show_pause_menu()

func _on_wave_cleared(wave_num: int):
	hud.add_combat_log_entry("Wave %d cleared!" % wave_num)
	phase = Phase.WAVE_TRANSITION

func _on_all_waves_cleared():
	hud.add_combat_log_entry("=== ALL WAVES DEFEATED ===")
	_end_game(true, "")

func _end_game(victory: bool, reason: String):
	phase = Phase.ENDED
	hud.set_combat_mode(false)
	
	# Show end screen as overlay
	var end_scene = preload("res://scenes/EndScreen.tscn").instantiate()
	add_child(end_scene)
	end_scene.setup(victory, reason)

func _get_unit_at_position(pos: Vector2) -> Unit:
	var closest: Unit = null
	var closest_dist: float = 30.0  # Click tolerance
	
	# Check enemies
	for enemy in wave_manager.get_all_enemies():
		if enemy.is_alive():
			var dist = pos.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest

func _on_unit_selected(unit: Unit):
	if selected_unit:
		selected_unit.deselect()
	
	selected_unit = unit
	unit.select()
	hud.update_unit_info(unit.unit_name, unit.hp, unit.max_hp, unit.unit_class)
