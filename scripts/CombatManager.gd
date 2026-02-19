extends Node

signal turn_started(unit)
signal turn_ended(unit)
signal combat_ended(victory: bool)
signal damage_dealt(attacker, target, damage)
signal ability_used(user, ability_name, targets)

enum CombatState {
	SETUP,
	PLAYER_TURN,
	AI_TURN,
	ENDED
}

var combat_state: CombatState = CombatState.SETUP
var turn_queue = []
var current_turn_index = 0
var combat_units = []
var current_wave = 1
var max_waves = 3
var combat_log = []

func start_combat(allies: Array, enemies: Array):
	combat_state = CombatState.SETUP
	combat_units.clear()
	turn_queue.clear()
	current_turn_index = 0
	current_wave = 1
	combat_log.clear()
	
	# Add all units to combat
	for ally in allies:
		combat_units.append(ally)
	for enemy in enemies:
		combat_units.append(enemy)
	
	# Roll initiative and create turn order
	roll_initiative()
	
	add_to_log("Combat begins!")
	combat_state = CombatState.PLAYER_TURN
	start_next_turn()

func roll_initiative():
	var initiative_list = []
	
	for unit in combat_units:
		var initiative = randi_range(1, 20) + get_initiative_bonus(unit)
		initiative_list.append({"unit": unit, "initiative": initiative})
	
	# Sort by initiative (highest first)
	initiative_list.sort_custom(func(a, b): return a["initiative"] > b["initiative"])
	
	# Create turn queue
	turn_queue.clear()
	for item in initiative_list:
		turn_queue.append(item["unit"])
	
	add_to_log("Initiative order determined!")

func get_initiative_bonus(unit) -> int:
	# Simple initiative bonus based on class
	match unit.get("class", ""):
		"Rogue":
			return 3
		"Ranger":
			return 2
		"Wizard":
			return 1
		_:
			return 0

func start_next_turn():
	if current_turn_index >= turn_queue.size():
		current_turn_index = 0
		# Check for combat end conditions
		if is_combat_over():
			end_combat()
			return
	
	var current_unit = turn_queue[current_turn_index]
	
	# Skip defeated units
	if current_unit["hp"] <= 0:
		current_turn_index += 1
		start_next_turn()
		return
	
	# Process status effects
	process_status_effects(current_unit)
	
	# Check if unit can act (not stunned/sleeping)
	if can_unit_act(current_unit):
		if current_unit.get("is_ai", false):
			combat_state = CombatState.AI_TURN
			ai_take_turn(current_unit)
		else:
			combat_state = CombatState.PLAYER_TURN
			turn_started.emit(current_unit)
	else:
		add_to_log(current_unit["name"] + " is incapacitated and loses their turn!")
		end_turn()

func end_turn():
	var current_unit = turn_queue[current_turn_index]
	turn_ended.emit(current_unit)
	current_turn_index += 1
	start_next_turn()

func attack_roll(attacker, target) -> Dictionary:
	var roll = randi_range(1, 20)
	var attack_bonus = attacker.get("attack", 0)
	var total = roll + attack_bonus
	var target_ac = target.get("ac", 10)
	var hit = total >= target_ac
	
	var result = {
		"roll": roll,
		"total": total,
		"hit": hit,
		"critical": roll == 20,
		"fumble": roll == 1
	}
	
	if hit:
		var damage = calculate_damage(attacker, result["critical"])
		result["damage"] = damage
		deal_damage(target, damage)
		add_to_log(attacker["name"] + " attacks " + target["name"] + " for " + str(damage) + " damage!")
		damage_dealt.emit(attacker, target, damage)
	else:
		add_to_log(attacker["name"] + " misses " + target["name"] + "!")
	
	return result

func calculate_damage(attacker, is_critical: bool = false) -> int:
	var base_damage = attacker.get("attack", 1)
	var damage = randi_range(1, 6) + max(0, base_damage - 10) # Simple damage formula
	
	if is_critical:
		damage *= 2
		add_to_log("Critical hit!")
	
	return damage

func deal_damage(target, damage: int):
	target["hp"] = max(0, target["hp"] - damage)
	if target["hp"] == 0:
		add_to_log(target["name"] + " is defeated!")

