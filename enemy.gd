class_name EnemyController
extends CharacterBody2D

@export var move_speed: float = 120.0
@export var preferred_distance: float = 200.0
@export var target: Node2D
@export var health: float = 100.0


func _physics_process(_delta):
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_target = global_position.distance_to(
		target.global_position
	)

	if distance_to_target > preferred_distance:
		var direction = global_position.direction_to(
			target.global_position
		)

		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _ready() -> void:
	$Hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	
func _on_hurtbox_hit_received(hit_data: HitData) -> void:
	print("Enemy received a hit!")
	print("Health remaining: ", health)
	print("Damage type: ", hit_data.damage_type)
	print("Tags: ", hit_data.tags)

	if health <= 0:
		print("Enemy defeated!")
