extends Panel

export var get_func: String = "get_health"

func _process(_delta: float) -> void:
	var player = get_parent().get_parent() as Player
	if player:
		var val = player.call(get_func)
		$Label.text = String(val)
		var bar = $Bar as Range
		if bar:
			bar.value = val
