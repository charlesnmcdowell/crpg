extends Control

@onready var volume_slider = $VBoxContainer/OptionsContainer/VolumeContainer/VolumeSlider
@onready var music_checkbox = $VBoxContainer/OptionsContainer/MusicContainer/MusicCheckBox
@onready var sfx_checkbox = $VBoxContainer/OptionsContainer/SFXContainer/SFXCheckBox
@onready var ui_scale_option = $VBoxContainer/OptionsContainer/UIScaleContainer/UIScaleOption
@onready var back_button = $VBoxContainer/BackButton

func _ready():
	# Connect signals
	volume_slider.value_changed.connect(_on_volume_changed)
	music_checkbox.toggled.connect(_on_music_toggled)
	sfx_checkbox.toggled.connect(_on_sfx_toggled)
	ui_scale_option.item_selected.connect(_on_ui_scale_selected)
	back_button.pressed.connect(_on_back_pressed)
	
	# Load current settings
	load_current_settings()
	apply_ui_scaling()
	
	# Connect settings changed signal
	SettingsManager.settings_changed.connect(_on_settings_changed)

func load_current_settings():
	volume_slider.value = SettingsManager.get_setting("master_volume")
	music_checkbox.button_pressed = SettingsManager.get_setting("music_enabled")
	sfx_checkbox.button_pressed = SettingsManager.get_setting("sfx_enabled")
	
	var ui_scale = SettingsManager.get_setting("ui_scale")
	match ui_scale:
		"Small":
			ui_scale_option.selected = 0
		"Medium":
			ui_scale_option.selected = 1
		"Large":
			ui_scale_option.selected = 2

func _on_volume_changed(value: float):
	SettingsManager.set_master_volume(value)

func _on_music_toggled(pressed: bool):
	SettingsManager.set_music_enabled(pressed)

func _on_sfx_toggled(pressed: bool):
	SettingsManager.set_sfx_enabled(pressed)

func _on_ui_scale_selected(index: int):
	var scale_names = ["Small", "Medium", "Large"]
	if index < scale_names.size():
		SettingsManager.set_ui_scale(scale_names[index])

func _on_back_pressed():
	GameManager.change_scene("res://scenes/TitleScreen.tscn")

func _on_settings_changed():
	apply_ui_scaling()

func apply_ui_scaling():
	var scale_value = SettingsManager.get_ui_scale_value()
	scale = Vector2(scale_value, scale_value)