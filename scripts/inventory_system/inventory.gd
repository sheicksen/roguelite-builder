class_name Inventory extends Resource
@export var coins: int = 0
@export var corruption: int = 0
@export var pickups: Array[Item] = []
@export var ability_1: AbilityData = NullAbilityConfig.new()
@export var ability_2: AbilityData = NullAbilityConfig.new()
@export var ability_3: AbilityData = NullAbilityConfig.new()

var owner_stats: EntityStats

func _init(_owner:Node2D) -> void:
	if "stats" in _owner:
		owner_stats = _owner.stats
	else:
		push_error("Node must have EntityStats to use inventory.")

func add_item(item:Item)->void:
	pickups.append(item)
	for i in item.target_stats.size():
		modify_stat(item.target_stats[i], item.amounts[i])

func remove_item(item_name: String) -> void:
	for item in pickups:
		if item.name == item_name:
			for i in item.target_stats.size():
				modify_stat(item.target_stats[i], -1 * item.amounts[i])
			pickups.erase(item)

func modify_stat(target, amount):
	match target:
		"max_health":
			owner_stats.modify_max_health(owner_stats.max_health + amount)
		"health":
			owner_stats.heal(amount)
		"defense":
			owner_stats.update_defense(owner_stats.defense + amount)
		"speed":
			owner_stats.modify_speed(amount)
		"weight":
			owner_stats.update_weight(owner_stats.weight + amount)
	
	if target == "immunity":
		if amount < 1:
			owner_stats.remove_immunity(amount * -1)
		else:
			owner_stats.add_immunity(amount)
	elif target == "vulnerability":
		if amount < 1:
			owner_stats.remove_vulnerability(amount * -1)
		else:
			owner_stats.add_vulnerability(amount)

func assign_ability_1(ability_data:AbilityData) -> void:
	ability_1 = ability_data

func assign_ability_2(ability_data:AbilityData) -> void:
	ability_2 = ability_data

func assign_ability_3(ability_data:AbilityData) -> void:
	ability_3 = ability_data
