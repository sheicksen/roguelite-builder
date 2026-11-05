class_name Projectile extends Node2D

@export var sprite: Sprite2D
@export var hitbox: Hitbox
@export var speed: int
@export var direction: int
@export var size: Vector2
@export var gravity: float = 0
@export var y_velocity = 0
@export var piercing: bool = false

func _init(_sprite:String, _hitbox:Hitbox, _speed:int = 750, _direction:int  = -1, _size: Vector2 = Vector2(1.0, 1.0)) -> void:
	sprite = Sprite2D.new()
	sprite.texture = load(_sprite)
	sprite.scale = _size
	speed = _speed
	add_child(sprite)
	hitbox = _hitbox
	if not piercing:
		hitbox.area_entered.connect(queue_free)
	hitbox.tree_exited.connect(queue_free)
	direction = _direction
	add_child(hitbox)
	
func _physics_process(delta: float) -> void:
	position.x += speed * delta * direction
	position.y += y_velocity*delta + 0.5*(gravity* delta**2)
	y_velocity = y_velocity + gravity*delta
