class_name ranged_ability extends Ability

func spawn_hitboxes(user:Node, facing:int) -> void:
	var hitlog: HitLog 
	if data.hitlog:
		hitlog = HitLog.new() # Create hitlog if necessary
	for i in range(data.hitbox_count):
		print("Spawning hitbox: ", i)
		var hitbox_shape: Shape2D # Initiate variable for hitbox shape
		if data.shape == "Circle": # Create shape of hitbox with size specified in Data
			hitbox_shape = CircleShape2D.new()
			hitbox_shape.radius = data.hitbox_scale
		elif data.shape == "Rectangle":
			hitbox_shape = RectangleShape2D.new()
			hitbox_shape.size = data.scale
			
		var hitbox = Hitbox.new(data.stats, data.hitbox_lifespan, hitbox_shape, hitlog, data.emit_signal)
		hitbox.name = name + str(i)
		hitbox.position = data.hitbox_offsets[i]
		hitbox.position.x = hitbox.position.x * facing
		var projectile
		get_tree().current_scene.add_child(hitbox)
