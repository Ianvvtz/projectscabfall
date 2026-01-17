extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox

enum Faction {
	PLAYER,
	ENEMY
}

@export var faction: Faction

func _ready() -> void:
	if faction == Faction.ENEMY:
		hurtbox.set_collision_layer_value(4, true)


func _on_hurtbox_died() -> void:
	queue_free()
