tool
extends EditorInspectorPlugin
class_name ShaderInspectorInjectPlugin

const ExtendedShader = preload("../ExtendedShader.gd")


func can_handle(object):
	return object is ShaderMaterial

var obj : ShaderMaterial

func parse_property(object, type, path, hint, hint_text, usage):
	if path == "shader":
		obj = object
		add_property_editor("shader", VirtualShaderEditor.new(self))
		

class VirtualShaderEditor extends EditorProperty:
	var standard_shader: int = -1
	var menu : PopupMenu
	var p: ShaderInspectorInjectPlugin
	func _init(parent: ShaderInspectorInjectPlugin) -> void:
		p = parent
	
	func _ready() -> void:
		yield(get_tree(), "idle_frame")
		print("injecting into shader editor")
		menu = get_parent().get_child(1).get_child(1)
		menu.connect("visibility_changed", self, "_on_Menu_visibility_changed")
		menu.connect("index_pressed", self, "_on_Menu_Option_selected")

	func _on_Menu_visibility_changed():
		var storage = []
		for item in menu.get_item_count():
			var istore = {}
			istore["id"] = menu.get_item_id(item)
			istore["accelerator"] = menu.get_item_accelerator(item)
			istore["icon"] = menu.get_item_icon(item)
			istore["metadata"] = menu.get_item_metadata(item)
			istore["shortcut"] = menu.get_item_shortcut(item)
			istore["submenu"] = menu.get_item_submenu(item)
			istore["text"] = menu.get_item_text(item)
			istore["tooltip"] = menu.get_item_tooltip(item)
			
			istore["checkable"] = menu.is_item_checkable(item)
			istore["radiocheckable"] = menu.is_item_checkable(item)
			istore["checked"] = menu.is_item_checked(item)
			istore["disabled"] = menu.is_item_disabled(item)
			istore["separator"] = menu.is_item_separator(item)
			istore["scutdisabled"] = menu.is_item_shortcut_disabled(item)
			storage.push_back(istore)
			
		menu.clear()
		push_item_from_dictionary(0, storage[0])
		standard_shader = storage[0].get("id")
		menu.add_icon_item(preload("../icon_extended_shader.svg"), "New ExtendedShader", standard_shader)
		
		for item in range(1, storage.size()):
			var istore: Dictionary = storage[item]
			push_item_from_dictionary(item + 1, istore)
			
#			menu.add_item()

	func push_item_from_dictionary(index: int, istore: Dictionary):
		var id = istore["id"]
		menu.add_item(istore["text"], id, istore["accelerator"])
		menu.set_item_icon(index, istore["icon"])
		menu.set_item_metadata(index, istore["metadata"])
		menu.set_item_shortcut(index, istore["shortcut"])
		menu.set_item_submenu(index, istore["submenu"])
		menu.set_item_tooltip(index, istore["tooltip"])
		
		menu.set_item_as_checkable(index, istore["checkable"])
		menu.set_item_as_radio_checkable(index, istore["radiocheckable"])
		menu.set_item_checked(index, istore["checked"])
		menu.set_item_disabled(index, istore["disabled"])
		menu.set_item_as_separator(index, istore["separator"])
		menu.set_item_shortcut_disabled(index, istore["scutdisabled"])		

	func _on_Menu_Option_selected(idx: int):
		if menu.get_item_id(idx) == standard_shader and idx == 1:
			p.obj.shader = ExtendedShader.new()

