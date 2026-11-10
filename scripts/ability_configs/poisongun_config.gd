class_name PoisonGunConfig extends ProjectileData

func _init() -> void:
	stats = AttackStats.new(
		20, 
		BaseStats.DamageType.POISON, 
		[BaseStats.Faction.ENEMY]
	)
	icon = ""
	
	sprite = "poison_ball"
	sprite_scale = Vector2(1.0, 1.0)
	sprite_rotation = 0.0
	sprite_offset = Vector2(0.0, 0.0)

	cool_down = 1.0
	corrupted = false
	
	shape = "Circle"
	hitbox_scale = 7
	hitbox_lifespan = 3.0
	hitbox_count = 1
	hitlog = true
	hitbox_offsets = [Vector2(10, 0)]
	
	speed = 700
	gravity = 950
	y_velocity = -200
	piercing = false
	
	description = "A medium-ranged projectile based attack. Spew a glob of poison in the air that arcs down upon your enemies."
