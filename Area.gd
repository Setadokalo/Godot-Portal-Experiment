extends Area




func _on_body_entered(body: Node) -> void:
	if body.has_method("respawn"):
		body.respawn()
