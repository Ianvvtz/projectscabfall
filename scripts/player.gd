extends CharacterBody2D


@onready var weapon_holder: Node2D = $WeaponHolder
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Hurtbox = $Hurtbox

#Player Stats
@export var speed: float = 200
@export var sprint_multiplier: float = 2.0
@export var dodge_distance: float = 200
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5
@export var attack_cooldown: float = 0.2

enum Faction {
	PLAYER,
	ENEMY
}

@export var faction: Faction

#State Machine
enum PlayerState {
	MOVE,
	ATTACK,
	DEAD,
}
var state: PlayerState = PlayerState.MOVE

#Timers
var attack_timer: float = 0.0
var dodge_timer: float = 0.0

#Movement
var dodge_direction: Vector2
var is_dodging: bool = false
var dodge_time_left: float
var input_vector: Vector2 = Vector2.ZERO
var last_move_direction: Vector2

var is_invulnerable := false


func _ready() -> void:
	if faction == Faction.PLAYER:
		hurtbox.set_collision_layer_value(5, true)
	state = PlayerState.MOVE


func _physics_process(_delta: float) -> void:
	input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		).normalized()
	look_at(get_global_mouse_position())


func _process(delta: float) -> void:
	attack_timer = max(0, attack_timer - delta)
	dodge_timer = max(0, dodge_timer - delta)
	match state:
		PlayerState.MOVE:
			handle_move(delta)
		PlayerState.ATTACK:
			handle_attack(delta)
		PlayerState.DEAD:
			handle_dead()


func handle_move(delta) -> void:
	if is_dodging:
		handle_dodge(delta)
		return
	
	anim.play("move")

	if Input.is_action_just_pressed("left_click") and attack_timer <= 0:
		start_attack()
		return
	elif Input.is_action_just_pressed("dodge") and dodge_timer <= 0:
		dodge()
		return
	
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed *= sprint_multiplier
	
	if input_vector != Vector2.ZERO:
		last_move_direction = input_vector.normalized() # Or set this to dodge left
	
	velocity = input_vector * current_speed
	move_and_slide()


func dodge():
	is_invulnerable = true
	anim.play("dodge")
	dodge_timer = dodge_cooldown
	is_dodging = true
	dodge_time_left = dodge_duration

	if input_vector != Vector2.ZERO:
		dodge_direction = input_vector.normalized()
	else:
		dodge_direction = last_move_direction


func handle_dodge(delta) -> void:
	dodge_time_left -= delta

	velocity = dodge_direction * (dodge_distance / dodge_duration)
	move_and_slide()

	if dodge_time_left <= 0:
		is_dodging = false
		is_invulnerable = false
		velocity = Vector2.ZERO


func start_attack():
	state = PlayerState.ATTACK
	attack_timer = attack_cooldown
	weapon_holder.get_child(0).set_active(true)
	anim.play("attack")


func handle_attack(delta):
	if attack_timer <= 0:
		weapon_holder.get_child(0).set_active(false)
		state = PlayerState.MOVE

func handle_dead():
	print("Player got hit")
	get_tree().paused = true
	# TODO handle death


func _on_hurtbox_died() -> void:
	state = PlayerState.DEAD
