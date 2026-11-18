extends Control

var opened_from_pause: bool = false
var remapping_action: String = ""
var active_button: Button = null

@onready var action_list_container: VBoxContainer = $Control/CenterContainer/VBoxContainer/ScrollContainer/ActionListContainer
@onready var reset_button: Button = $Control/CenterContainer/VBoxContainer/ScrollContainer/ButtonRow/ResetButton
@onready var back_button: Button = $Control/CenterContainer/VBoxContainer/ScrollContainer/ButtonRow/BackButton

const CONFIG_PATH = "user://keybinds.cfg"

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	load_keybinds() # Load saved binds
	create_rebind_buttons()

func save_keybinds() -> void:
	var config = ConfigFile.new()
	for action in rebindable_actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			# Save the first event
			config.set_value("keybinds", action, events[0])
	config.save(CONFIG_PATH)

func load_keybinds() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		return # No saved config found, use defaults
		
	for action in rebindable_actions:
		if config.has_section_key("keybinds", action):
			var event = config.get_value("keybinds", action)
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
	
var rebindable_actions = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump / Up",
	"slide": "Slide / Down",
	"ability_1": "Ability 1",
	"ability_2": "Ability 2",
	"ability_3": "Ability 3"
}

func create_rebind_buttons() -> void:
	for child in action_list_container.get_children():
		child.queue_free()
		
	for action in rebindable_actions:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var label = Label.new()
		label.text = rebindable_actions[action]
		label.custom_minimum_size = Vector2(180, 40)
		hbox.add_child(label)
		
		var btn = Button.new()
		btn.name = action
		btn.custom_minimum_size = Vector2(160, 40)
		btn.text = get_action_key_name(action)
		btn.pressed.connect(_on_rebind_button_pressed.bind(action, btn))
		hbox.add_child(btn)
		
		action_list_container.add_child(hbox)

func get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
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
		if event.physical_keycode == KEY_ESCAPE:
			create_rebind_buttons()
			remapping_action = ""
			active_button = null
			return
			
		InputMap.action_erase_events(remapping_action)
		InputMap.action_add_event(remapping_action, event)
		
		# Save the newly overwritten bind
		save_keybinds()
		
		create_rebind_buttons()
		remapping_action = ""
		active_button = null
		get_viewport().set_input_as_handled()

func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	# Delete the saved config file
	var dir = DirAccess.open("user://")
	if dir.file_exists("keybinds.cfg"):
		dir.remove("keybinds.cfg")
	create_rebind_buttons()

func _on_back_button_pressed() -> void:
	if opened_from_pause:
		
		queue_free()
	else:
		var error = get_tree().change_scene_to_file("res://main_menu.tscn")
		if error != OK:
			print("Error loading main_menu.tscn: ", error)
