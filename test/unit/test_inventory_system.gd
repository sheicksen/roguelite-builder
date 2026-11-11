extends GutTest

var _player = null;

func before_each():
	gut.p("Creating empty inventory for player")
	_player = Player.new("Player", 1, 100, 300)
	
func after_each():
	gut.p("Removing inventory from player")
	#_inventory = null
	_player.free()
	assert_no_new_orphans()

func test_health_item():
	gut.p("Have player take 20 points of damage")
	_player.stats.take_damage(20)
	assert_eq(_player.stats.health, 80, "Player health should be 80 after taking damage")
	var health_item = Item.new("Health Potion", ["health"], [20])
	
	_player.inventory.add_item(health_item)
	assert_has(_player.inventory.pickups, health_item)
	assert_eq(_player.stats.health, 100, "Player should be at 100 hp after acquiring potion")
	
func test_damaging_item():
	gut.p("Create item that damages health")
	var poison_item = Item.new("Poison Potion", ["health"], [-20])
	_player.inventory.add_item(poison_item)
	assert_has(_player.inventory.pickups, poison_item)
	assert_eq(_player.stats.health, 80, "Player should be at 80 hp after acquiring potion")

func test_defense_item_pickup():
	var defense_item = Item.new("Shield", ["defense"], [10])
	_player.inventory.add_item(defense_item)
	assert_has(_player.inventory.pickups, defense_item)
	assert_eq(_player.stats.defense, 10, "Player should have 10 defense after picking up shield.")

func test_defense_item_remove():
	var defense_item = Item.new("Shield", ["defense"], [10])
	_player.inventory.add_item(defense_item)
	assert_has(_player.inventory.pickups, defense_item)
	_player.inventory.remove_item("Shield")
	assert_does_not_have(_player.inventory.pickups, defense_item)
	assert_eq(_player.stats.defense, 0, "Player should have no defense after losing shield.")

func test_defense_item_duplicate():
	var defense_item_1 = Item.new("Shield", ["defense"], [10])
	var defense_item_2 = Item.new("Shield", ["defense"], [10])
	_player.inventory.add_item(defense_item_1)
	_player.inventory.add_item(defense_item_2)
	assert_has(_player.inventory.pickups, defense_item_1)
	assert_has(_player.inventory.pickups, defense_item_2)
	assert_eq(_player.stats.defense, 20, "Player should have 20 total defense")
	_player.inventory.remove_item("Shield")
	assert_eq(len(_player.inventory.pickups), 1)
	assert_eq(_player.stats.defense, 10, "Player should have 10 defense after losing shield.")

func test_immunity_item_pickup():
	var immunity_item = Item.new("Antidote", ["immunity"], [BaseStats.DamageType.POISON])
	_player.inventory.add_item(immunity_item)
	assert_has(_player.inventory.pickups, immunity_item)
	assert_has(_player.stats.immunity, BaseStats.DamageType.POISON)

func test_immunity_item_loss():
	var immunity_item = Item.new("Antidote", ["immunity"], [BaseStats.DamageType.POISON])
	_player.inventory.add_item(immunity_item)
	assert_has(_player.inventory.pickups, immunity_item)
	assert_has(_player.stats.immunity, BaseStats.DamageType.POISON)
	_player.inventory.remove_item("Antidote")
	assert_does_not_have(_player.inventory.pickups, immunity_item)
	assert_does_not_have(_player.stats.immunity, BaseStats.DamageType.POISON)

func test_multistat_item_pickup():
	var multistat_item = Item.new("Overcharge", ["max_health", "defense", "immunity"], [100, 20, BaseStats.DamageType.CORRUPTED])
	_player.inventory.add_item(multistat_item)
	assert_has(_player.inventory.pickups, multistat_item)
	assert_eq(_player.stats.max_health, 200)
	assert_eq(_player.stats.defense, 20)
	assert_has(_player.stats.immunity, BaseStats.DamageType.CORRUPTED)

func test_multistat_item_drop():
	var multistat_item = Item.new("Overcharge", ["max_health", "defense", "immunity"], [100, 20, BaseStats.DamageType.CORRUPTED])
	_player.inventory.add_item(multistat_item)
	_player.inventory.remove_item("Overcharge")
	
	assert_does_not_have(_player.inventory.pickups, multistat_item)
	assert_eq(_player.stats.max_health, 100)
	assert_eq(_player.stats.defense, 0)
	assert_does_not_have(_player.stats.immunity, BaseStats.DamageType.CORRUPTED)

func test_remove_non_existent_item():
	_player.inventory.remove_item("Bob")

	
