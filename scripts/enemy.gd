extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var anim: AnimationPlayer = $AnimationPlayer

enum Faction {
	PLAYER,
	ENEMY
}

enum Behavior {
	CHASE,
	STRAFE,
}

var current_behavior: Behavior = Behavior.CHASE
var behavior_timer: float = 0.0

var player: CharacterBody2D
@export var faction: Faction
@export var move_speed: float = 100.0
@export var strafe_speed: float = 70.0

# Attack variables
@export var attack_pause: float = 0.5
@export var attack_duration: float = 0.15
@export var attack_cooldown: float = 0.6
var can_attack: bool = true
var attack_pause_timer: float = 0.0
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_range: float


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if faction == Faction.ENEMY:
		hurtbox.set_collision_layer_value(4, true)
	if hitbox.get_shape() is CircleShape2D:
		attack_range = hitbox.get_shape().radius
	elif hitbox.get_shape() is RectangleShape2D:
		var rect = hitbox.get_shape().extents
		attack_range = rect.length()


func _on_hurtbox_died() -> void:
	can_attack = false
	anim.play("hit")
	
	print("Enemy got hit")


func enemy_die() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	ai_behavior(delta)


func ai_behavior(delta):
	velocity = Vector2.ZERO

	if attack_pause_timer > 0 and can_attack:
		anim.play("attack_windup")
		attack_pause_timer -= delta
		if attack_pause_timer <= 0:
			hitbox.set_active(true)
		return

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
		return
	
	# Behavior
	behavior_timer -= delta
	if behavior_timer <= 0:
		current_behavior = Behavior.STRAFE if current_behavior == Behavior.CHASE else Behavior.CHASE
		behavior_timer = randf_range(2.0, 4.0)
	
	match current_behavior:
		Behavior.CHASE:
			chase_player(delta)
		Behavior.STRAFE:
			strafe_attack(delta)
	
	if not is_attacking and attack_timer <= 0:
		if global_position.distance_to(player.hurtbox.global_position) <= attack_range and can_attack:
			start_attack()
	move_and_slide()


#func attac_windup() -> void:
	


# --- Movement Functions ---
func chase_player(_delta):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed

func strafe_attack(_delta):
	var to_player = player.global_position - global_position
	var perpendicular = Vector2(-to_player.y, to_player.x).normalized()
	var random_offset = Vector2(randf_range(-0.1,0.1), randf_range(-0.1,0.1))
	velocity = (perpendicular + random_offset).normalized() * strafe_speed
	#velocity = perpendicular * move_speed * 0.7

# --- Attack Functions ---
func start_attack():
	if not can_attack:
		return
	is_attacking = true
	attack_pause_timer = attack_pause
	attack_timer = attack_duration
	# Play wind-up animation here
	#hitbox.set_active(true)
	# Optional: play attack animation here

func end_attack():
	is_attacking = false
	hitbox.set_active(false)
	attack_timer = attack_cooldown
