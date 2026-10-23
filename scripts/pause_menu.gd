extends Control

@onready var resume_button: Button = $CenterContainer/MenuContainer/ResumeButton
@onready var settings_button: Button = $CenterContainer/MenuContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/MenuContainer/QuitButton

func _ready() -> void:
	#hide menu
	visible = false
	
	#Buttons 
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# Pressing Esc for menu
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var new_paused_state = not get_tree().paused
	get_tree().paused = new_paused_state
	visible = new_paused_state
	
	if new_paused_state:
		resume_button.grab_focus()

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_settings_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	
	var error = get_tree().change_scene_to_file("res://main_menu.tscn")
	
	#if error != OK:
		#print("Error: Could not load main menu scene")
