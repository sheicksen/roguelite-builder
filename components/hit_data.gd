class_name HitData
extends RefCounted

var source: Node
var damage: float = 0.0
var damage_type: String = "physical"
var tags: Array[String] = []
var effects: Array[HitEffect] = []


func _init(
	p_source: Node = null,
	p_damage: float = 0.0,
	p_damage_type: String = "physical",
	p_tags: Array[String] = [],
	p_effects: Array[HitEffect] = []
) -> void:
	source = p_source
	damage = p_damage
	damage_type = p_damage_type
	tags = p_tags
	effects = p_effects
