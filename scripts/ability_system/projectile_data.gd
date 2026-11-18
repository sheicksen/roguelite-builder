class_name ProjectileData extends AbilityData
## Extension of AbilityData class. Manages additional data specific to projectiles,
## including projectile speed, gravity applied, and initial upwards momentum (negative).
@export var speed: int = 700 # Projectile speed
@export var gravity: float = 0 # Gravity, or anti gravity (if negative), applied to projectile
@export var y_velocity = 0 # Upwards momentum (Should be negative if projectile is to go up)

## Estimates whether a projectile can hit a target
## at its current position.
func can_hit_target(
	attacker_position: Vector2,
	target_position: Vector2,
	target_half_height: float = 16.0
) -> bool:
	if speed <= 0:
		return false

	var direction: float = signf(
		target_position.x - attacker_position.x
	)

	if direction == 0.0:
		return false

	# Determine the projectile's vertical hitbox extent.
	var projectile_half_height: float = 0.0

	if shape == "Circle":
		projectile_half_height = float(hitbox_scale)
	elif shape == "Rectangle" and hitbox_scale is Vector2:
		projectile_half_height = hitbox_scale.y * 0.5
	else:
		return false

	# Check the trajectory of each projectile.
	for offset in hitbox_offsets:
		var spawn_position: Vector2 = attacker_position + Vector2(
			offset.x * direction,
			offset.y
		)

		var horizontal_distance: float = (
			target_position.x - spawn_position.x
		) * direction

		if horizontal_distance < 0.0:
			continue

		var travel_time: float = horizontal_distance / float(speed)

		if hitbox_lifespan > 0.0 and travel_time > hitbox_lifespan:
			continue

		var predicted_y: float = (
			spawn_position.y
			+ float(y_velocity) * travel_time
			+ 0.5 * gravity * travel_time * travel_time
		)

		if absf(predicted_y - target_position.y) <= (
			projectile_half_height + target_half_height
		):
			return true

	return false
