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
var name: String
func _init(_name:String = "Unknown", _faction: int = 0) -> void:
	faction = _faction
