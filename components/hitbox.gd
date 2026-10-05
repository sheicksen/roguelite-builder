class_name Hitbox
extends Area2D

@export var damage: float = 10.0
@export var damage_type: String = "physical"
@export var team: String = "neutral"
@export var target_teams: Array[String] = []
@export var tags: Array[String] = []
@export var effects: Array[HitEffect] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox

		if not _can_interact_with(hurtbox):
			return

		var hit_data := HitData.new(
			self,
			damage,
			damage_type,
			tags.duplicate(),
			effects.duplicate()
		)

		hurtbox.receive_hit(hit_data)

func _can_interact_with(hurtbox: Hurtbox) -> bool:
	if hurtbox.team == team:
		return false

	if not target_teams.is_empty():
		if hurtbox.team not in target_teams:
			return false

	return true
