extends Control

@onready var name_line_edit = $VBoxContainer/NameContainer/NameLineEdit
@onready var warrior_button = $VBoxContainer/ClassContainer/WarriorButton
@onready var ranger_button = $VBoxContainer/ClassContainer/RangerButton
@onready var wizard_button = $VBoxContainer/ClassContainer/WizardButton
@onready var class_description = $VBoxContainer/ClassDescription
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var start_button = $VBoxContainer/ButtonContainer/StartButton

var selected_class = ""

func _ready():
	warrior_button.pressed.connect(func(): _on_class_selected("Warrior"))
	ranger_button.pressed.connect(func(): _on_class_selected("Ranger"))
	wizard_button.pressed.connect(func(): _on_class_selected("Wizard"))
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	apply_ui_scaling()
	
	# Connect settings changed signal
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_class_selected(class_name: String):
	selected_class = class_name
	start_button.disabled = false
	
	# Reset button styles
	warrior_button.modulate = Color.WHITE
	ranger_button.modulate = Color.WHITE
	wizard_button.modulate = Color.WHITE
	
	# Highlight selected button
	match class_name:
		"Warrior":
			warrior_button.modulate = Color.YELLOW
		"Ranger":
			ranger_button.modulate = Color.YELLOW
		"Wizard":
			wizard_button.modulate = Color.YELLOW
	
	# Update description
	var class_data = GameManager.get_character_class_data(class_name)
	if not class_data.is_empty():
		var abilities_text = ""
		for ability in class_data["abilities"]:
			abilities_text += "• " + ability + "\n"
		
		class_description.text = "[center][b]" + class_data["name"] + "[/b]\n\n" + \
			class_data["description"] + "\n\n[b]Abilities:[/b]\n" + abilities_text + "[/center]"

func _on_back_pressed():
	GameManager.change_scene("res://scenes/TitleScreen.tscn")

func _on_start_pressed():
	if selected_class != "":
		var player_name = name_line_edit.text.strip_edges()
		GameManager.create_player_character(selected_class, player_name)
		GameManager.start_new_game()

func _on_settings_changed():
	apply_ui_scaling()

func apply_ui_scaling():
	var scale_value = SettingsManager.get_ui_scale_value()
	scale = Vector2(scale_value, scale_value)