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
