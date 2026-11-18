#class_name Projectile extends Node2D
### Flies in a straight line and damages the player on contact.
#
#var direction: Vector2
#var speed: float
#var lifetime: float
#var size: Vector2
#
#func _init(_direction: Vector2, _speed: float = 150.0, _damage: int = 1, _lifetime: float = 3.0, _size: Vector2 = Vector2(6, 6)) -> void:
	#direction = _direction
	#speed = _speed
	#damage = _damage
	#lifetime = _lifetime
	#size = _size
#
#func _ready() -> void:
	#var attack := AttackStats.new(damage, BaseStats.DamageType.DEFAULT, [1])  # layer 1 = player
#
	#var shape := RectangleShape2D.new()
	#shape.size = size
#
	## emit_signal = true so we get hit_made and can disappear on impact
	#var hitbox := Hitbox.new(attack, 0.0, shape, null, true)
	#hitbox.hit_made.connect(_on_hit_made)
	#add_child(hitbox)
#
	## Safety net: despawn if it never hits anything
	#get_tree().create_timer(lifetime).timeout.connect(queue_free)
	#queue_redraw()
#
#func _physics_process(delta: float) -> void:
	#position += direction * speed * delta
#
#func _on_hit_made(_attacker, _target) -> void:
	#queue_free()
#
#func _draw() -> void:
	## Placeholder visual. Delete this and add a Sprite2D when you have art.
	#draw_circle(Vector2.ZERO, size.x, Color.ORANGE_RED)
