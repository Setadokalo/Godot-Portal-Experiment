extends Node

static func apply_movement(player: Player, delta: float) -> bool:
	var raw_input := Vector3(0, 0, 0)
	raw_input.z -= Input.get_action_strength("move_forward")
	raw_input.z += Input.get_action_strength("move_back")
	
	raw_input.x += Input.get_action_strength("move_right")
	raw_input.x -= Input.get_action_strength("move_left")
	
	var effective_input := player.transform.basis * raw_input
	effective_input.y = 0
#	print(effective_input)
	effective_input = effective_input.normalized()
	player.velocity.y -= 9.8 * delta
	var applied_input := Vector3(0, 0, 0)
	var is_jumping := false
	if player.is_on_floor():
		applied_input = effective_input * 40
		if Input.is_action_just_pressed("jump"):
			applied_input.y += 400
			is_jumping = true
	else:
		applied_input = effective_input * 4
	if Input.is_action_pressed("sprint"):
		applied_input *= 2.0
	
	player.velocity += applied_input * delta
	return is_jumping

static func apply_drag(player: Player, delta: float) -> void:
	if player.is_on_floor():
		var drag_velocity := player.velocity * Vector3(delta * 5, 0, delta * 5)
		player.velocity -= drag_velocity
	else:
		var drag_velocity := player.velocity * Vector3(delta / 2, 0, delta / 2)
		player.velocity -= drag_velocity
