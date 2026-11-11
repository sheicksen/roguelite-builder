
class_name EditableRoom
extends Node2D

## Emitted whenever the room's terrain is edited.
signal terrain_changed

## Manages editable floor and wall tiles for the level builder.

# --- Tile Configuration ---

@export_group("Solid Terrain")
@export var solid_source_id: int = 0
@export var solid_atlas_coords: Vector2i = Vector2i.ZERO

@export_group("Platforms")
@export var platform_source_id: int = 0
@export var platform_atlas_coords: Vector2i = Vector2i.ZERO
@export var platform_alternative_id: int = 1

@export_group("Destructible Terrain")
@export_range(1, 1000, 1)
var destructible_max_health: int = 100

@export var destructible_source_id: int = 0
@export var destructible_atlas_coords: Vector2i = Vector2i.ZERO


@export_group("Editor")
@export var edit_mode: bool = false
@export_enum("Solid", "Platform", "Destructible", "Hidden Passage")
var selected_terrain: int = 0

# References to the room's terrain layers.
@onready var solid_terrain: TileMapLayer = $SolidTerrain
@onready var platforms: TileMapLayer = $Platforms
@onready var destructible_terrain: TileMapLayer = $DestructibleTerrain
@onready var hidden_passages: TileMapLayer = $HiddenPassages

## Initialize navigation after the room's terrain layers are ready.
func _ready() -> void:
	var navigation: TerrainNavigation = $TerrainNavigation

	if navigation != null:
		navigation.rebuild_navigation()

# --- Constants ---

const ROOM_FILE_PATH: String = "user://editable_room.json"
const ROOM_FORMAT_VERSION: int = 1
const EDITOR_TEST_DAMAGE: int = 25

# Stores the remaining health of each destructible cell.
var _destructible_health: Dictionary = {}

# Keeps track of the Area2D associated with each tile.
var _destructible_hurtboxes: Dictionary = {}

## Terrain types available in the level editor.
enum TerrainType {
	SOLID,
	PLATFORM,
	DESTRUCTIBLE,
	HIDDEN_PASSAGE
}

# --- Solid Terrain ---

## Places a solid tile, replacing any existing terrain.
func place_solid_tile(cell: Vector2i) -> void:
	remove_tile(cell)

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

## Places a one-way platform, replacing existing terrain.
func place_platform_tile(cell: Vector2i) -> void:
	remove_tile(cell)

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

## Removes any terrain type at the specified cell.
func remove_tile(cell: Vector2i) -> void:
	remove_solid_tile(cell)
	remove_platform_tile(cell)
	remove_destructible_tile(cell)
	remove_hidden_passage_tile(cell)



## Paints, removes, or damages terrain at the mouse position.
func _edit_tile_at_mouse(button: int) -> void:
	var mouse_position: Vector2 = solid_terrain.get_local_mouse_position()
	var cell: Vector2i = solid_terrain.local_to_map(mouse_position)

	match button:
		MOUSE_BUTTON_LEFT:
			match selected_terrain:
				TerrainType.SOLID:
					if not has_solid_tile(cell):
						place_solid_tile(cell)

				TerrainType.PLATFORM:
					if not has_platform_tile(cell):
						place_platform_tile(cell)

				TerrainType.DESTRUCTIBLE:
					if not has_destructible_tile(cell):
						place_destructible_tile(cell)

				TerrainType.HIDDEN_PASSAGE:
					if not has_hidden_passage_tile(cell):
						place_hidden_passage_tile(cell)

		MOUSE_BUTTON_RIGHT:
			remove_tile(cell)

		MOUSE_BUTTON_MIDDLE:
			damage_destructible_at_position(
			get_global_mouse_position(),
			EDITOR_TEST_DAMAGE
		)

	# Notify other systems that the terrain may have changed.
	terrain_changed.emit()



