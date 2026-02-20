extends Control

@onready var new_game_button = $VBoxContainer/MenuButtons/NewGameButton
@onready var options_button = $VBoxContainer/MenuButtons/OptionsButton
@onready var credits_button = $VBoxContainer/MenuButtons/CreditsButton
@onready var quit_button = $VBoxContainer/MenuButtons/QuitButton

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Apply UI scaling
	apply_ui_scaling()
	
	# Connect settings changed signal
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_new_game_pressed():
	GameManager.change_scene("res://scenes/CharacterCreation.tscn")

func _on_options_pressed():
	GameManager.change_scene("res://scenes/OptionsScreen.tscn")

func _on_credits_pressed():
	GameManager.change_scene("res://scenes/CreditsScreen.tscn")

func _on_quit_pressed():
	get_tree().quit()

# Ensure script parses cleanly in editor when nodes are not yet ready
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if new_game_button == null:
		warnings.append("NewGameButton not found")
	return warnings

func _on_settings_changed():
	apply_ui_scaling()

func apply_ui_scaling():
	var scale_value = SettingsManager.get_ui_scale_value()
	scale = Vector2(scale_value, scale_value)