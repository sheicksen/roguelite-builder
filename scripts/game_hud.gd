extends CanvasLayer

#UI
@onready var health_bar: ProgressBar = $HUD_Root/TopLevelLayout/CenterBarContainer/HealthBar
@onready var stamina_bar: ProgressBar = $HUD_Root/TopLevelLayout/CenterBarContainer/StaminaBar
@onready var corruption_circle: TextureRect = $HUD_Root/TopLevelLayout/LeftPanel/HBoxContainer/CorruptionCircle

@onready var powerup_slot_1: TextureRect = $HUD_Root/TopLevelLayout/LeftPanel/HBoxContainer/PowerupSlotsContainer/PowerupSlot1
@onready var powerup_slot_2: TextureRect = $HUD_Root/TopLevelLayout/LeftPanel/HBoxContainer/PowerupSlotsContainer/PowerupSlot2
@onready var powerup_slot_3: TextureRect = $HUD_Root/TopLevelLayout/LeftPanel/HBoxContainer/PowerupSlotsContainer/PowerupSlot3

@onready var dollar_label: Label = $HUD_Root/TopLevelLayout/RightPanel/VBoxContainer/DollarLabel
@onready var cent_label: Label = $HUD_Root/TopLevelLayout/RightPanel/VBoxContainer/CentLabel

# INT TRACKING VAR (assigned for currency)
var current_dollars: int = 0
var current_cents: int = 0

func _ready() -> void:
	initialize_hud()

# health and stamina bar
func update_health_on_damage(damage_amount: float = 0.0) -> void:
	# CUSTOM...THIS IS FILLER TO CHANGE BASED ON ENEMIES OR ALL ROUND
	health_bar.value -= damage_amount
	
	# flashing indicator
	trigger_health_bar_flash()

func trigger_health_bar_flash() -> void:
	#flash white and red..we can change this to maybe something more futuristic probably. 
	var tween = create_tween()
	tween.tween_property(health_bar, "modulate", Color(2.0, 0.5, 0.5), 0.1)
	tween.tween_property(health_bar, "modulate", Color(1.0, 1.0, 1.0), 0.1)
func update_stamina_on_sprint(drain_amount: float = 0.0) -> void:
	stamina_bar.value -= drain_amount

# Corruption (UNTESTED AND UNASSIGNED)
func update_corruption(increase_amount: float = 0.0) -> void:
	pass

# currency (UNTESTED AND UNASSIGNED)
func add_dollar_currency(amount: int = 1) -> void:
	current_dollars += amount
	dollar_label.text = "$: " + str(current_dollars)

func add_cent_currency(amount: int = 1) -> void:
	current_cents += amount
	cent_label.text = "¢: " + str(current_cents)

# SLOTS (UNTESTED AND UNASSIGNED/ instead of linking specific variables we should have powerups pull from the file names for the icons rather than variables,
# that way its easier on pickup and we dont have to worry about loosing items if unequipted?)
func display_powerup_icon(slot_index: int, icon_texture: Texture2D) -> void:
	match slot_index:
		1: powerup_slot_1.texture = icon_texture
		2: powerup_slot_2.texture = icon_texture
		3: powerup_slot_3.texture = icon_texture

# INITALIZATION.
func initialize_hud() -> void:
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	dollar_label.text = "$: 0"
	cent_label.text = "¢: 0"
