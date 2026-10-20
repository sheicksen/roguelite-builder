class_name BaseEnemy
extends CharacterBody2D

@export var enemy_name: String = "Basic Enemy"
@export var max_health: int = 100
@export var move_speed: int = 100
@export var defense: int = 0

var stats: EntityStats
var hurtbox: Hurtbox

func _ready() -> void:
	stats = EntityStats.new(
		enemy_name,
		BaseStats.Faction.ENEMY,
		max_health,
		move_speed,
		defense
	)
	
	# Create a shape for the hurtbox.
	var hurtbox_shape := RectangleShape2D.new()
	hurtbox_shape.size = Vector2(32, 32)

	# Create a hurtbox using the enemy's stats.
	hurtbox = Hurtbox.new(
		stats,
		0.0,
		hurtbox_shape,
		false,
		true
	)

	# Listen for changes to the enemy's health.
	hurtbox.health_changed.connect(_on_health_changed)

	# Add the hurtbox to the enemy scene.
	add_child(hurtbox)

func _on_health_changed(
	old_health: int,
	new_health: int
) -> void:
	print("Enemy health: ", old_health, " -> ", new_health)

	if new_health <= 0:
		die()


func die() -> void:
	print(enemy_name, " has died!")
	queue_free()
