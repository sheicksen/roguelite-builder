class_name AbilityData extends Resource

@export var stats: AttackStats = AttackStats.new(10, 0, [0])
@export var icon: String = "res://icon.svg"
@export var cool_down: float = 3.0
@export var shape: String = "Circle"

@export var hitbox_scale = 10
@export var hitbox_lifespan: float = 1.0
@export var hitbox_count: int = 1
@export var hitlog: bool = false
@export var emit_signal: bool = false
@export var hitbox_offsets: Array[Vector2] = [Vector2(20, 0)]
