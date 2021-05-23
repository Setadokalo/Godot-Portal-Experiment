tool
extends VBoxContainer

const ExtendedShader := preload("../ExtendedShader.gd")

var shader : ExtendedShader
var con2key := {}

func parse_shader(object: ExtendedShader):
	shader = object
	for define in shader.defines:
		add_entry(define, shader.defines[define])
	var new_child := MenuButton.new()
	new_child.get_popup().add_item("String", TYPE_STRING)
	new_child.get_popup().add_item("int", TYPE_INT)
	new_child.get_popup().add_item("float", TYPE_REAL)
	new_child.get_popup().add_item("boolean", TYPE_BOOL)
	new_child.text = "Add"
	new_child.get_popup().connect("id_pressed", self, "_on_Add_pressed")
	add_child(new_child)
	
func _on_Add_pressed(id: int):
	match id:
		TYPE_STRING:
			add_entry("", "")
		TYPE_INT:
			add_entry("", 0)
		TYPE_REAL:
			add_entry("", 0.0)
		TYPE_BOOL:
			add_entry("", false)

func add_entry(key: String, value):
	var new_child: HBoxContainer = HBoxContainer.new()
	var key_line: LineEdit = LineEdit.new()
	key_line.text = key
	key_line.size_flags_horizontal = SIZE_EXPAND_FILL
	key_line.connect("text_entered", self, "_on_Define_key_changed", [new_child])
	new_child.add_child(key_line)
	match typeof(value):
		TYPE_STRING:
			var value_line: LineEdit = LineEdit.new()
			value_line.text = value
			value_line.connect("text_entered", self, "_on_Define_value_changed", [new_child])
			value_line.size_flags_horizontal = SIZE_EXPAND_FILL
			new_child.add_child(value_line)
		TYPE_INT:
			var value_line := EditorSpinSlider.new()
			value_line.step = 1
			value_line.max_value = 1024
			value_line.min_value = -1024
			value_line.value = value
			value_line.connect("value_changed", self, "_on_Define_value_changed", [new_child])
			value_line.size_flags_horizontal = SIZE_EXPAND_FILL
			new_child.add_child(value_line)
		TYPE_REAL:
			var value_line := EditorSpinSlider.new()
			value_line.step = 0.01
			value_line.max_value = 1024
			value_line.min_value = -1024
			value_line.value = value
			value_line.connect("value_changed", self, "_on_Define_value_changed", [new_child])
			value_line.size_flags_horizontal = SIZE_EXPAND_FILL
			new_child.add_child(value_line)
		TYPE_BOOL:
			var value_line := CheckBox.new()
			value_line.pressed = value
			value_line.connect("pressed", self, "_on_Define_value_changed", [new_child])
			value_line.size_flags_horizontal = SIZE_EXPAND_FILL
			new_child.add_child(value_line)
	var btn = get_child(get_child_count() - 1)
	remove_child(btn)
	add_child(new_child)
	add_child(btn)

func _on_Define_key_changed(new_key: String, source: HBoxContainer) -> void:
	var old_key = con2key.get(source)
	if typeof(old_key) == TYPE_STRING:
		shader.defines.erase(old_key)
	shader.defines[new_key] = source.get_child(1).text

func _on_Define_value_changed(new_value, source: HBoxContainer) -> void:
	var key = source.get_child(0).text
	print(key, ": ", new_value)
	shader.defines[key] = new_value
