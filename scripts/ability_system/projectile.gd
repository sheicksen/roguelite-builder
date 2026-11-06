class_name Projectile extends Node2D


@export var hitbox: Hitbox
@export var speed: int
@export var direction: int
@export var size: Vector2
@export var gravity: float = 950
@export var y_velocity = -200
@export var piercing: bool = false
@export var sprite_type: String = "poison_ball"
var sprite: AnimatedSprite2D

var valid_sprites = ["laser", "big_slash", "jab", "medium_slash", "poison_ball", "fire_ball"]

func _init(_sprite:String, _hitbox:Hitbox, _speed:int = 750, _direction:int  = -1, _size: Vector2 = Vector2(1.0, 1.0)) -> void:
	if _sprite in valid_sprites:
		sprite_type = _sprite
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/ability_sprite_frames.tres")
	if _direction < 1:
		sprite.flip_h = true
	add_child(sprite)
	speed = _speed
	hitbox = _hitbox
	hitbox.emit_signal = true
	if not piercing:
		hitbox.hit_made.connect(_destroy)
	hitbox.tree_exited.connect(queue_free)
	direction = _direction
	add_child(hitbox)

func _ready() -> void:
	sprite.play(sprite_type)
		
func _physics_process(delta: float) -> void:
	position.x += speed * delta * direction
	position.y += y_velocity*delta + 0.5*(gravity* delta**2)
	y_velocity = y_velocity + gravity*delta

func _destroy(_attacker, _defender) -> void:
	# Play contact animation
	queue_free()
	
