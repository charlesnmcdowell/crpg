extends Node
class_name CompanionAI

# Healer AI: heal ally <50% → buff → attack
# Rogue AI: flank/backstab if safe → focus low HP → ranged if unsafe

static func take_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	var action = {"type": "none"}
	
	match unit.ai_type:
		"healer":
			action = healer_turn(unit, allies, enemies, combat_mgr)
		"rogue":
			action = rogue_turn(unit, allies, enemies, combat_mgr)
		"melee":
			action = melee_enemy_turn(unit, allies, enemies, combat_mgr)
		"ranged":
			action = ranged_enemy_turn(unit, allies, enemies, combat_mgr)
		"leader":
			action = leader_enemy_turn(unit, allies, enemies, combat_mgr)
		_:
			action = basic_turn(unit, enemies, combat_mgr)
	
	return action

static func healer_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	# Priority 1: Heal ally under 50% HP
	var injured_allies = []
	for ally in allies:
		if ally.is_alive() and ally != unit:
			var hp_pct = float(ally.hp) / float(ally.max_hp)
			if hp_pct < 0.5:
				injured_allies.append(ally)
	
	if injured_allies.size() > 0:
		# Heal most injured
		injured_allies.sort_custom(func(a, b): return float(a.hp) / a.max_hp < float(b.hp) / b.max_hp)
		var target = injured_allies[0]
		if "Heal" in unit.abilities:
			return {"type": "ability", "ability": "Heal", "target": target}
	
	# Priority 2: Buff allies
	if "Bless" in unit.abilities:
		for ally in allies:
			if ally.is_alive() and ally != unit and not ally.has_status("Blessed"):
				return {"type": "ability", "ability": "Bless", "target": ally}
	
	# Priority 3: Cure status effects
	if "Cure Disease" in unit.abilities:
		for ally in allies:
			if ally.is_alive() and ally.status_effects.size() > 0:
				return {"type": "ability", "ability": "Cure Disease", "target": ally}
	
	# Priority 4: Attack
	if enemies.size() > 0:
		var target = _get_closest_enemy(unit, enemies)
		return {"type": "attack", "target": target}
	
	return {"type": "none"}

static func rogue_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	if enemies.size() == 0:
		return {"type": "none"}
	
	# Sort enemies by HP (focus low HP targets)
	var live_enemies = enemies.filter(func(e): return e.is_alive())
	if live_enemies.size() == 0:
		return {"type": "none"}
	
	live_enemies.sort_custom(func(a, b): return a.hp < b.hp)
	var weakest = live_enemies[0]
	
	# Check if safe to melee (no more than 1 enemy adjacent)
	var nearby_enemies = 0
	for enemy in live_enemies:
		if unit.global_position.distance_to(enemy.global_position) < 80:
			nearby_enemies += 1
	
	var is_safe = nearby_enemies <= 1
	
	# Priority 1: Backstab if safe and available
	if is_safe and "Backstab" in unit.abilities:
		return {"type": "ability", "ability": "Backstab", "target": weakest}
	
	# Priority 2: Sneak Attack if safe
	if is_safe and "Sneak Attack" in unit.abilities:
		return {"type": "ability", "ability": "Sneak Attack", "target": weakest}
	
	# Priority 3: Poison Blade on leader/high HP enemy
	if "Poison Blade" in unit.abilities:
		for enemy in live_enemies:
			if enemy.ai_type == "leader" and not enemy.has_status("Poison"):
				return {"type": "ability", "ability": "Poison Blade", "target": enemy}
	
	# Priority 4: Basic attack on weakest (ranged if unsafe)
	return {"type": "attack", "target": weakest}

static func melee_enemy_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	if enemies.size() == 0:
		return {"type": "none"}
	
	# Attack closest enemy (which is actually a player/ally from enemy perspective)
	var target = _get_closest_enemy(unit, enemies)
	
	if "Savage Strike" in unit.abilities and randf() > 0.5:
		return {"type": "ability", "ability": "Savage Strike", "target": target}
	
	return {"type": "attack", "target": target}

static func ranged_enemy_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	if enemies.size() == 0:
		return {"type": "none"}
	
	# Prefer ranged attack on lowest HP target
	var live_enemies = enemies.filter(func(e): return e.is_alive())
	if live_enemies.size() == 0:
		return {"type": "none"}
	
	live_enemies.sort_custom(func(a, b): return a.hp < b.hp)
	var target = live_enemies[0]
	
	if "Aimed Shot" in unit.abilities:
		return {"type": "ability", "ability": "Aimed Shot", "target": target}
	
	return {"type": "attack", "target": target}

static func leader_enemy_turn(unit: Unit, allies: Array, enemies: Array, combat_mgr) -> Dictionary:
	if enemies.size() == 0:
		return {"type": "none"}
	
	# Priority 1: War Cry to slow enemies
	if "War Cry" in unit.abilities and randf() > 0.6:
		var target = enemies[randi() % enemies.size()]
		return {"type": "ability", "ability": "War Cry", "target": target}
	
	# Priority 2: Command to buff allies
	if "Command" in unit.abilities and allies.size() > 1 and randf() > 0.5:
		var target = allies[randi() % allies.size()]
		return {"type": "ability", "ability": "Command", "target": target}
	
	# Priority 3: Crushing Blow on strongest enemy
	if "Crushing Blow" in unit.abilities:
		var live_enemies = enemies.filter(func(e): return e.is_alive())
		if live_enemies.size() > 0:
			live_enemies.sort_custom(func(a, b): return a.hp > b.hp)
			return {"type": "ability", "ability": "Crushing Blow", "target": live_enemies[0]}
	
	# Fallback: basic attack
	var target = _get_closest_enemy(unit, enemies)
	return {"type": "attack", "target": target}

static func basic_turn(unit: Unit, enemies: Array, combat_mgr) -> Dictionary:
	if enemies.size() == 0:
		return {"type": "none"}
	var target = _get_closest_enemy(unit, enemies)
	return {"type": "attack", "target": target}

static func _get_closest_enemy(unit: Unit, enemies: Array) -> Unit:
	var closest: Unit = null
	var closest_dist: float = INF
	
	for enemy in enemies:
		if enemy.is_alive():
			var dist = unit.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest
