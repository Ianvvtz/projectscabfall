extends CharacterBody2D


@onready var weapon_holder: Node2D = $WeaponHolder
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Hurtbox = $Hurtbox

#Player Stats
const MAX_SPEED: int = 400
const ACCELERATION: int = 5
const FRICTION: int = 8
@export var speed: float = 200
@export var sprint_multiplier: float = 2.0
@export var dodge_distance: float = 200
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5
@export var health: int = 100
@export var attack_damage: int = 25
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
var input_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	if faction == Faction.PLAYER:
		hurtbox.set_collision_layer_value(5, true)
	state = PlayerState.MOVE


func _physics_process(_delta: float) -> void:
	input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		).normalized()


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


func handle_idle():
	anim.play("idle")
	if input_vector.length() > 0:
		state = PlayerState.MOVE
	elif Input.is_action_just_pressed("left_click"):
		start_attack()

func handle_move(delta) -> void:
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
	
	var lerp_weight = delta * ACCELERATION
	velocity = lerp(velocity, input_vector * current_speed, lerp_weight)
	move_and_slide()


func dodge():
	anim.play("dodge")
	dodge_timer = dodge_cooldown
	velocity = input_vector * dodge_distance / dodge_duration


func start_attack():
	state = PlayerState.ATTACK
	attack_timer = attack_cooldown
	weapon_holder.get_child(0).set_active(true)
	anim.play("attack")


func handle_attack(delta):
	if not anim.is_playing():
		weapon_holder.get_child(0).set_active(false)
		state = PlayerState.MOVE


func handle_dead():
	self.queue_free()


func _on_hurtbox_died() -> void:
	state = PlayerState.DEAD
