class_name KnifeConfig extends AbilityData

func _init() -> void:
	stats = AttackStats.new(10, 0, [BaseStats.Faction.ENEMY])
	icon = ""
	
	sprite = "jab"
	sprite_scale = Vector2(1, 1)
	sprite_rotation = 0.0
	sprite_offset = Vector2(40, 0)

	cool_down = 1.0
	corrupted = false
	
	shape = "Rectangle"
	hitbox_scale = Vector2(60, 6)
	hitbox_lifespan = 0.8
	hitbox_count = 1
	hitlog = true
	hitbox_offsets = [Vector2(30, 0)]
	
	description = "A fast, short-range  melee attack. Clean and simple."
