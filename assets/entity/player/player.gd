extends KinematicBody
class_name Player

var Movement := load("res://assets/entity/player/movement.gd")

var velocity := Vector3(0, 0, 0) setget , get_velocity

export var mouse_sensitivity := 1.0 setget , get_mouse_sensitivity

	
export var mouse_captured := true setget , is_mouse_captured

const ZOOM_FOV = 20
onready var original_fov := ($Camera as Camera).fov setget , get_original_fov


var jumping := false setget , is_jumping

var health := 100.0

func respawn():
	var respawn_pos := get_parent().get_node("PlayerSpawnPoint") as Spatial
	if respawn_pos:
		transform = respawn_pos.transform
	else:
		transform = Transform()
	velocity = Vector3.ZERO
	health = 100



func get_snap_vector(is_jumping: bool) -> Vector3:
	var snap := Vector3(0, -2, 0)
	if velocity.y < 0:
		jumping = false
	if is_jumping:
		jumping = true
	if not is_on_floor() or jumping:
			snap = Vector3.ZERO
	return snap

var m_delta: Vector2 = Vector2(0.0, 0.0)

func apply_cam_move():
	if mouse_captured:
		transform.basis = transform.basis.rotated(
			Vector3.UP, 
			deg2rad(m_delta.x * mouse_sensitivity * 0.1)
		)
		var b = $Camera.transform.basis.rotated(
			Vector3.RIGHT,
			deg2rad(m_delta.y * mouse_sensitivity * 0.1)
		)
		var e = b.get_euler()
		e.x = clamp(e.x, -PI/2, PI/2)
		$Camera.transform.basis = Basis(e)
	
	m_delta = Vector2.ZERO
	
func transition_to_fov(fov_target_radians: float, transition_time: float, delta: float) -> void:
	$Camera.fov = lerp($Camera.fov, fov_target_radians, delta / transition_time)
	
	

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		m_delta -= event.relative
	
func _process(delta: float) -> void:
	apply_cam_move()
	if Input.is_action_pressed("quit"):
		get_tree().quit(0)
	elif Input.is_action_just_pressed("mouse_free"):
		mouse_captured = !mouse_captured
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if Input.is_action_pressed("zoom"):
			transition_to_fov(ZOOM_FOV, 0.1, delta)
		else:
			if Input.is_action_pressed("sprint"):
				transition_to_fov(original_fov * 1.25, 0.1, delta)
			else:
				transition_to_fov(original_fov, 0.1, delta)

func take_damage(damage: float) -> void:
	health -= damage
	if health < 0.0:
		respawn()

func _physics_process(delta: float) -> void:
#	print(to_local(($RayCast as RayCast).get_collision_point()).y)
	var _jumping = Movement.apply_movement(self, delta)
	if _jumping:
		jumping = true
	elif velocity.y < 0:
		jumping = false
	Movement.apply_drag(self, delta)
#	var old_pos := transform.origin
#	var was_on_floor := is_on_floor()
	var new_velocity = move_and_slide_with_snap(velocity, get_snap_vector(jumping), Vector3.UP, true)
	
	var impact_speed = abs((velocity - new_velocity).y)
	if impact_speed > 20.0:
		take_damage(max((impact_speed - 20.0) * 3.0, 0.0))
	velocity = new_velocity


# getter functions

func is_mouse_captured() -> bool:
	return mouse_captured
func get_velocity() -> Vector3:
	return velocity
func get_mouse_sensitivity() -> float:
	return mouse_sensitivity
func get_original_fov() -> float:
	return original_fov
func is_jumping() -> bool:
	return jumping
func get_health() -> float:
	return health
