extends Node2D

@onready var spawn_light: PointLight2D = $PointLight2D


func _ready() -> void:
	var spawn_tween = create_tween().set_loops()
	spawn_tween.tween_property(spawn_light, "energy", 5.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	spawn_tween.parallel().tween_property(spawn_light, "texture_scale", 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	spawn_tween.tween_property(spawn_light, "energy", 3.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	spawn_tween.parallel().tween_property(spawn_light, "texture_scale", 6.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	
	var border_lights = get_tree().get_nodes_in_group("border_lights")
	for i in border_lights:
		var border_tween = create_tween().set_loops()
		border_tween.tween_property(i, "energy", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		border_tween.parallel().tween_property(i, "texture_scale", 2.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		border_tween.tween_property(i, "energy", 0.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		border_tween.parallel().tween_property(i, "texture_scale", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
