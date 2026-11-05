class_name RoomGen extends RefCounted

## Scene builder

func generate_room(data: RoomData) -> Node2D:
## if the data is null or invalid
	if data == null:
		push_error("room gen requires room data")
		return null
	if not _validate_definition(data):
		return null
		
	var room := Node2D.new()
	room.name = "GeneratedRoom"
	room.set_meta("room_size_cells", data.room_size_cells)
	room.set_meta("cell_size", data.cell_size)

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

func set_exit_open(
	data: RoomData,
	exit_index: int,
	is_open: bool,
	generated_room: Node2D = null
) -> bool:
	if data == null:
		push_error("RoomGen requires RoomData.")
		return false

	if exit_index < 0 or exit_index >= data.exits.size():
		push_error("RoomGen exit index %d is out of range." % exit_index)
		return false

	var exit_node: Node2D

	if generated_room != null:
		exit_node = generated_room.get_node_or_null(
			"Exits/Exit_%d" % exit_index
		) as Node2D

		if exit_node == null:
			push_error("Generated room is missing exit %d." % exit_index)
			return false

	if not data.set_exit_open(exit_index, is_open):
		return false

	if generated_room != null:
		_apply_exit_state(exit_node, is_open)

	return true


func _validate_definition(data: RoomData) -> bool:
	var is_valid := true

	if data.room_size_cells.x <= 0 or data.room_size_cells.y <= 0:
		push_error("RoomData room_size_cells values must be greater than zero.")
		is_valid = false

	if data.cell_size.x <= 0.0 or data.cell_size.y <= 0.0:
		push_error("RoomData cell_size values must be greater than zero.")
		is_valid = false

	if data.player_scene == null:
		push_error("RoomData requires a player_scene.")
		is_valid = false

	if not data.exits.is_empty() and data.exit_scene == null:
		push_error("RoomData requires an exit_scene when exits are configured.")
		is_valid = false

	is_valid = _validate_spawn_entries(data.layout, "layout") and is_valid
	is_valid = _validate_spawn_entries(data.enemy_spawns, "enemy") and is_valid
	is_valid = _validate_spawn_entries(data.obstacle_spawns, "obstacle") and is_valid

	for index in data.exits.size():
		var cell_value: Variant = data.exits[index].get("cell")

		if not cell_value is Vector2i:
			push_error(
				"RoomData exit %d must define a Vector2i in 'cell'." % index
			)
			is_valid = false

	return is_valid


func _validate_spawn_entries(
	entries: Array[Dictionary],
	entry_type: String
) -> bool:
	var is_valid := true

	for index in entries.size():
		var entry: Dictionary = entries[index]
		var scene_value: Variant = entry.get("scene")
		var cell_value: Variant = entry.get("cell")

		if not scene_value is PackedScene:
			push_error(
				"RoomData %s entry %d must define a PackedScene in 'scene'."
				% [entry_type, index]
			)
			is_valid = false

		if not cell_value is Vector2i:
			push_error(
				"RoomData %s entry %d must define a Vector2i in 'cell'."
				% [entry_type, index]
			)
			is_valid = false

	return is_valid


func _add_container(parent: Node, container_name: String) -> Node2D:
	var container := Node2D.new()
	container.name = container_name
	parent.add_child(container)
	return container


func _spawn_entries(
	data: RoomData,
	entries: Array[Dictionary],
	parent: Node2D,
	entry_type: String
) -> void:
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var scene_value: Variant = entry.get("scene")
		var cell_value: Variant = entry.get("cell")

		if not scene_value is PackedScene:
			push_error(
				"RoomGen %s entry %d has an invalid scene." % [entry_type, index]
			)
			continue

		if not cell_value is Vector2i:
			push_error(
				"RoomGen %s entry %d has an invalid cell." % [entry_type, index]
			)
			continue

		var instance := _instantiate_at_cell(
			data,
			scene_value,
			cell_value,
			parent,
			"%s %d" % [entry_type, index]
		)

		if instance != null:
			instance.name = "%s_%d" % [entry_type.capitalize(), index]


func _spawn_exits(data: RoomData, parent: Node2D) -> void:
	for index in data.exits.size():
		var exit_data: Dictionary = data.exits[index]
		var cell_value: Variant = exit_data.get("cell")

		if not cell_value is Vector2i:
			push_error(
				"RoomData exit %d has an invalid cell." % index
			)
			continue

		var exit_node := _instantiate_at_cell(
			data,
			data.exit_scene,
			cell_value,
			parent,
			"exit %d" % index
		)

		if exit_node != null:
			exit_node.name = "Exit_%d" % index
			_apply_exit_state(
				exit_node,
				bool(exit_data.get("is_open", false))
			)


func _instantiate_at_cell(
	data: RoomData,
	scene: PackedScene,
	cell: Vector2i,
	parent: Node2D,
	description: String
) -> Node2D:
	var instance := scene.instantiate()

	if not instance is Node2D:
		push_error("RoomGen %s scene root must be a Node2D." % description)
		instance.free()
		return null

	var node := instance as Node2D
	node.position = _cell_to_position(data, cell)
	parent.add_child(node)

	return node


func _cell_to_position(data: RoomData, cell: Vector2i) -> Vector2:
	return Vector2(cell) * data.cell_size + data.cell_size * 0.5


func _apply_exit_state(exit_node: Node2D, is_open: bool) -> void:
	exit_node.set_meta("is_open", is_open)

	for property in exit_node.get_property_list():
		var property_name: StringName = property["name"]

		if property_name == &"is_open":
			exit_node.set("is_open", is_open)
			return