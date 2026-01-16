extends CanvasLayer
@onready var color_rect: ColorRect = $ColorRect
@onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0


func change_scene(scene: String):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 1, 1.0)
	tween.tween_property(texture_rect, "modulate:a", 1, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file('res://scenes/%s.tscn' % scene)
	get_tree().paused = false
	
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 0, 1.0)
	tween.tween_property(texture_rect, "modulate:a", 0, 1.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
