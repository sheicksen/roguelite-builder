class_name HitEffect
extends Resource

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	SET
}

@export var property_name: StringName = &"health"
@export var operation: Operation = Operation.SUBTRACT
@export var value: float = 10.0
