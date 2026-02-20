extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	# Center camera on player for this minimal demo
	if camera and player:
		camera.global_position = player.global_position
