extends Area2D
class_name Hurtbox

signal died()

func take_damage() -> void:
	var parent = get_parent()
	if parent.is_invulnerable:
		print("Dodged death!")
		return
	died.emit()
