class_name SwordConfig extends AbilityData

func _init() -> void:
	stats = AttackStats.new(30, 0, [BaseStats.Faction.ENEMY])
	icon = ""
	
	sprite = "big_slash"
	sprite_scale = Vector2(1, 1)
	sprite_rotation = 0.0
	sprite_offset = Vector2(40, -20)

	cool_down = 3.0
	corrupted = false
	
	shape = "Circle"
	hitbox_scale = 15
	hitbox_lifespan = 0.8
	hitbox_count = 3
	hitlog = true
	hitbox_offsets = [Vector2(30, 0), Vector2(40, -20), Vector2(40, -40)]
	
	description = "A medium ranged melee attack. Split your enemies clean through for heavy damage."
