extends GutTest

var _player = Player.new("Player", 1, 100, 300)
var _inventory = null;

func before_each():
	gut.p("Creating empty inventory for player")
	_inventory = Inventory.new(_player)
	_player.inventory = _inventory
	
func after_each():
	gut.p("Removing inventory from player")
	_player.inventory = null
	_inventory = null
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
	
