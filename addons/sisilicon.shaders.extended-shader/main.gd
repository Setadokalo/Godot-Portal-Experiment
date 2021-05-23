tool
extends EditorPlugin

const ExtendedShader = preload("ExtendedShader.gd")

var inspector_plugin = preload("inspector_plugin/ExtShaderInspectorPlugin.gd").new()

var shader_inspector_injector = preload("inspector_plugin/ShaderInspectorInjectPlugin.gd").new()


var shader : Shader
var shader_editor : Control
var button : Button
var shader_button : Button

func _enter_tree():
	add_custom_type("ExtendedShader", "Shader", ExtendedShader, preload("icon_extended_shader.svg"))
	print("ExtendedShader has entered the editor.")
	shader_editor = preload("ExtEditorPanel.tscn").instance()
	
	shader_editor.set_custom_minimum_size(Vector2(0, 300))
	button = add_control_to_bottom_panel(shader_editor, "ExtendedShader")
	button.hide()
	
	shader_editor.get_child(0).parse_settings(get_editor_interface().get_editor_settings())
	
	for panel in shader_editor.get_parent().get_children():
		if panel.get_class() == "ShaderEditor":
			#we do truly evil things here don't worry about it
			print("found the shader editor, it is ", panel)
			# crawl the shader editor panel to the error label so we can
			# watch it for changes
			var shader_errlbl := panel.get_child(1).get_child(1).get_child(2)\
				.get_child(1).get_child(2) as Label
			var shader_timer := panel.get_child(1).get_child(1).get_child(3) as Timer
			print(shader_errlbl)
			shader_editor.get_child(0).error_label = shader_errlbl
			shader_editor.get_child(0).classic_shader_editor = panel
			shader_editor.get_child(0).shader_timer = shader_timer
			shader_editor.get_child(0).fs = get_editor_interface().get_resource_filesystem()
	
	for but in button.get_parent().get_children():
		if but.text == "Shader":
			shader_button = but
			break
	
	add_inspector_plugin(shader_inspector_injector)
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	remove_custom_type("ExtendedShader")
	remove_control_from_bottom_panel(shader_editor)
	print("ExtendedShader has exited the editor.")
	remove_inspector_plugin(inspector_plugin)

func edit(object : Object) -> void:
	shader = object as ExtendedShader
	shader_editor.get_child(0).edit(shader)

func handles(object : Object) -> bool:
	return object is ExtendedShader

func make_visible(visible : bool) -> void:
	if visible:
		shader_button.hide()
		button.show()
		make_bottom_panel_item_visible(shader_editor)
	else:
		button.hide()
		if shader_editor.is_visible_in_tree():
			hide_bottom_panel()
		shader_editor.get_child(0).apply_shaders()

func selected_notify() -> void:
	shader_editor.get_child(0).ensure_select_current()

func save_external_data() -> void:
	shader_editor.get_child(0).save_external_data()

func apply_changes() -> void:
	shader_editor.get_child(0).apply_shaders()
