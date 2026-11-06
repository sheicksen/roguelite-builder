class_name KnifeConfig extends AbilityData

func _init() -> void:
	stats = AttackStats.new(10, 0, [BaseStats.Faction.ENEMY])
	icon = ""
	
	sprite = "jab"
	sprite_scale = Vector2(0.3, 0.3)
	sprite_rotation = 0.0
	sprite_offset = Vector2(0.0, 0.0)

	cool_down = 1.0
	corrupted = false
	
	shape = "Rectangle"
	hitbox_scale = Vector2(15, 5)
	hitbox_lifespan = 0.8
	hitbox_count = 1
	hitlog = true
	hitbox_offsets = [Vector2(20, 0)]
