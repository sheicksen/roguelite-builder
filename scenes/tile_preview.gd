
extends Node2D

## Shows which terrain cell the mouse will edit.

@onready var terrain: TileMapLayer = get_parent() as TileMapLayer
@onready var room: EditableRoom = terrain.get_parent() as EditableRoom

var _last_terrain_type: int = -1


func _ready() -> void:
	# Draw the preview above the terrain tiles.
	z_index = 10
	queue_redraw()


func _process(_delta: float) -> void:
	# Only show the preview while editing.
	visible = room.edit_mode

	if not visible:
		return

	# Find the grid cell underneath the mouse.
	var mouse_position: Vector2 = terrain.get_local_mouse_position()
	var cell: Vector2i = terrain.local_to_map(mouse_position)

	# Snap the preview to the center of that cell.
	position = terrain.map_to_local(cell)

	# Redraw only when the selected terrain type changes.
	if _last_terrain_type != room.selected_terrain:
		_last_terrain_type = room.selected_terrain
		queue_redraw()


## Draws a translucent square over the selected cell.
func _draw() -> void:
	if terrain.tile_set == null:
		return

	var tile_size: Vector2 = Vector2(terrain.tile_set.tile_size)
	var rect := Rect2(-tile_size / 2.0, tile_size)

	var preview_color := Color(0.25, 0.65, 1.0, 0.25)

	# Give each terrain type a different preview color.
	match room.selected_terrain:
		0:
			preview_color = Color(0.25, 0.65, 1.0, 0.25)
		1:
			preview_color = Color(0.25, 0.9, 0.5, 0.25)
		2:
			preview_color = Color(1.0, 0.6, 0.2, 0.25)
		3:
			preview_color = Color(0.7, 0.4, 1.0, 0.25)

	# Translucent fill.
	draw_rect(rect, preview_color, true)

	# Solid outline for visibility.
	var outline_color := preview_color
	outline_color.a = 0.9

	draw_rect(rect, outline_color, false, 2.0)
