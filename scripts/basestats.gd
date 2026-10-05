class_name BaseStats extends Resource
enum DamageType {
	DEFAULT
}
enum Faction {
	ENEMY,
	PLAYER,
	ENVIRONMENT
}

var faction: int

func _init(_faction: int = 0) -> void:
	faction = _faction
