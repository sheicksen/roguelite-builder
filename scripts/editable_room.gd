
class_name EditableRoom
extends Node2D

## Manages editable floor and wall tiles for the level builder.

# --- Tile Configuration ---

@export_group("Solid Terrain")
@export var solid_source_id: int = 0
@export var solid_atlas_coords: Vector2i = Vector2i.ZERO

@export_group("Platforms")
@export var platform_source_id: int = 0
@export var platform_atlas_coords: Vector2i = Vector2i.ZERO
@export var platform_alternative_id: int = 1

@export_group("Editor")
@export var edit_mode: bool = false
@export_enum("Solid", "Platform") var selected_terrain: int = 0

# References to the room's terrain layers.
@onready var solid_terrain: TileMapLayer = $SolidTerrain
@onready var platforms: TileMapLayer = $Platforms


# --- Solid Terrain ---

## Places a solid tile and removes any platform at that cell.
func place_solid_tile(cell: Vector2i) -> void:
	platforms.erase_cell(cell)

	solid_terrain.set_cell(
		cell,
		solid_source_id,
		solid_atlas_coords
	)


func remove_solid_tile(cell: Vector2i) -> void:
	solid_terrain.erase_cell(cell)


func has_solid_tile(cell: Vector2i) -> bool:
	return solid_terrain.get_cell_source_id(cell) != -1


# --- Semi-Solid Platforms ---

## Places a one-way platform using the alternative tile.
func place_platform_tile(cell: Vector2i) -> void:
	solid_terrain.erase_cell(cell)

	platforms.set_cell(
		cell,
		platform_source_id,
		platform_atlas_coords,
		platform_alternative_id
	)


func remove_platform_tile(cell: Vector2i) -> void:
	platforms.erase_cell(cell)


func has_platform_tile(cell: Vector2i) -> bool:
	return platforms.get_cell_source_id(cell) != -1


# --- General Terrain Editing ---

## Removes either type of terrain from a cell.
func remove_tile(cell: Vector2i) -> void:
	remove_solid_tile(cell)
	remove_platform_tile(cell)


## Handles placing and removing terrain with the mouse.
func _unhandled_input(event: InputEvent) -> void:
	if not edit_mode:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_position: Vector2 = solid_terrain.get_local_mouse_position()
		var cell: Vector2i = solid_terrain.local_to_map(mouse_position)

		match event.button_index:
			MOUSE_BUTTON_LEFT:
				match selected_terrain:
					0:
						place_solid_tile(cell)
					1:
						place_platform_tile(cell)

			MOUSE_BUTTON_RIGHT:
				remove_tile(cell)