func use_ability(user, ability_name: String, targets: Array = []):
	var ability = GameManager.get_ability_data(ability_name)
	if ability.is_empty():
		return false
	
	add_to_log(user["name"] + " uses " + ability["name"] + "!")
	
	match ability["type"]:
		"heal":
			for target in targets:
				var heal_amount = randi_range(ability["min_value"], ability["max_value"])
				target["hp"] = min(target["max_hp"], target["hp"] + heal_amount)
				add_to_log(target["name"] + " heals for " + str(heal_amount) + " HP!")
		
		"damage":
			for target in targets:
				var damage = randi_range(ability["min_value"], ability["max_value"])
				deal_damage(target, damage)
				add_to_log(target["name"] + " takes " + str(damage) + " damage!")
		
		"status":
			for target in targets:
				apply_status_effect(target, ability["status"], ability["duration"])
	
	ability_used.emit(user, ability_name, targets)
	return true

func apply_status_effect(unit, effect: String, duration: int):
	unit["status_effects"][effect] = duration
	add_to_log(unit["name"] + " is affected by " + effect + "!")

func process_status_effects(unit):
	var effects_to_remove = []
	
	for effect in unit["status_effects"]:
		var duration = unit["status_effects"][effect]
		duration -= 1
		
		if duration <= 0:
			effects_to_remove.append(effect)
			add_to_log(unit["name"] + " recovers from " + effect + "!")
		else:
			unit["status_effects"][effect] = duration

	for effect in effects_to_remove:
		unit["status_effects"].erase(effect)

func can_unit_act(unit) -> bool:
	return not ("Stun" in unit["status_effects"] or "Sleep" in unit["status_effects"])

func ai_take_turn(unit):
	var ai_type = unit.get("ai_type", "basic")
	
	match ai_type:
		"healer":
			ai_healer_turn(unit)
		"rogue":
			ai_rogue_turn(unit)
		_:
			ai_basic_turn(unit)
	
	# End turn after a short delay
	await get_tree().create_timer(1.0).timeout
	end_turn()

func ai_healer_turn(unit):
	# Check for allies under 50% health
	var allies = get_allies(unit)
	var low_health_allies = []
	
	for ally in allies:
		if ally["hp"] < ally["max_hp"] * 0.5:
			low_health_allies.append(ally)
	
	if low_health_allies.size() > 0:
		# Heal the most injured ally
		low_health_allies.sort_custom(func(a, b): return (a["hp"] / float(a["max_hp"])) < (b["hp"] / float(b["max_hp"])))
		use_ability(unit, "Heal", [low_health_allies[0]])
		return
	
	# Otherwise attack an enemy
	var enemies = get_enemies(unit)
	if enemies.size() > 0:
		attack_roll(unit, enemies[0])

func ai_rogue_turn(unit):
	var enemies = get_enemies(unit)
	if enemies.size() == 0:
		return
	
	# Focus on lowest HP enemy
	enemies.sort_custom(func(a, b): return a["hp"] < b["hp"])
	attack_roll(unit, enemies[0])

func ai_basic_turn(unit):
	var enemies = get_enemies(unit)
	if enemies.size() > 0:
		attack_roll(unit, enemies[0])

func get_allies(unit) -> Array:
	var allies = []
	var is_player_side = not unit.get("is_enemy", false)
	
	for other_unit in combat_units:
		if other_unit != unit and other_unit.get("is_enemy", false) != is_player_side and other_unit["hp"] > 0:
			allies.append(other_unit)
	
	return allies

func get_enemies(unit) -> Array:
	var enemies = []
	var is_player_side = not unit.get("is_enemy", false)
	
	for other_unit in combat_units:
		if other_unit.get("is_enemy", false) == is_player_side and other_unit["hp"] > 0:
			enemies.append(other_unit)
	
	return enemies

func is_combat_over() -> bool:
	var allies_alive = false
	var enemies_alive = false
	
	for unit in combat_units:
		if unit["hp"] > 0:
			if unit.get("is_enemy", false):
				enemies_alive = true
			else:
				allies_alive = true
	
	return not allies_alive or not enemies_alive

func end_combat():
	combat_state = CombatState.ENDED
	var victory = true
	
	# Check if allies won
	for unit in combat_units:
		if unit.get("is_enemy", false) and unit["hp"] > 0:
			victory = false
			break
	
	add_to_log("Combat ends!")
	combat_ended.emit(victory)

func add_to_log(message: String):
	combat_log.append(message)
	print("[COMBAT] " + message)

func get_combat_log() -> Array:
	return combat_log