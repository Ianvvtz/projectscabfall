extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $WeaponHolder/Hitbox
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var attack_range_box: Area2D = $AttackRangeBox

enum Faction {
	PLAYER,
	ENEMY
}

enum Behavior {
	CHASE,
	STRAFE,
	DEAD,
}

var current_behavior: Behavior = Behavior.CHASE
var behavior_timer: float = 0.0

var current_district: Area2D

var player: CharacterBody2D
var distance_to_player: float
@export var faction: Faction
@export var move_speed: float = 100.0
@export var strafe_speed: float = 70.0

# Attack variables
@export var attack_pause: float = 0.5
@export var attack_duration: float = 0.15
var can_attack: bool = true
var attack_pause_timer: float = 0.0
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_range: float
var can_attack_range: float
var chase_range: float = 200.0
var got_hit: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if faction == Faction.ENEMY:
		hurtbox.set_collision_layer_value(4, true)
	if hitbox.get_shape() is CircleShape2D:
		attack_range = hitbox.get_shape().radius
	elif hitbox.get_shape() is RectangleShape2D:
		attack_range = hitbox.get_shape().size.x
	if attack_range_box.get_child(0).get_shape() is RectangleShape2D:
		can_attack_range = attack_range_box.get_child(0).get_shape().size.x


func _on_hurtbox_died() -> void:
	if not got_hit:
		got_hit = true
	else:
		return
	Signalbus.enemy_died.emit(current_district)
	current_behavior = Behavior.DEAD
	player.speed_boost()
	can_attack = false
	anim.play("hit")
	print("Enemy got hit")


func enemy_die() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	ai_behavior(delta)
	if not current_behavior == Behavior.DEAD: 
		look_at(player.global_position)


func ai_behavior(delta):
	velocity = Vector2.ZERO
	distance_to_player = global_position.distance_to(player.global_position)
	
	if attack_pause_timer > 0 and can_attack:
		anim.play("attack_windup")
		windup_attack(delta)

	if not is_attacking:
		if distance_to_player <= can_attack_range and can_attack:
			start_attack()

	if not current_behavior == Behavior.DEAD: 
		behavior_timer -= delta
		if distance_to_player < chase_range:
			current_behavior = Behavior.CHASE
		if behavior_timer <= 0:
			current_behavior = Behavior.STRAFE if current_behavior == Behavior.CHASE else Behavior.CHASE
			behavior_timer = randf_range(2.0, 4.0)

	match current_behavior:
		Behavior.CHASE:
			chase_player(delta)
		Behavior.STRAFE:
			strafe_attack(delta)
		Behavior.DEAD:
			handle_death()

	move_and_slide()


func chase_player(_delta):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed


func strafe_attack(_delta):
	var to_player = player.global_position - global_position
	var perpendicular = Vector2(-to_player.y, to_player.x).normalized()
	var random_offset = Vector2(randf_range(-0.1,0.1), randf_range(-0.1,0.1))
	velocity = (perpendicular + random_offset).normalized() * strafe_speed


func windup_attack(delta):
	attack_pause_timer = max(0, attack_pause_timer - delta)
	if attack_pause_timer <= 0:
		anim.play("attack")
	return


func start_attack():
	print("Starting attack")
	if not can_attack:
		return
	is_attacking = true
	attack_pause_timer = attack_pause


func end_attack():
	is_attacking = false
	hitbox.set_active(false)


func handle_death() -> void:
	velocity = Vector2.ZERO
