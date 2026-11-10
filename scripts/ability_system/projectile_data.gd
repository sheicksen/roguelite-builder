class_name ProjectileData extends AbilityData
## Extension of AbilityData class. Manages additional data specific to projectiles,
## including projectile speed, gravity applied, and initial upwards momentum (negative).
@export var speed: int = 700 # Projectile speed
@export var gravity: float = 0 # Gravity, or anti gravity (if negative), applied to projectile
@export var y_velocity = 0 # Upwards momentum (Should be negative if projectile is to go up)
