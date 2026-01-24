extends Area2D
class_name Hurtbox

signal died()

func take_damage() -> void:
	var parent = get_parent()
	if parent.is_in_group("player") and parent.is_invulnerable:
		print("Dodged death!")
		parent.speed_boost()
		return
	died.emit()
