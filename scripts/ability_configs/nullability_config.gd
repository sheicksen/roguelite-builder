class_name NullAbilityConfig extends AbilityData

func _init() -> void:
	stats = null
	icon = ""
	
	sprite = ""
	sprite_scale = Vector2(0, 0)
	sprite_rotation = 0.0
	sprite_offset = Vector2(0, 0)

	cool_down = 0
	corrupted = false
	
	shape = "Circle"
	hitbox_scale = Vector2(0, 0)
	hitbox_lifespan = 0
	hitbox_count = 0
	hitlog = false
	hitbox_offsets = []
