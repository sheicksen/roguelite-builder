class_name AbilityData extends Resource
## A class managing all data related to an ability's Attack stats, appearance,
## hitbox shape, placement, and behavior, cooldown time, corruption stat,
## and ability to pierce enemies.

@export var name: String = "Base" # Name of ability
@export var stats: AttackStats = AttackStats.new( 
	10, # Damage
	0,  # Damage Type (Default)
	[BaseStats.Faction.ENEMY] # Target
)
@export var icon: String # Appearance on the ground / in the GUI NOT IMPLEMENTED
@export var sprite: String # Name of animation/sprite when used
@export var sprite_scale: Vector2 = Vector2(0.3, 0.3) 
@export var sprite_rotation: float = 0.0
@export var sprite_offset: Vector2 = Vector2(0.0, 0.0)

@export var cool_down: float = 1.0 # Time it takes until the ability can be used again
@export var corrupted: bool = false # If ability is corrupted
@export var piercing: bool = true # If the ability can pass through targets

@export var shape: String = "Circle" # Shape of the hitbox(es)
@export var hitbox_scale = 7 # Size of hitbox(es): int if shape == Circle, Vector2 if shape == Rectangle
@export var hitbox_lifespan: float = 3.0 
@export var hitbox_count: int = 1 # Number of hitboxes that make up the attack
@export var hitlog: bool = true # Use hitlog
@export var do_emit_signal = false # Emit signal when hitbox contacts a target
@export var hitbox_offsets: Array[Vector2] = [Vector2(10, 0)] # Vector of hitbox offsets

@export var description: String = ""
