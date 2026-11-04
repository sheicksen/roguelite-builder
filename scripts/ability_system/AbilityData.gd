class_name AbilityData extends Resource

@export var name: String = "Base"
@export var stats: AttackStats = AttackStats.new(10, 0, [BaseStats.Faction.ENEMY])
@export var icon: String = "res://icon.svg"
@export var cool_down: float = 1.0
@export var shape: String = "Circle"

@export var hitbox_scale = 10
@export var hitbox_lifespan: float = 0.5
@export var hitbox_count: int = 2
@export var hitlog: bool = true
@export var emit_signal: bool = false
@export var hitbox_offsets: Array[Vector2] = [Vector2(20, 0), Vector2(10, 10)]
