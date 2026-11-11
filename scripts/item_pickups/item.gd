class_name Item extends Resource
# A class which manages the stat changes caused by general item pickups


@export var name: String
@export var target_stats: Array[String]
@export var amounts: Array[int]
@export var corruption: int
@export var ability_stats: AbilityData = null

var allowed_stats = [ # list of stats that could be changed in EntityStats
	"max_health", 
	"health",
	"defense", 
	"normal_speed", 
	"immunity", 
	"vulnerability",
	"weight",
	"under_effects"
]

func _init(_name:String, _target_stats:Array[String], _change_amounts: Array[int], _corruption:int = 0, _ability_data = null) -> void:
	for stat in _target_stats: # Check that there are no illegal, game breaking target stats
		if not stat in allowed_stats:
			push_error("Cannot target stat which does not exist")
			return
	name = _name
	target_stats = _target_stats
	amounts = _change_amounts
	corruption = _corruption
	ability_stats = _ability_data
	
	
	
