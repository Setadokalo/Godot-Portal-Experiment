extends Panel

export var get_func: String = "is_on_floor"

func _process(_delta: float) -> void:
	var player = get_parent().get_parent() as Player
	if player:
		$CheckBox.pressed = player.call(get_func)

