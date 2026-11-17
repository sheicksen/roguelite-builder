class_name TerrainHurtbox
extends Area2D

## Connects the existing hitbox system to destructible tiles.

var room: EditableRoom
var cell: Vector2i


## Sets up collision detection for one destructible tile.
func configure(
	target_room: EditableRoom,
	target_cell: Vector2i,
	tile_size: Vector2
) -> void:
	room = target_room
	cell = target_cell

	# Layer 3 is ENVIRONMENT in the team's hitbox system.
	collision_layer = 0
	set_collision_layer_value(3, true)
	collision_mask = 0

	# Match the tile's dimensions.
	var shape := RectangleShape2D.new()
	shape.size = tile_size

	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)


## Called automatically when a compatible Hitbox overlaps us.
func receive_hit(attack: AttackStats) -> void:
	if room == null or attack.damage <= 0:
		return

	# Defer tile changes so they are safe during physics callbacks.
	room.call_deferred(
		"damage_destructible_tile",
		cell,
		attack.damage
	)
