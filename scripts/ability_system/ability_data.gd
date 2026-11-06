class_name AbilityData extends Resource

@export var name: String = "Base"
@export var stats: AttackStats = AttackStats.new(10, 0, [BaseStats.Faction.ENEMY])
@export var icon: String
@export var sprite: String
@export var sprite_scale: Vector2 = Vector2(0.3, 0.3)
@export var sprite_rotation: float = 0.0
@export var sprite_offset: Vector2 = Vector2(0.0, 0.0)

@export var cool_down: float = 1.0
@export var shape: String = "Circle"
@export var corrupted: bool = false

@export var hitbox_scale = 7
@export var hitbox_lifespan: float = 3.0
@export var hitbox_count: int = 1
@export var hitlog: bool = true
@export var hitbox_offsets: Array[Vector2] = [Vector2(10, 0)]
