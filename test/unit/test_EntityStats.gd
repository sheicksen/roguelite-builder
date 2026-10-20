extends GutTest

var _entity = null;

func before_each():
	gut.p("Created Entity with 100 HP, 50 Speed, 0 Defense")
	_entity = EntityStats.new("Test_Entity", 0, 100, 50)
	
func after_each():
	gut.p("Removing Entity reference")
	_entity = null
	assert_no_new_orphans()

## Basic health modifications
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

func test_negative_damage():
	gut.p("Pass illegal negative damage value")
	_entity.take_damage(-10)
	assert_push_error("Cannot do negative damage.")
	
func test_heal():
	gut.p("Take 90 damage")
	_entity.take_damage(90)
	assert_eq(_entity.health, 10, "Entity took 90 damage, should have 10 HP remaining")
	gut.p("Heal 50hp")
	_entity.heal(50)
	assert_eq(_entity.health, 60, "Entity should have 60 HP after healing for 50")
	
func test_over_heal():
	gut.p("Take 30 damage")
	_entity.take_damage(30)
	gut.p("Heal 50hp")
	_entity.heal(50)
	assert_eq(_entity.health, _entity.max_health, "Entity should be at max hp")

func test_negative_heal():
	gut.p("Pass illegal healing amount: -10")
	_entity.heal(-10)
	assert_push_error("Cannot heal a negative amount of health.")
	
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
	var damage_taken = _entity.deal_attack_damage(poison_attack)
	assert_eq(damage_taken, 0, "Entity should have taken 0 damage")
	gut.p("Deal poison attack damage to entity")
	assert_eq(_entity.health, _entity.max_health, "Entity should still be at max health")
	

	
	
