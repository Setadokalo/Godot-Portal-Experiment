extends StaticBody


export var OtherPortal: NodePath

var other_portal: StaticBody
var other_camera: Camera

func _ready() -> void:
	yield(get_tree(), "idle_frame")
	other_portal = get_node(OtherPortal)
	other_camera = other_portal.get_node("Viewport/Camera")
	var view_tex := (other_portal.get_node("Viewport") as Viewport).get_texture()
	$MeshInstance.get_active_material(0).set_shader_param("viewport_tex", view_tex)

func _process(delta: float) -> void:
	var ctrans := get_viewport().get_camera().global_transform
	var local_origin := global_transform.xform_inv(ctrans.origin) as Vector3
	ctrans.origin = other_portal.global_transform.xform(local_origin * Vector3(1, 1, -1))
#	var cbasscale: Vector3 = ctrans.basis * 
	if get_viewport().size != $Viewport.size:
		$Viewport.size = get_viewport().size
	ctrans.basis = ctrans.basis.scaled(Vector3(1, 1, -1))
	
	$Viewport/Camera.fov = get_viewport().get_camera().fov
	$Viewport/Camera.frustum_offset = get_viewport().get_camera().frustum_offset
	$Viewport/Camera.h_offset = get_viewport().get_camera().h_offset
	$Viewport/Camera.v_offset = get_viewport().get_camera().v_offset
	$Viewport/Camera.size = get_viewport().get_camera().size
	$Viewport/Camera.projection = get_viewport().get_camera().projection
	
	other_camera.global_transform = ctrans
	other_camera.global_transform.basis.y *= -1
#	$Viewport/Camera
