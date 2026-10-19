extends GutTest

var _entity = null;

func before_each():
	gut.p("Created Entity with 100 HP, 50 Speed, 0 Defense")
	_entity = EntityStats.new("Test_Entity", 0, 100, 50)
	
func after_each():
	gut.p("Removing Entity reference")
	_entity = null
	assert_no_new_orphans()
	
func test_take_damage():
	gut.p("Taking 50 damage with No Defense")
	_entity.take_damage(50)
	assert_eq(_entity.health, 50, "Health should be 50")

func test_take_damage_with_defense():
	_entity.update_defense(10)
	assert_eq(_entity.defense, 10, "Defense should be 10")
	gut.p("Updated Defense to be 10")
	gut.p("Taking 50 damage with 10 Defense")
	_entity.take_damage(50)
	assert_eq(_entity.health, 60, "Health should be 60")

func test_add_immunity():
	gut.p("Adding an immunity to poison")
	_entity.add_immunity(BaseStats.DamageType.POISON)
	assert_has(_entity.immunity, BaseStats.DamageType.POISON)

func test_add_vulnerability():
	gut.p("Add a vulnerability to fire")
	_entity.add_vulnerability(BaseStats.DamageType.FIRE)
	assert_has(_entity.vulnerability, BaseStats.DamageType.FIRE)
	
