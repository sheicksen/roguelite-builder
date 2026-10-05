class_name Hurtbox
extends Area2D

signal hit_received(hit_data: HitData)

@export var team: String = "neutral"
@export var enabled: bool = true


func receive_hit(hit_data: HitData) -> void:
	if not enabled:
		return

	_apply_effects(hit_data.effects)

	hit_received.emit(hit_data)


func _apply_effects(effects: Array[HitEffect]) -> void:
	var target := get_parent()

	for effect in effects:
		if not _has_property(target, effect.property_name):
			push_warning(
				"Property '%s' does not exist on %s"
				% [effect.property_name, target.name]
			)
			continue

		var current_value = target.get(effect.property_name)

		match effect.operation:
			HitEffect.Operation.ADD:
				target.set(
					effect.property_name,
					current_value + effect.value
				)

			HitEffect.Operation.SUBTRACT:
				target.set(
					effect.property_name,
					current_value - effect.value
				)

			HitEffect.Operation.MULTIPLY:
				target.set(
					effect.property_name,
					current_value * effect.value
				)

			HitEffect.Operation.SET:
				target.set(
					effect.property_name,
					effect.value
				)


func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.name == property_name:
			return true
			
	return false
