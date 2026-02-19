extends Control

@onready var back_button = $VBoxContainer/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	apply_ui_scaling()
	
	# Connect settings changed signal
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_back_pressed():
	GameManager.change_scene("res://scenes/TitleScreen.tscn")

func _on_settings_changed():
	apply_ui_scaling()

func apply_ui_scaling():
	var scale_value = SettingsManager.get_ui_scale_value()
	scale = Vector2(scale_value, scale_value)