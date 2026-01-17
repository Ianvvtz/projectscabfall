extends Area2D
class_name Hitbox


#var hitbox_lifetime: float
#var shape: Shape2D
#
## note: add hitbox logging
#
#func _init(_hitbox_lifetime: float, _shape: Shape2D) -> void:
	#hitbox_lifetime = _hitbox_lifetime
	#shape = _shape
#
#
func _ready() -> void:
	monitorable = false
	monitoring = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if get_parent().get_parent().is_in_group("player"):
		set_collision_mask_value(4, true)
	elif get_parent().get_parent().is_in_group("enemy"):
		set_collision_mask_value(5, true)

	#area_entered.connect(_on_area_entered)
	
	#if hitbox_lifetime > 0.0:
		#var new_timer = Timer.new()
		#add_child(new_timer)
		#new_timer.timeout.connect(queue_free)
		#new_timer.call_deferred("start", hitbox_lifetime)
	
	#if shape:
		#print(get_child(0))
		#shape = get_child(0).shape
		#print(shape)

#func _on_area_entered(area: Area2D) -> void:
	#pass

func set_active(boolean: bool) -> void:
	for child in get_children():
		if child is not CollisionShape2D:
			continue
		monitoring = boolean


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		area.take_damage()
