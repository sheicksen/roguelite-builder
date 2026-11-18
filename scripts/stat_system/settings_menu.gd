extends Control

var remapping_action: String = ""
var active_button: Button = null
var opened_from_pause: bool = false

@onready var action_list_container: VBoxContainer = $CenterContainer/VBoxContainer/ScrollContainer/ActionListContainer
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ButtonRow/ResetButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/ButtonRow/BackButton

# The input actions 
var rebindable_actions = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump / Up",
	"slide": "Slide / Down",
	"ability_1": "Ability 1",
	"ability_2": "Ability 2",
	"ability_3": "Ability 3"
}

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	create_rebind_buttons()

func create_rebind_buttons() -> void:
	# Clear existing rows
	for child in action_list_container.get_children():
		child.queue_free()
		
	for action in rebindable_actions:
		var hbox = HBoxContainer.new()
		hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
		
		# Action display 
		var label = Label.new()
		label.text = rebindable_actions[action]
		label.custom_minimum_size = Vector2(180, 40)
		hbox.add_child(label)
		
		# Rebind button showing current key
		var btn = Button.new()
		btn.name = action
		btn.custom_minimum_size = Vector2(160, 40)
		btn.text = get_action_key_name(action)
		btn.pressed.connect(_on_rebind_button_pressed.bind(action, btn))
		hbox.add_child(btn)
		
		action_list_container.add_child(hbox)

func get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		for event in events:
			if event is InputEventKey:
				return OS.get_keycode_string(event.physical_keycode)
	return "Unassigned"

func _on_rebind_button_pressed(action: String, button: Button) -> void:
	remapping_action = action
	active_button = button
	button.text = "Press any key..."

func _unhandled_input(event: InputEvent) -> void:
	if remapping_action != "" and event is InputEventKey and event.pressed:
		# Prevent assigning Escape if you want to reserve it for menus, or allow it:
		if event.physical_keycode == KEY_ESCAPE:
			# Cancel remapping
			create_rebind_buttons()
			remapping_action = ""
			active_button = null
			return
			
		# Clear old events for this action from the InputMap
		InputMap.action_erase_events(remapping_action)
		# Add the new key event
		InputMap.action_add_event(remapping_action, event)
		
		# Refresh the buttons display
		create_rebind_buttons()
		
		# Reset tracking variables
		remapping_action = ""
		active_button = null
		get_viewport().set_input_as_handled()

func _on_reset_button_pressed() -> void:
	# Built-in Godot method that reloads default key bindings from project.godot
	InputMap.load_from_project_settings()
	create_rebind_buttons()

func _on_back_button_pressed() -> void:
	if opened_from_pause:
		# If opened from the pause menu overlay, just remove this settings node
		queue_free()
	else:
		# If opened from the main menu scene, switch back to main menu
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
