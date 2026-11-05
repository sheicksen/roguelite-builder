class_name RoomData extends Resource

## what's needed: data definition (basically everything in the room)

## default room dimensions
@export var room_size_cells: Vector2i = Vector2i(16, 9)
@export var cell_size: Vector2 = Vector2(128.0, 128.0)

@export_group("Player")
@export var player_scene: PackedScene
@export var player_spawn_cell: Vector2i = Vector2i(1, 1)

@export_group("Exits")
@export var exit_scene: PackedScene
@export var exits: Array[Dictionary] = []

@export_group("Room Contents")
@export var layout: Array[Dictionary] = []
@export var enemy_spawns: Array[Dictionary] = []
@export var obstacle_spawns: Array[Dictionary] = []

## exits/doors configs

## checks to see if the exit is open
func is_exit_open(exit_index: int) -> bool:
	if not _is_valid_exit_index(exit_index):
		return false
	return bool(exits[exit_index].get("is_open", false))

## updates exit state
func set_exit_open(exit_index: int, is_open: bool) -> bool:
	if not _is_valid_exit_index(exit_index):
		return false
		
		var exit_data: Dictionary = exits[exit_index]
		exit_data["is_open"] = is_open
		exits[exit_index] = exit_data
	return true

func _is_valid_exit_index(exit_index: int) -> bool:
	if exit_index < 0 or exit_index >= exits.size():
		push_error("RoomGen exit index %d is out of range." % exit_index)
		return false
	return true
