class_name BaseStats extends Resource
## Extends Resource. Used to enumerate damage types and factions, and enforce faction assignment.
enum DamageType { ## Enumeration of damage types
	DEFAULT,
	FIRE,
	POISON,
	ICE,
	CORRUPTED
}
enum Faction {  ## Enumeration of Factions
	DEFAULT,    ## 0
	PLAYER,     ## 1
	ENEMY,      ## 2
	ENVIRONMENT ## 3
}

var faction: int  ## Integer representation of Owner Faction
var name: String  ## Owner Name
func _init(_name:String = "Unknown", _faction: int = 0) -> void:
	faction = _faction
