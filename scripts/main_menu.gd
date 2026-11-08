extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	# Loads Room_01
	get_tree().change_scene_to_file("res://Room_01.tscn")

func _on_settings_button_pressed() -> void:
	# Placeholder
	pass

func _on_quit_button_pressed() -> void:
	# Quits to desktop
	get_tree().quit()
