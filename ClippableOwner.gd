tool
extends RigidBody

export var clippable_mesh_children: Array

func set_clip(clip_pos: Vector3, clip_normal: Vector3) -> void:
	for mesh_path in clippable_mesh_children:
		var mesh = get_node(mesh_path)
		for surface_idx in mesh.get_surface_material_count():
			var mat: ShaderMaterial = mesh.get_active_material(surface_idx)
			assert(mat)
			mat.set_shader_param("plane_pos", clip_pos)
			mat.set_shader_param("plane_normal", clip_normal)
