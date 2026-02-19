extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var continue_btn: Button = $VBoxContainer/ContinueBtn
@onready var menu_btn: Button = $VBoxContainer/MenuBtn

var is_victory: bool = false

func _ready():
	continue_btn.pressed.connect(_on_continue)
	menu_btn.pressed.connect(_on_menu)

func setup(victory: bool, reason: String = ""):
	is_victory = victory
	
	if victory:
		title_label.text = "VICTORY!"
		message_label.text = "All enemies defeated! The innkeeper is safe.\n\nContinue Outside (Not Implemented)"
		continue_btn.text = "Continue Outside"
		continue_btn.disabled = true
		$Background.color = Color(0.1, 0.2, 0.1, 0.9)
	else:
		title_label.text = "DEFEAT"
		if reason == "innkeeper_died":
			message_label.text = "The innkeeper has fallen!\nYou failed to protect them."
		else:
			message_label.text = "Your party has been wiped out.\nThe goblins have won."
		continue_btn.visible = false
		$Background.color = Color(0.3, 0.1, 0.1, 0.9)

func _on_continue():
	pass # Not implemented

func _on_menu():
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
