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


## Moves the projectile and checks for terrain collisions.
func _physics_process(delta: float) -> void:
	# Calculate where the projectile will move this frame.
	var movement := Vector2(
		config.speed * delta * direction,
		y_velocity * delta + 0.5 * config.gravity * delta * delta
	)

	var start_position: Vector2 = global_position
	var end_position: Vector2 = start_position + movement

	# Check for solid terrain along the projectile's path.
	# Collision mask 1 detects solid and destructible terrain.
	var query := PhysicsRayQueryParameters2D.create(
		start_position,
		end_position,
		1
	)

	# Detect collisions even when the projectile starts inside a wall.
	query.hit_from_inside = true

	# Detect physics bodies, not Area2D hurtboxes.
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var collision: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	# Handle projectile collisions with terrain.
	if not collision.is_empty():
		var collider: Object = collision["collider"]

		# Check whether we hit a terrain layer.
		if collider is TileMapLayer:
			var layer: TileMapLayer = collider as TileMapLayer
			var room: EditableRoom = layer.get_parent() as EditableRoom

			# Destructible terrain should receive damage.
			if room != null and layer == room.destructible_terrain:

				# Move slightly inside the tile to identify
				# the correct cell rather than its boundary.
				var impact_position: Vector2 = collision["position"]

				if movement.length_squared() > 0.0:
					impact_position += movement.normalized() * 2.0

				# Apply damage through the existing terrain system.
				room.call_deferred(
					"damage_destructible_at_position",
					impact_position,
					hitbox.attack_effects.damage
				)

				print("Projectile hit destructible terrain!")

		# Stop the projectile regardless of terrain type.
		global_position = collision["position"]
		queue_free()
		return

	# No collision: continue moving normally.
	global_position = end_position
	y_velocity += config.gravity * delta


func _destroy(_attacker, _defender) -> void:
	# Play contact animation
	queue_free()
	
