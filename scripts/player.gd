extends CharacterBody2D


@onready var weapon_holder: Node2D = $WeaponHolder
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var checkpoint: Node2D = $"../Checkpoint"

#Player Stats
@export var speed: float = 200.0
@export var sprint_multiplier: float = 2.0
@export var dodge_distance: float = 200.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5
@export var attack_cooldown: float = 0.3

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
var boost_timer: float = 0.0

#Movement
var dodge_direction: Vector2
var is_dodging: bool = false
var dodge_time_left: float
var input_vector: Vector2 = Vector2.ZERO
var last_move_direction: Vector2
var boost_speed: float = 50.0
var received_boost: bool = false
var boost_time: float = 4.0

var is_invulnerable := false
var respawn_location: Marker2D


func _ready() -> void:
	if faction == Faction.PLAYER:
		hurtbox.set_collision_layer_value(5, true)
	state = PlayerState.MOVE
	set_respawn(1)


func _physics_process(_delta: float) -> void:
	input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		).normalized()
	var look_dir := Vector2.RIGHT.rotated(rotation)
	var look_target := global_position + look_dir * 100
	if state == PlayerState.MOVE:
		look_target = look_target.lerp(get_global_mouse_position(), 0.2)
		look_at(look_target)
	elif state == PlayerState.ATTACK:
		look_target = look_target.lerp(get_global_mouse_position(), 0.05)
		look_at(look_target)


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
	if received_boost:
		boost_timer = (max(0, boost_timer - delta))

	if boost_timer == 0.0 and received_boost:
		speed -= boost_speed
		received_boost = false

	if is_dodging:
		handle_dodge(delta)
		return

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
		anim.play("move")
		last_move_direction = input_vector.normalized() # Or set this to dodge left
	else:
		anim.play("RESET")
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
	apply_screen_shake()
	var tween = create_tween()
	tween.tween_property(weapon_holder, "position:x", 20, 0.1)  # Forward
	tween.tween_property(weapon_holder, "position:x", 0, 0.1)  # Back to rest
	anim.play("attack")


func handle_attack(delta):
	if attack_timer <= 0:
		weapon_holder.get_child(0).set_active(false)
		state = PlayerState.MOVE


func handle_dead():
	anim.play("die")


func _on_hurtbox_died() -> void:
	print("Player got hit")
	weapon_holder.get_child(0).set_active(false)
	apply_screen_shake()
	hit_stop(0.1, 0.15)
	state = PlayerState.DEAD


func apply_screen_shake(intensity: float = 8.0):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		camera.offset = shake_offset
		await get_tree().create_timer(0.1).timeout
		camera.offset = Vector2.ZERO


func hit_stop(duration: float = 0.05, slow_motion: float = 0.0) -> void:
	Engine.time_scale = slow_motion
	await get_tree().create_timer(duration).timeout
	await get_tree().process_frame
	Engine.time_scale = 1.0


func speed_boost() -> void:
	if not received_boost:
		received_boost = true
		boost_timer = boost_time
		speed += boost_speed
	else:
		return


func set_respawn(number: int) -> void:
	match number:
		1:
			respawn_location = $"../Districts/SpawnLocation1"
			checkpoint.global_position = respawn_location.global_position
		2:
			respawn_location = $"../Districts/SpawnLocation2"
			checkpoint.global_position = respawn_location.global_position
		3:
			respawn_location = $"../Districts/SpawnLocation3"
			checkpoint.global_position = respawn_location.global_position


func reset_position() -> void:
	anim.play("RESET")
	global_position = respawn_location.global_position
	state = PlayerState.MOVE
