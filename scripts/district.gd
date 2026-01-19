extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer

enum DistrictState {
	RED,
	CONTESTED,
	BLUE,
}

@export var enemies_to_clear: int = 10

var player: CharacterBody2D
var enemies: Array = []
var state: DistrictState = DistrictState.BLUE
var enemies_killed: int = 0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	enemies = get_tree().get_nodes_in_group("enemy")
	Signalbus.enemy_died.connect(enemy_died)
	


#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("reload"):
		#update_visuals()


func update_visuals() -> void:
	match state:
		DistrictState.BLUE:
			anim.play("change_to_yellow")
			state = DistrictState.CONTESTED
		DistrictState.CONTESTED:
			anim.play("change_to_red")
			state = DistrictState.RED
		DistrictState.RED:
			pass


func contest_district() -> void:
	if state == DistrictState.BLUE:
		update_visuals()


func capture_district() -> void:
	if enemies_killed >= enemies_to_clear and state == DistrictState.CONTESTED:
		update_visuals()


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		print("player entered")
		contest_district()
	elif body in enemies:
		body.current_district = self

func enemy_died(district):
	if district == self:
		print("correct district")
		enemies_killed += 1
		print(enemies_killed)
		capture_district()
