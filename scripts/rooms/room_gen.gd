class_name RoomGen extends RefCounted

## Scene builder
## what's needed: room heirarchy from room_data

func generate_room(data: RoomData) -> Node2D:
## if the data is null or invalid
    if data == null:
    push_error("room gen requires room data")
    return null

    if not _validate_definition(data):
        return null

    var room := Node2D.new()
	room.name = "GeneratedRoom"
	room.set_meta("room_size_cells", room_size_cells)
	room.set_meta("cell_size", cell_size)

	var layout_root := _add_container(room, "Layout")
	var exits_root := _add_container(room, "Exits")
	var enemies_root := _add_container(room, "Enemies")
	var obstacles_root := _add_container(room, "Obstacles")

	_spawn_entries(data, data.layout, layout_root, "layout")
	_spawn_exits(data, exits_root)
	_spawn_entries(data, data.enemy_spawns, enemies_root, "enemy")
	_spawn_entries(data, data.obstacle_spawns, obstacles_root, "obstacle")

	var player := _instantiate_at_cell(
        data,
		data.player_scene,
		data.player_spawn_cell,
		room,
		"player"
	)

	if player != null:
		player.name = "Player"

	return room