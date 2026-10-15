extends Node

var myEntityStats: EntityStats = EntityStats.new("Test", 0, 100, 50)

func _ready() -> void:
	print("------- Current Entity Stats --------")
	print("Name: ", myEntityStats.name)
	print("Faction: ", myEntityStats.faction)
	print("Max Health: ", myEntityStats.max_health)
	print("Current Health: ",myEntityStats.health)
	print("Speed: ",myEntityStats.speed)
	print("Defense: ", myEntityStats.defense)
	print("Weight: ",myEntityStats.weight)
	print("Vulnerabilities: ", myEntityStats.vulnerability)
	print("Immunities: ", myEntityStats.immunity)
	print("Under Effects: ", myEntityStats.under_effects)
	print ("------ Test Methods -------")
	
	print("Take damage with no defense: ")
	print(myEntityStats.health, " - 20 = 80. ", myEntityStats.take_damage(20) == 80)
	
	print("Reset health: ")
	print(myEntityStats.health, " -> 100", myEntityStats.reset_health() == 100)
	
	print("Add defense: ")
	print("Defense added: ", myEntityStats.update_defense(10), myEntityStats.defense == 10)
	
	print("Take damage with 10 defense: ")
	print(myEntityStats.health, " - 20 = 90. ", myEntityStats.take_damage(20) == 90)
	
	print("Add vulnerability id 1: ")
	print(myEntityStats.add_vulnerability(1))
	
	print("Attempt to add redundant vulnerability 1: ")
	print(myEntityStats.add_vulnerability(1))

	print("Remove vulnerability 1: ")
	print(myEntityStats.remove_vulnerability(1))
	
	print("Remove vulnerability 1 that has already been removed: ")
	print(myEntityStats.remove_vulnerability(1))
