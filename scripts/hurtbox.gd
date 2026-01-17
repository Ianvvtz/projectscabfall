extends Area2D
class_name Hurtbox

signal died()

func take_damage() -> void:
	print("Took damage")
	died.emit()
