class_name Inventory extends Resource
## Resource for tracking coins, corruptions, Items which modify stats, and ability data
## Updates the owners stats and ability list upon item pickup
@export var coins: int = 0
@export var corruption: int = 0
@export var pickups: Array[Item] = []
@export var ability_stats: Array[AbilityData] = [NullAbilityConfig.new(),NullAbilityConfig.new(),NullAbilityConfig.new()]

var owner: Node2D
var owner_stats: EntityStats

func _init(_owner:Node2D) -> void:
	if "stats" in _owner:
		owner = _owner
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
				if item.target_stats[i] != "health":
					modify_stat(item.target_stats[i], -1 * item.amounts[i])
			pickups.erase(item)

func modify_stat(target, amount):
	match target:
		"max_health":
			owner_stats.modify_max_health(owner_stats.max_health + amount)
		"defense":
			owner_stats.update_defense(owner_stats.defense + amount)
		"speed":
			owner_stats.modify_speed(amount)
		"weight":
			owner_stats.update_weight(owner_stats.weight + amount)
	
	if target == "health":
		if amount < 0:
			owner_stats.take_damage(amount * -1)
		else:
			owner_stats.heal(amount)
	elif target == "immunity":
		if amount < 1:
			owner_stats.remove_immunity(amount * -1)
		else:
			owner_stats.add_immunity(amount)
	elif target == "vulnerability":
		if amount < 1:
			owner_stats.remove_vulnerability(amount * -1)
		else:
			owner_stats.add_vulnerability(amount)

func assign_ability(ability_data:AbilityData, slot:int) -> void:
	if slot < 1 or slot > 3:
		push_error("Valid ability slots are 1, 2, and 3.")
		return
		
	ability_stats.remove_at(slot - 1)
	ability_stats.insert(slot - 1, ability_data)
	
	if owner.has_method("update_abilities"):
		owner.update_abilities()
	
func add_coins(amount: int) -> int:
	if amount < 0:
		push_error("Cannot gain negative amount of coins.")
		return -1
	coins += amount
	return coins

func spend_coins(amount: int) -> int:
	if amount < 0:
		push_error("Cannot spend negative amount of coins.")
		return -1
	
	coins -= amount
	if coins < 0:
		coins = 0
	return coins

func gain_corruption(amount: int) -> int:
	if amount < 0: 
		push_error("Cannot gain negative corruption")
		return -1
	
	corruption += amount
	return corruption
	
func reduce_corruption(amount: int) -> int:
	if amount < 0: 
		push_error("Cannot reduce by negative corruption.")
		return -1
	
	corruption -= amount
	if corruption < 0:
		corruption = 0
	return corruption
