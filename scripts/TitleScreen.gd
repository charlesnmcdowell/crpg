extends Control

@onready var new_game_button: Button = $Center/NewGameButton

func _ready() -> void:
	new_game_button.pressed.connect(GameManager.start_new_game)
