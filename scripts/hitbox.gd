extends Area2D
class_name Hitbox

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitorable = false
	monitoring = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if get_parent().get_parent().is_in_group("player"):
		set_collision_mask_value(4, true)
	elif get_parent().get_parent().is_in_group("enemy"):
		set_collision_mask_value(5, true)


func set_active(boolean: bool) -> void:
	for child in get_children():
		if child is not CollisionShape2D:
			continue
		monitoring = boolean


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		area.take_damage()


func get_shape() -> Shape2D:
	return collision_shape.shape
