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
	
## VULNERABILITY TESTS
func test_add_vulnerability():
	gut.p("Add a vulnerability to fire")
	_entity.add_vulnerability(BaseStats.DamageType.FIRE)
	assert_has(_entity.vulnerability, BaseStats.DamageType.FIRE)

func test_duplicate_vulnerability():
	# Test adding a duplicate vulnerability to an entity's vulnerability list
	gut.p("Add vulnerability to fire twice to an entity")
	_entity.add_vulnerability(BaseStats.DamageType.FIRE)
	_entity.add_vulnerability(BaseStats.DamageType.FIRE)
	assert_has(_entity.vulnerability, BaseStats.DamageType.FIRE)
	var count = 0
	for i in _entity.vulnerability:
		if i == BaseStats.DamageType.FIRE:
			count += 1
	assert_eq(count, 1, "vulnerability list should only have instance of fire vulnerability")

func test_vulnerable_to_damage():
	gut.p("Adding vulnerability to FIRE")
	_entity.add_vulnerability(BaseStats.DamageType.FIRE)
	gut.p("Create fire attack that does 10 damage")
	var fire_attack: AttackStats = AttackStats.new(10, BaseStats.DamageType.FIRE, [0])
	gut.p("Deal fire attack damage to entity vulnerable to fire")
	var attack_damage = _entity.deal_attack_damage(fire_attack)
	assert_eq(attack_damage, 20, "Recieved damage should be 20, doubled by vulnerability")
	assert_eq(_entity.health, 80, "Entity should be at 80 HP, having taken 20 damage")
	

# IMMUNITY TESTS

func test_add_immunity():
	# Test adding an immunity to an entity's immunity list
	gut.p("Adding an immunity to poison")
	_entity.add_immunity(BaseStats.DamageType.POISON)
	assert_has(_entity.immunity, BaseStats.DamageType.POISON)

func test_add_duplicate_immunity():
	# Test adding a duplicate immunity to an entity's immunity list
	gut.p("Add immunity to fire twice to an entity")
	_entity.add_immunity(BaseStats.DamageType.FIRE)
	_entity.add_immunity(BaseStats.DamageType.FIRE)
	assert_has(_entity.immunity, BaseStats.DamageType.FIRE)
	var count = 0
	for i in _entity.immunity:
		if i == BaseStats.DamageType.FIRE:
			count += 1
	assert_eq(count, 1, "Immunity list should only have instance of fire immunity")
	
func test_immunity_to_damage():
	gut.p("Take damage from a type that you're immune to")
	
	gut.p("Creating POISON attack that does 10 damage")
	var poison_attack: AttackStats = AttackStats.new(10, BaseStats.DamageType.POISON, [0])
	gut.p("Adding Poison Immunity")
	_entity.add_immunity(BaseStats.DamageType.POISON)
	_entity.deal_attack_damage(poison_attack)
	gut.p("Deal poison attack damage to entity")
	assert_eq(_entity.health, _entity.max_health, "Entity should still be at max health")
	

	
	
