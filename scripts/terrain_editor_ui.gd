extends CanvasLayer

## Provides terrain selection controls for the room editor.

@onready var room: EditableRoom = get_parent() as EditableRoom
@onready var terrain_selector: OptionButton = $PanelContainer/HBoxContainer/TerrainSelector


func _ready() -> void:
	# Show these controls only when editing is enabled.
	visible = room.edit_mode

	# Keep this order consistent with the terrain enum.
	terrain_selector.add_item("Solid")
	terrain_selector.add_item("Platform")
	terrain_selector.add_item("Destructible")
	terrain_selector.add_item("Hidden Passage")

	# Start with the terrain type selected in the room.
	terrain_selector.select(room.selected_terrain)

	# Respond when the user selects a different type.
	terrain_selector.item_selected.connect(_on_terrain_selected)


## Changes the terrain type used by mouse placement.
func _on_terrain_selected(index: int) -> void:
	room.selected_terrain = index
