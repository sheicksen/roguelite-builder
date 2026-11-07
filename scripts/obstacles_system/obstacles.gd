## Basic Obstacles Class
## base class for environmental hazards (like a spike), 
## that damages the player on contact
	
class_name Obstacle extends Node2D

@export var damage: int = 1
@export var hitbox_size: Vector2 = Vector2 (16,16)

func _ready() -> void:
	var attack := AttackStats.new(damage, BaseStats.DamageType.DEFAULT, [1])
	##Layer 1 is the player, so it will only damage the player's hurtbox
	var shape := RectangleShape2D.new()
	shape.size = hitbox_size
	var hitbox := Hitbox.new(attack, 10.0, shape)
	add_child(hitbox)
