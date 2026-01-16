extends CharacterBody2D


@onready var weapon_holder: Node2D = $WeaponHolder
@onready var anim: AnimationPlayer = $AnimationPlayer

#Player Stats
const MAX_SPEED: int = 400
const ACCELERATION: int = 5
const FRICTION: int = 8
@export var speed: float = 200
@export var sprint_multiplier: float = 1.5
@export var dodge_distance: float = 150
@export var dodge_cooldown: float = 0.5
@export var health: int = 100
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.3

#State Machine
enum PlayerState {
	IDLE,
	MOVE,
	ATTACK,
	RELOAD,
	DEAD,
}
var state: PlayerState = PlayerState.IDLE

#Timers
var attack_timer: float = 0.0
var dodge_timer: float = 0.0

#Movement
var input_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	state = PlayerState.IDLE


func _physics_process(_delta: float) -> void:
	input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		).normalized()


func _process(delta: float) -> void:
	match state:
		PlayerState.IDLE:
			handle_idle()
		PlayerState.MOVE:
			handle_move(delta)
		PlayerState.ATTACK:
			handle_attack()
		PlayerState.RELOAD:
			handle_reload()
		PlayerState.DEAD:
			handle_dead()


func handle_idle():
	anim.play("idle")
	if input_vector.length() > 0:
		state = PlayerState.MOVE
	elif Input.is_action_just_pressed("left_click"):
		start_attack()


func handle_move(delta) -> void:
	anim.play("move")
	velocity = input_vector * speed
	if input_vector.length() == 0:
		state = PlayerState.IDLE
	elif Input.is_action_just_pressed("left_click"):
		start_attack()
	elif Input.is_action_just_pressed("dodge") and dodge_timer <= 0:
		anim.play("dodge")
		dodge()
	elif Input.is_action_pressed("sprint"):
		anim.play("sprint")
		velocity *= sprint_multiplier
	var lerp_weight = delta * (ACCELERATION if input_vector else FRICTION)
	velocity = lerp(velocity, input_vector * MAX_SPEED, lerp_weight)
	move_and_slide()


func dodge():
	velocity *= dodge_distance
	dodge_timer = dodge_cooldown


func handle_attack():
	pass


func handle_reload():
	pass


func handle_dead():
	pass


func start_attack():
	pass
