extends Node2D

@onready var spawn_light: PointLight2D = $PointLight2D


func _ready() -> void:
	var spawn_tween = create_tween().set_loops()
	spawn_tween.tween_property(spawn_light, "energy", 2.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	spawn_tween.parallel().tween_property(spawn_light, "texture_scale", 2.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	spawn_tween.tween_property(spawn_light, "energy", 1.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	spawn_tween.parallel().tween_property(spawn_light, "texture_scale", 1.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
