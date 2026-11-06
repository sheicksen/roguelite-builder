class_name RangedAbility extends Ability

func spawn_hitboxes(_user:Node, facing:int) -> void:
	var hitlog: HitLog 
	if data.hitlog:
		hitlog = HitLog.new() # Create hitlog if necessary
	for i in range(data.hitbox_count):
		var hitbox_shape: Shape2D # Initiate variable for hitbox shape
		if data.shape == "Circle": # Create shape of hitbox with size specified in Data
			hitbox_shape = CircleShape2D.new()
			hitbox_shape.radius = data.hitbox_scale
		elif data.shape == "Rectangle":
			hitbox_shape = RectangleShape2D.new()
			hitbox_shape.size = data.scale
			
		var hitbox = Hitbox.new(data.stats, data.hitbox_lifespan, hitbox_shape, hitlog, data.do_emit_signal)
		var projectile = Projectile.new(data, hitbox, facing)
		projectile.position.y = _user.position.y + data.hitbox_offsets[i].y
		projectile.position.x = _user.position.x + (data.hitbox_offsets[i].x * facing)
		get_tree().current_scene.add_child(projectile)
