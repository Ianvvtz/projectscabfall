extends Area2D

@onready var spawn_points: Node2D = $SpawnPoints

enum DistrictState {
	RED,
	CONTESTED,
	BLUE,
}

@export var enemy_scene: PackedScene
@export var enemies_to_clear: int = 10
@export var respawn_number: int = 1

var player: CharacterBody2D
var enemies: Array = []
var state: DistrictState = DistrictState.BLUE
var enemies_killed: int = 0
var spawn_points_group: Array = []


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	enemies = get_tree().get_nodes_in_group("enemy")
	spawn_points_group = spawn_points.get_children()
	Signalbus.enemy_died.connect(enemy_died)


func update_visuals() -> void:
	match state:
		DistrictState.BLUE:
			state = DistrictState.CONTESTED
		DistrictState.CONTESTED:
			state = DistrictState.RED
		DistrictState.RED:
			pass


func contest_district() -> void:
	if state == DistrictState.BLUE:
		update_visuals()
		spawn_enemies(enemies_to_clear)


func capture_district() -> void:
	if enemies_killed >= enemies_to_clear and state == DistrictState.CONTESTED:
		update_visuals()
		player.set_respawn(respawn_number)
		player.speed_increase()


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		print("player entered")
		contest_district()


func enemy_died(district):
	if district == self:
		print("correct district")
		enemies_killed += 1
		print(enemies_killed)
		capture_district()


func spawn_enemies(amount: int):
	var spawn_radius: float = 32.0
	for i in range(amount):
		var spawn_point: Marker2D = spawn_points_group.pick_random()
		var new_enemy = enemy_scene.instantiate()
		call_deferred("add_child", new_enemy)

		new_enemy.set_deferred("collision_layer", 0)
		new_enemy.set_deferred("collision_mask", 0)

		var angle := randf() * TAU
		var dist := randf() * spawn_radius
		var offset := Vector2(cos(angle), sin(angle)) * dist

		new_enemy.call_deferred("set_global_position", spawn_point.global_position + offset)
		new_enemy.current_district = self
		new_enemy.call_deferred("_enable_collision")
