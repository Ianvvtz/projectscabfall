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
	IDLE,
	CHASE,
	STRAFE,
	ATTACK,
	DEAD,
}

var current_behavior: Behavior = Behavior.IDLE
var behavior_timer: float = 0.0

var current_district: Area2D

var player: CharacterBody2D
var distance_to_player: float
@export var faction: Faction
@export var move_speed: float = 100.0
@export var strafe_speed: float = 70.0
@export var group_spacing: float = 100.0
@export var flank_offset_distance: float = 120.0
var current_group_offset: Vector2 = Vector2.ZERO
var current_flank_offset: Vector2 = Vector2.ZERO


# Attack variables
@export var attack_pause: float = 0.5
@export var attack_duration: float = 0.15
@export var chase_range: float = 200.0
var can_attack: bool = true
var attack_pause_timer: float = 0.0
var attack_range: float
var can_attack_range: float
var got_hit: bool = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if faction == Faction.ENEMY:
		hurtbox.set_collision_layer_value(4, true)
	if attack_range_box.get_child(0).get_shape() is RectangleShape2D:
		can_attack_range = attack_range_box.get_child(0).get_shape().size.x


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if current_behavior != Behavior.DEAD:
		look_at(player.global_position)
	ai_behavior(delta)


func ai_behavior(delta: float) -> void:
	distance_to_player = global_position.distance_to(player.global_position)

	match current_behavior:
		Behavior.IDLE:
			handle_idle()
		Behavior.CHASE:
			if distance_to_player <= can_attack_range and can_attack:
				enter_attack()
			else:
				if not distance_to_player < chase_range:
					behavior_timer -= delta
					if behavior_timer <= 0:
						behavior_timer = randf_range(2.0, 4.0)
						set_state(Behavior.STRAFE)
				chase_player(delta)
		Behavior.STRAFE:
			if distance_to_player <= can_attack_range and can_attack:
				enter_attack()
			else:
				behavior_timer -= delta
				if distance_to_player <= chase_range or behavior_timer <= 0:
					behavior_timer = randf_range(2.0, 4.0)
					set_state(Behavior.CHASE)
				strafe_attack(delta)
		Behavior.ATTACK:
			velocity = Vector2.ZERO
			handle_attack(delta)
		#Behavior.DEAD:
			#velocity = Vector2.ZERO
	move_and_slide()


func handle_idle() -> void:
	if distance_to_player < 800.0:
		behavior_timer = randf_range(2.0, 4.0)
		set_state(Behavior.CHASE)


func chase_player(_delta) -> void:
	var direction = (player.global_position - global_position).normalized()
	var desired_group_offset = compute_group_offset()
	var desired_flank_offset = compute_flank_offset()
	current_group_offset = current_group_offset.lerp(desired_group_offset, 0.1)
	current_flank_offset = current_flank_offset.lerp(desired_flank_offset, 0.1)
	direction = (player.global_position - global_position) + current_group_offset + current_flank_offset
	velocity = direction.normalized() * move_speed
	if velocity != Vector2.ZERO:
		
		anim.play("move")
	else:
		anim.play("RESET")


func strafe_attack(_delta) -> void:
	var to_player = player.global_position - global_position
	var perpendicular = Vector2(-to_player.y, to_player.x).normalized()
	var random_offset = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
	var strafe_direction = (perpendicular + random_offset).normalized()
	var desired_group_offset = compute_group_offset()
	var desired_flank_offset = compute_flank_offset()
	current_group_offset = current_group_offset.lerp(desired_group_offset, 0.1)
	current_flank_offset = current_flank_offset.lerp(desired_flank_offset, 0.1)
	var final_direction = (strafe_direction * strafe_speed + current_group_offset + current_flank_offset)
	velocity = final_direction.normalized() * strafe_speed

	if velocity != Vector2.ZERO:
		anim.play("move")
	else:
		anim.play("RESET")


func enter_attack() -> void:
	can_attack = false
	attack_pause_timer = attack_pause
	anim.play("attack_windup")
	set_state(Behavior.ATTACK)


func handle_attack(delta) -> void:
	attack_pause_timer -= delta
	if attack_pause_timer > 0:
		return
	anim.play("attack")


func exit_attack() -> void:
	hitbox.set_active(false)
	can_attack = true
	behavior_timer = randf_range(2.0, 4.0)
	set_state(Behavior.CHASE)


func set_state(new_state: Behavior) -> void:
	if current_behavior == new_state:
		return
	print("AI:", current_behavior, "→", new_state)
	current_behavior = new_state


func _on_hurtbox_died() -> void:
	if got_hit:
		return
	got_hit = true
	can_attack = false
	var hit_direction = (global_position - player.global_position).normalized()
	velocity = hit_direction * 100.0
	player.hit_stop(0.035, 0.3)
	anim.play("hit")
	set_state(Behavior.DEAD)
	await get_tree().create_timer(0.25).timeout
	velocity = Vector2.ZERO
	player.speed_boost()
	Signalbus.enemy_died.emit(current_district)


func enemy_die() -> void:
	queue_free()


func get_nearby_allies(radius: float = 100.0) -> Array:
	var allies = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or enemy.current_behavior == Behavior.DEAD:
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			allies.append(enemy)
	return allies


func compute_group_offset() -> Vector2:
	var offset = Vector2.ZERO
	var allies = get_nearby_allies(group_spacing * 2)
	for ally in allies:
		var dir = global_position - ally.global_position
		var distance = dir.length()
		if distance == 0:
			continue
		if distance < group_spacing:
			offset += dir.normalized() * (group_spacing - distance)
	return offset


func compute_flank_offset() -> Vector2:
	var to_player = (player.global_position - global_position).normalized()
	var perpendicular = Vector2(-to_player.y, to_player.x)
	var side = 1 if randf() < 0.5 else -1
	return perpendicular * side * randf_range(0, flank_offset_distance)


func _enable_collision():
	await get_tree().physics_frame
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
