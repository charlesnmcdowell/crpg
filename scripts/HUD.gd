extends CanvasLayer

signal attack_pressed
signal ability_pressed(index: int)
signal end_turn_pressed
signal inventory_pressed
signal pause_pressed

@onready var attack_btn: Button = $HUDContainer/ActionBar/AttackBtn
@onready var ability1_btn: Button = $HUDContainer/ActionBar/Ability1Btn
@onready var ability2_btn: Button = $HUDContainer/ActionBar/Ability2Btn
@onready var ability3_btn: Button = $HUDContainer/ActionBar/Ability3Btn
@onready var end_turn_btn: Button = $HUDContainer/ActionBar/EndTurnBtn
@onready var inventory_btn: Button = $HUDContainer/TopBar/InventoryBtn
@onready var pause_btn: Button = $HUDContainer/TopBar/PauseBtn
@onready var combat_log: RichTextLabel = $HUDContainer/CombatLogPanel/CombatLog
@onready var unit_info_label: Label = $HUDContainer/TopBar/UnitInfoLabel
@onready var turn_label: Label = $HUDContainer/TopBar/TurnLabel
@onready var initiative_list: VBoxContainer = $HUDContainer/InitiativePanel/InitiativeList
@onready var action_bar: HBoxContainer = $HUDContainer/ActionBar
@onready var combat_log_panel: PanelContainer = $HUDContainer/CombatLogPanel
@onready var initiative_panel: PanelContainer = $HUDContainer/InitiativePanel
@onready var pause_menu: Control = $PauseMenu

var is_combat_mode: bool = false

func _ready():
	attack_btn.pressed.connect(_on_attack_pressed)
	ability1_btn.pressed.connect(func(): _on_ability_pressed(0))
	ability2_btn.pressed.connect(func(): _on_ability_pressed(1))
	ability3_btn.pressed.connect(func(): _on_ability_pressed(2))
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	
	set_combat_mode(false)
	pause_menu.visible = false

func set_combat_mode(enabled: bool):
	is_combat_mode = enabled
	action_bar.visible = enabled
	combat_log_panel.visible = enabled
	initiative_panel.visible = enabled
	
	if not enabled:
		turn_label.text = "Exploration"

func update_unit_info(unit_name: String, hp: int, max_hp: int, unit_class: String):
	unit_info_label.text = "%s (%s) HP: %d/%d" % [unit_name, unit_class, hp, max_hp]

func update_turn_info(unit_name: String, turn_number: int):
	turn_label.text = "Turn %d - %s's Turn" % [turn_number, unit_name]

func set_ability_names(names: Array):
	var buttons = [ability1_btn, ability2_btn, ability3_btn]
	for i in range(3):
		if i < names.size():
			buttons[i].text = names[i]
			buttons[i].visible = true
		else:
			buttons[i].visible = false

func set_abilities_enabled(enabled: bool):
	attack_btn.disabled = not enabled
	ability1_btn.disabled = not enabled
	ability2_btn.disabled = not enabled
	ability3_btn.disabled = not enabled
	end_turn_btn.disabled = not enabled

func add_combat_log_entry(text: String):
	combat_log.append_text(text + "\n")
	# Auto-scroll to bottom
	combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func clear_combat_log():
	combat_log.clear()

func update_initiative_display(turn_order: Array, current_index: int):
	# Clear existing
	for child in initiative_list.get_children():
		child.queue_free()
	
	for i in range(turn_order.size()):
		var unit = turn_order[i]
		var label = Label.new()
		var prefix = "► " if i == current_index else "  "
		var hp_text = "%d/%d" % [unit.hp, unit.max_hp]
		label.text = prefix + unit.unit_name + " " + hp_text
		
		if unit.hp <= 0:
			label.modulate = Color(0.5, 0.5, 0.5)
		elif unit.is_enemy:
			label.modulate = Color(1, 0.4, 0.4)
		elif unit.is_ai:
			label.modulate = Color(0.4, 0.7, 1)
		else:
			label.modulate = Color(0.4, 1, 0.4)
		
		initiative_list.add_child(label)

func show_pause_menu():
	pause_menu.visible = true
	get_tree().paused = true

func hide_pause_menu():
	pause_menu.visible = false
	get_tree().paused = false

func _on_attack_pressed():
	attack_pressed.emit()

func _on_ability_pressed(index: int):
	ability_pressed.emit(index)

func _on_end_turn_pressed():
	end_turn_pressed.emit()

func _on_inventory_pressed():
	inventory_pressed.emit()

func _on_pause_pressed():
	if pause_menu.visible:
		hide_pause_menu()
	else:
		show_pause_menu()
