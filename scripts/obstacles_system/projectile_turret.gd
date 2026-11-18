#class_name ProjectileTurret extends Node2D
### Continuously shoots a Projectile at the player when they're in range.
### 
#@export var fire_interval: float = 2.0
#@export var projectile_speed: float = 150.0
#@export var damage: int = 1
#@export var detection_range: float = 250.0
#
#func _ready() -> void:
	#var timer := Timer.new()
	#timer.wait_time = fire_interval
	#timer.timeout.connect(_shoot)
	#add_child(timer)
	#timer.start()
#
#func _shoot() -> void:
	#var player := get_tree().get_first_node_in_group("player")
	#if player == null:
		#return
	#if global_position.distance_to(player.global_position) > detection_range:
		#return
#
	#var direction := (player.global_position - global_position).normalized()
	#var projectile := Projectile.new(direction, projectile_speed, damage)
#
	## Add to the level, not the turret, so it doesn't move with the turret
	#get_tree().current_scene.add_child(projectile)
	#projectile.global_position = global_position
