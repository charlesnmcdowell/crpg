extends CharacterBody2D
class_name Unit

signal unit_selected(unit: Unit)
signal unit_moved(unit: Unit)
signal unit_died(unit: Unit)

@export var unit_name: String = "Unit"
@export var unit_class: String = ""
@export var max_hp: int = 20
@export var hp: int = 20
@export var attack_stat: int = 12
@export var ac: int = 12
@export var move_speed: float = 200.0
@export var move_range: float = 150.0
@export var is_enemy: bool = false
@export var is_ai: bool = false
@export var ai_type: String = "basic"

var abilities: Array = []
var ability_cooldowns: Dictionary = {}
var status_effects: Dictionary = {}
var is_selected: bool = false
var has_moved: bool = false
var has_acted: bool = false
var move_target: Vector2 = Vector2.ZERO
var is_moving: bool = false
var start_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var selection_indicator: Sprite2D = $SelectionIndicator
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	health_bar.max_value = max_hp
	health_bar.value = hp
	name_label.text = unit_name
	selection_indicator.visible = false
	start_position = global_position
	
	# Color based on team
	if is_enemy:
		sprite.modulate = Color(0.9, 0.3, 0.3)
	elif is_ai:
		sprite.modulate = Color(0.3, 0.7, 0.9)
	else:
		sprite.modulate = Color(0.3, 0.9, 0.3)

func _process(delta):
	if is_moving:
		var direction = (move_target - global_position).normalized()
		var distance = global_position.distance_to(move_target)
		
		if distance < 5.0:
			global_position = move_target
			is_moving = false
			has_moved = true
			unit_moved.emit(self)
		else:
			velocity = direction * move_speed
			move_and_slide()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		unit_selected.emit(self)

func select():
	is_selected = true
	selection_indicator.visible = true

func deselect():
	is_selected = false
	selection_indicator.visible = false

func move_to(target_pos: Vector2):
	var dist = global_position.distance_to(target_pos)
	if dist <= move_range and not has_moved:
		move_target = target_pos
		is_moving = true

func take_damage(amount: int) -> bool:
	hp = max(0, hp - amount)
	health_bar.value = hp
	
	# Flash red
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.15).timeout
	_reset_color()
	
	if hp <= 0:
		die()
		return true
	return false

func heal(amount: int):
	hp = min(max_hp, hp + amount)
	health_bar.value = hp
	
	# Flash green
	sprite.modulate = Color(0, 1, 0)
	await get_tree().create_timer(0.15).timeout
	_reset_color()

func _reset_color():
	if is_enemy:
		sprite.modulate = Color(0.9, 0.3, 0.3)
	elif is_ai:
		sprite.modulate = Color(0.3, 0.7, 0.9)
	else:
		sprite.modulate = Color(0.3, 0.9, 0.3)

func die():
	unit_died.emit(self)
	sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	collision_shape.set_deferred("disabled", true)
	health_bar.visible = false

func reset_turn():
	has_moved = false
	has_acted = false
	start_position = global_position

func get_data() -> Dictionary:
	return {
		"name": unit_name,
		"class": unit_class,
		"hp": hp,
		"max_hp": max_hp,
		"attack": attack_stat,
		"ac": ac,
		"abilities": abilities,
		"status_effects": status_effects,
		"is_enemy": is_enemy,
		"is_ai": is_ai,
		"ai_type": ai_type
	}

func apply_data(data: Dictionary):
	unit_name = data.get("name", "Unit")
	unit_class = data.get("class", "")
	max_hp = data.get("max_hp", data.get("hp", 20))
	hp = data.get("hp", 20)
	attack_stat = data.get("attack", 12)
	ac = data.get("ac", 12)
	abilities = data.get("abilities", [])
	status_effects = data.get("status_effects", {})
	is_enemy = data.get("is_enemy", false)
	is_ai = data.get("is_ai", false)
	ai_type = data.get("ai_type", "basic")
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if name_label:
		name_label.text = unit_name

func is_alive() -> bool:
	return hp > 0

func has_status(effect: String) -> bool:
	return effect in status_effects

func can_act() -> bool:
	return not (has_status("Stun") or has_status("Sleep"))
