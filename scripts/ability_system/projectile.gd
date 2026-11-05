class_name Projectile extends Node2D

@export var sprite: Sprite2D
@export var hitbox: Hitbox
@export var speed: int
@export var direction: int
@export var size: Vector2
@export var gravity: float = 0
@export var piercing: bool = false

func _init(_sprite:String, _hitbox:Hitbox, _speed:int = 750, _direction:int  = -1, _size: Vector2 = Vector2(1.0, 1.0)) -> void:
	sprite = Sprite2D.new()
	sprite.texture = load(_sprite)
	sprite.size = _size
	add_child(sprite)
	hitbox = _hitbox
	if not piercing:
		hitbox.area_entered.connect(queue_free)
	hitbox.tree_exited.connect(queue_free)
	direction = _direction
	
func _physics_process(delta: float) -> void:
	self.position.x += speed * delta * direction
	self.position.y += gravity* delta
