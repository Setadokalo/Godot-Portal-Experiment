tool
extends Position3D

const AABB_HALF_SIZE := Vector3(0.01, 0.01, 0.01)

var old_gtransform : Transform

var intersecting_objects: Array

func _process(delta: float) -> void:
	if old_gtransform != global_transform:
		old_gtransform = global_transform
		
		var aabb: AABB
		if get_parent() is MeshInstance:
			aabb = (get_parent() as MeshInstance).get_transformed_aabb()
		else:
			aabb = AABB(global_transform.origin - AABB_HALF_SIZE, AABB_HALF_SIZE)
		for object in get_tree().get_nodes_in_group("clippable"):
			assert(object is MeshInstance)
			var mesh := object as MeshInstance
			set_mesh_clip_planes(aabb, mesh)
		for object in intersecting_objects:
			print(object)
			object.set_clip(global_transform.origin, -global_transform.basis.z)

func set_mesh_clip_planes(aabb: AABB, mesh: MeshInstance):
	print(mesh.get_transformed_aabb(), aabb)
	if mesh.get_transformed_aabb().intersects(aabb):
		print("intersects")
		for surface_idx in mesh.get_surface_material_count():
			var mat: ShaderMaterial = mesh.get_active_material(surface_idx)
			assert(mat)
			mat.set_shader_param("plane_pos", global_transform.origin)
			mat.set_shader_param("plane_normal", -global_transform.basis.z)


func _on_Area_body_entered(body: Node) -> void:
	if body.has_method("set_clip") and not intersecting_objects.has(body):
		print(body)
		intersecting_objects.append(body)
		body.set_clip(global_transform.origin, -global_transform.basis.z)


func _on_Area_body_exited(body: Node) -> void:
	if intersecting_objects.has(body):
		intersecting_objects.erase(body)
		body.set_clip(global_transform.origin, Vector3.ZERO)
