class_name Hook extends Area2D
## Snags the player on contact, stopping their movement while they touch it.

@export var size: Vector2 = Vector2(16, 16)

var _removed: Dictionary = {}  # Hurtbox -> speed removed

func _ready() -> void:
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = size
	add_child(collision)

	monitorable = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, true)  # layer 1 = player Hurtbox

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and not _removed.has(area):
		_removed[area] = area.stats.speed
		area.stats.modify_speed(-area.stats.speed)  # speed drops to 0

func _on_area_exited(area: Area2D) -> void:
	if _removed.has(area):
		area.stats.modify_speed(_removed[area])
		_removed.erase(area)
