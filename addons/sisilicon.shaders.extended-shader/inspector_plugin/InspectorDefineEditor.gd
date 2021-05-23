tool
extends EditorProperty
class_name InspectorDefineEditor

const ExtendedShader := preload("../ExtendedShader.gd")
const ExtDefinesPanel := preload("ExtDefinesPanel.gd")

var button: Button
var editor: ExtDefinesPanel
var object: ExtendedShader

func _init(edit_object: ExtendedShader) -> void:
	editor = preload("ExtDefinesPanel.tscn").instance() as ExtDefinesPanel
	object = edit_object
	button = ToolButton.new()
	button.text = "Edit"
	button.connect("pressed", self, "_on_Button_pressed")
	add_child(button)
	add_child(editor)
	set_bottom_editor(editor)
	print(editor.get_method_list())
	editor.call("parse_shader", object)

func _on_Button_pressed():
	editor.visible = not editor.visible
