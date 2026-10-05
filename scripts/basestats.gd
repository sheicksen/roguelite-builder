class_name BaseStats extends Resource
enum DamageType {
	DEFAULT
}
enum Faction {
	DEFAULT,
	PLAYER,
	ENEMY,
	ENVIRONMENT
}

var faction: int

func _init(_faction: int = 0) -> void:
	faction = _faction
