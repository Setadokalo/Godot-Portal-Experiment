extends Panel


func _process(_delta: float) -> void:
	var player := get_parent().get_parent() as Player
	if player:
		var vel := player.get_velocity()
		var text: String = "Velocity: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z]
		
		($Label as Label).text = text

