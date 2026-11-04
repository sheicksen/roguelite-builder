class_name BaseAbility extends Node

var stats: AttackStats
var icon: String       # Path to Icon

var cooldown_timer: Timer
var is_ready: bool
var cool_down: float


# Hitbox info
var attack_shape: Shape2D
var attack_lifespan: float
var emit_signal: bool 


func _init(
	_name:String, 
	_icon:String, 
	_stats:AttackStats,
	_shape:Shape2D, 
	_cool_down: float = 3.0,
	_lifespan: float = 0.0,
	_emit_signal = false
	) -> void:
	name = _name
	stats = _stats
	attack_shape = _shape
	attack_lifespan = _lifespan
	emit_signal = _emit_signal
	cool_down = _cool_down
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(reset_cooldown)
	

func use_ability() -> void:
	if is_ready:
		is_ready = false
		var hitbox = Hitbox.new(stats, attack_lifespan, attack_shape, null, emit_signal)
		hitbox.name = "Attack_01"
		add_child(hitbox)
		cooldown_timer.call_deferred("start", cool_down)
		
		

func reset_cooldown() -> void:
	cooldown_timer.stop()
	is_ready = true