## Handles keyboard shortcuts and mouse terrain editing.
func _unhandled_input(event: InputEvent) -> void:
	if not edit_mode:
		return

	# Save and load shortcuts.
	if event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_F9:
					save_room()
					return

				KEY_F10:
					load_room()
					return

	# Handle individual mouse clicks.
	if event is InputEventMouseButton:
		if event.pressed:
			_edit_tile_at_mouse(event.button_index)

	# Handle mouse movement while a button is held.
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_edit_tile_at_mouse(MOUSE_BUTTON_LEFT)

		elif (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			_edit_tile_at_mouse(MOUSE_BUTTON_RIGHT)


# --- Destructible Terrain ---

## Places a destructible tile with full health.
func place_destructible_tile(cell: Vector2i) -> void:
	remove_tile(cell)

	destructible_terrain.set_cell(
		cell,
		destructible_source_id,
		destructible_atlas_coords
	)

	_destructible_health[cell] = destructible_max_health

	# Each destructible cell needs its own hurtbox so attacks
	# can damage individual tiles instead of the entire layer.
	var hurtbox := TerrainHurtbox.new()

	hurtbox.configure(
		self,
		cell,
		Vector2(destructible_terrain.tile_set.tile_size)
	)

	destructible_terrain.add_child(hurtbox)
	hurtbox.position = destructible_terrain.map_to_local(cell)

	_destructible_hurtboxes[cell] = hurtbox


## Removes both the tile and its stored health.

func remove_destructible_tile(cell: Vector2i) -> void:
	# Check whether a tile actually exists before removing it.
	var had_tile: bool = has_destructible_tile(cell)

	destructible_terrain.erase_cell(cell)
	_destructible_health.erase(cell)

	# Remove the tile's attack-detection area.
	if _destructible_hurtboxes.has(cell):
		var hurtbox: TerrainHurtbox = _destructible_hurtboxes[cell]

		_destructible_hurtboxes.erase(cell)
		hurtbox.queue_free()

	# Tell navigation that the terrain has changed.
	if had_tile:
		terrain_changed.emit()


func has_destructible_tile(cell: Vector2i) -> bool:
	return destructible_terrain.get_cell_source_id(cell) != -1


func get_destructible_health(cell: Vector2i) -> int:
	return int(_destructible_health.get(cell, 0))


## Applies damage and returns true if the tile was destroyed.
func damage_destructible_tile(cell: Vector2i, amount: int) -> bool:
	if amount <= 0 or not has_destructible_tile(cell):
		return false

	var remaining: int = get_destructible_health(cell) - amount

	if remaining <= 0:
		remove_destructible_tile(cell)
		return true

	_destructible_health[cell] = remaining
	return false


## Damages a destructible tile at a global world position.
## Returns true if the tile was destroyed.
func damage_destructible_at_position(
	world_position: Vector2,
	amount: int
) -> bool:
	# Convert the global position to the layer's local space.
	var local_position: Vector2 = destructible_terrain.to_local(
		world_position
	)

	# Determine which tile occupies that position.
	var cell: Vector2i = destructible_terrain.local_to_map(
		local_position
	)

	return damage_destructible_tile(cell, amount)


# --- Hidden Passages ---

## Places a false wall that looks solid but has no collision.
func place_hidden_passage_tile(cell: Vector2i) -> void:
	remove_tile(cell)

	# Reuse the solid tile's appearance.
	hidden_passages.set_cell(
		cell,
		solid_source_id,
		solid_atlas_coords
	)


func remove_hidden_passage_tile(cell: Vector2i) -> void:
	hidden_passages.erase_cell(cell)


func has_hidden_passage_tile(cell: Vector2i) -> bool:
	return hidden_passages.get_cell_source_id(cell) != -1


# --- Room Saving ---

## Converts a TileMapLayer into data that can be saved.
func _serialize_layer(layer: TileMapLayer) -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []

	for cell in layer.get_used_cells():
		var atlas: Vector2i = layer.get_cell_atlas_coords(cell)

		tiles.append({
			"x": cell.x,
			"y": cell.y,
			"source_id": layer.get_cell_source_id(cell),
			"atlas_x": atlas.x,
			"atlas_y": atlas.y,
			"alternative": layer.get_cell_alternative_tile(cell)
		})

	return tiles

## Creates a dictionary describing the room's terrain.
func get_room_data() -> Dictionary:
	var destructibles: Array[Dictionary] = _serialize_layer(
		destructible_terrain
	)

	# Save the remaining health of every destructible tile.
	for tile in destructibles:
		var cell := Vector2i(
			int(tile["x"]),
			int(tile["y"])
		)

		tile["health"] = get_destructible_health(cell)

	return {
		"version": ROOM_FORMAT_VERSION,
		"solid": _serialize_layer(solid_terrain),
		"platform": _serialize_layer(platforms),
		"destructible": destructibles,
		"hidden": _serialize_layer(hidden_passages)
	}

## Saves the current room to the user's local data folder.
func save_room() -> bool:
	var path := "user://editable_room.json"

	var file := FileAccess.open(ROOM_FILE_PATH, FileAccess.WRITE)

	if file == null:
		push_error(
			"Could not save room: " +
			str(FileAccess.get_open_error())
		)
		return false

	var room_data: Dictionary = get_room_data()
	file.store_string(JSON.stringify(room_data, "\t"))
	file.close()

	print("Room saved to: ", path)
	return true


## Restores tiles using saved TileSet information.
## Destructible cells must also recreate their health and hurtboxes.
func _restore_layer(layer: TileMapLayer, tiles: Array) -> void:
	for entry in tiles:
		if not entry is Dictionary:
			continue

		var tile: Dictionary = entry

		if not tile.has("x") or not tile.has("y"):
			continue

		var cell := Vector2i(
			int(tile["x"]),
			int(tile["y"])
		)

		# Destructible tiles also need health and a hurtbox.
		if layer == destructible_terrain:
			var health: int = int(
				tile.get("health", destructible_max_health)
			)

			if health <= 0:
				continue

			place_destructible_tile(cell)
			_destructible_health[cell] = health

		# Restore the original tile appearance and alternative.
		layer.set_cell(
			cell,
			int(tile.get("source_id", 0)),
			Vector2i(
				int(tile.get("atlas_x", 0)),
				int(tile.get("atlas_y", 0))
			),
			int(tile.get("alternative", 0))
		)

## Replaces the current terrain with saved room data.
func load_room_data(data: Dictionary) -> bool:
	# Verify the file format before modifying the room.
	if int(data.get("version", -1)) != ROOM_FORMAT_VERSION:
		push_warning("Unsupported room file version.")
		return false

	for section in ["solid", "platform", "destructible", "hidden"]:
		if not data.has(section) or not (data[section] is Array):
			push_warning("Invalid room section: " + section)
			return false

	# Free the old destructible hurtboxes.
	for hurtbox in _destructible_hurtboxes.values():
		if is_instance_valid(hurtbox):
			hurtbox.queue_free()

	_destructible_hurtboxes.clear()
	_destructible_health.clear()

	# Remove the previous layout.
	solid_terrain.clear()
	platforms.clear()
	destructible_terrain.clear()
	hidden_passages.clear()

	# Rebuild each terrain layer.
	_restore_layer(solid_terrain, data["solid"])
	_restore_layer(platforms, data["platform"])
	_restore_layer(hidden_passages, data["hidden"])
	_restore_layer(destructible_terrain, data["destructible"])

	# Rebuild navigation after restoring the saved room.
	terrain_changed.emit()

	return true


## Loads a previously saved room from disk.
func load_room() -> bool:
	var path := "user://editable_room.json"

	if not FileAccess.file_exists(path):
		push_warning("No saved room found.")
		return false

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open saved room.")
		return false

	var contents: String = file.get_as_text()
	file.close()

	# Convert JSON text back into a dictionary.
	var parsed: Variant = JSON.parse_string(contents)

	if not parsed is Dictionary:
		push_error("Saved room contains invalid JSON data.")
		return false

	if not load_room_data(parsed):
		return false

	print("Room loaded from: ", path)
	return true
