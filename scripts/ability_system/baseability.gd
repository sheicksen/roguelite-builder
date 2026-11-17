class_name Ability extends Node
var data:AbilityData
var cooldown_timer: Timer
var is_ready: bool = true

func _init(
	_name:String,
	_ability_data:AbilityData
	) -> void:
	name = _name
	data = _ability_data
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(reset_cooldown)
	

func use_ability(user:Node, facing:int) -> void:
	if is_ready:
		is_ready = false
		spawn_hitboxes(user, facing)
		cooldown_timer.call_deferred("start", data.cool_down)

func spawn_hitboxes(user:Node, facing:int) -> void:
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
			hitbox_shape.size = data.hitbox_scale
			
		var hitbox = Hitbox.new(data.stats, data.hitbox_lifespan, hitbox_shape, hitlog)
		hitbox.name = name + str(i)
		hitbox.position = data.hitbox_offsets[i]
		hitbox.position.x = hitbox.position.x * facing
		var melee = Melee.new(data, hitbox, facing)
		user.add_child(melee)	

func reset_cooldown() -> void:
	cooldown_timer.stop()
	is_ready = true
