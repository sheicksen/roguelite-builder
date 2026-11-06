class_name Melee extends Node2D


@export var hitbox: Hitbox
@export var config: AbilityData
@export var direction: int
var sprite: AnimatedSprite2D
var valid_sprites = ["laser", "big_slash", "jab", "medium_slash", "poison_ball", "fire_ball"]

func _init(_config:AbilityData, _hitbox:Hitbox, _direction:int  = 1) -> void:
	config = _config
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/ability_sprite_frames.tres")
	sprite.position += config.sprite_offset
	sprite.position.x *= _direction
	if _direction < 1:
		sprite.flip_h = true
	add_child(sprite)
	sprite.z_index = 4
	hitbox = _hitbox
	hitbox.emit_signal = true
	if not config.piercing:
		hitbox.hit_made.connect(_destroy)
	hitbox.tree_exited.connect(queue_free)
	direction = _direction
	add_child(hitbox)

func _ready() -> void:
	sprite.play(config.sprite)
		

func _destroy(_attacker, _defender) -> void:
	# Play contact animation
	queue_free()
	
