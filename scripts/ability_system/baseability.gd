class_name Ability extends Node
var data:AbilityData = AbilityData.new()
var cooldown_timer: Timer
var is_ready: bool = true

func _init(
	_name:String, 
	) -> void:
	name = _name
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(reset_cooldown)
	

func use_ability(user:Node, facing:int) -> void:
	if is_ready:
		print("Ability used")
		is_ready = false
		spawn_hitboxes(user, facing)
		cooldown_timer.call_deferred("start", data.cool_down)

func spawn_hitboxes(user:Node, facing:int) -> void:
	for i in range(data.hitbox_count):
		print("Spawning hitbox: ", i)
		var hitbox_shape: Shape2D # Initiate variable for hitbox shape
		var hitlog: HitLog 
		if data.hitlog:
			hitlog = HitLog.new() # Create hitlog if necessary
		if data.shape == "Circle": # Create shape of hitbox with size specified in Data
			hitbox_shape = CircleShape2D.new()
			hitbox_shape.radius = data.hitbox_scale
		elif data.shape == "Rectangle":
			hitbox_shape = RectangleShape2D.new()
			hitbox_shape.size = data.scale
			
		var hitbox = Hitbox.new(data.stats, data.hitbox_lifespan, hitbox_shape, hitlog, data.emit_signal)
		hitbox.name = name + str(i)
		hitbox.position = (data.hitbox_offsets[i]*facing)
		user.add_child(hitbox)

func reset_cooldown() -> void:
	print("Ability cooled down")
	cooldown_timer.stop()
	is_ready = true
