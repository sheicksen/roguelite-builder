class_name Projectile extends Node2D


@export var hitbox: Hitbox
@export var config: ProjectileData
@export var direction: int
@export var y_velocity: float
var sprite: AnimatedSprite2D

var valid_sprites = ["laser", "big_slash", "jab", "medium_slash", "poison_ball", "fire_ball"]

func _init(_config:ProjectileData, _hitbox:Hitbox, _direction:int  = 1) -> void:
	config = _config
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/ability_sprite_frames.tres")
	if _direction < 1:
		sprite.flip_h = true
	add_child(sprite)
	y_velocity = _config.y_velocity
	hitbox = _hitbox
	hitbox.emit_signal = true
	if not config.piercing:
		hitbox.hit_made.connect(_destroy)
	hitbox.tree_exited.connect(queue_free)
	direction = _direction
	add_child(hitbox)

func _ready() -> void:
	sprite.play(config.sprite)
		
func _physics_process(delta: float) -> void:
	position.x += config.speed * delta * direction
	
	position.y += y_velocity*delta + 0.5*(config.gravity* delta**2)
	y_velocity = y_velocity + config.gravity*delta

func _destroy(_attacker, _defender) -> void:
	# Play contact animation
	queue_free()
	
