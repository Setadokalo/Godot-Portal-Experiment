tool
extends Control

enum {FIND, FIND_NEXT, FIND_PREVIOUS, REPLACE, GOTO_LINE,
		UNDO, REDO, CUT, COPY, PASTE, SELECT_ALL, MOVE_UP,
		MOVE_DOWN, INDENT_LEFT, INDENT_RIGHT, DELETE_LINE,
		TOGGLE_COMMENT, CLONE_DOWN, COMPLETE_SYMBOL, ONLINE_DOCS,
		EXTENDED_DOCS
}

#enum {GOTO_LINE}

var fs: EditorFileSystem

const ExtendedShader = preload("ExtendedShader.gd")


onready var text_edit := $TextEdit as TextEdit

var had_focus := false
var shader : ExtendedShader

var error_label : Label
var error_msg: String
var error_lbl_regex = RegEx.new()

var shader_timer : Timer

var classic_shader_editor: Control
var raw_view: bool = false

var singleton := preload("ExtendedShaderSingleton.gd").new()

var flattened_shaders_list := []

var functions := []

var shader_func_regex

var argument_regex

func add_shaders_to_popup(popup: PopupMenu, shaders: Array, path: String = "", index: int = 0) -> PopupMenu:
	var dirs := Dictionary()
	for idx in shaders.size():
		var shader = shaders[idx]
		if shader is String:
			if not (shader as String).get_extension():
				popup.add_icon_item(preload("res://addons/sisilicon.shaders.extended-shader/icon_extended_shader.svg"),\
					shader,
					flattened_shaders_list.size()
				)
				flattened_shaders_list.append(path + "/" + shader)
		else:
			dirs[index + idx] = shader
	for shader_key in dirs.keys():
		var shader = dirs[shader_key]
		var child_popup := add_shaders_to_popup(PopupMenu.new(), shader.children,\
			path + shader.category, shader_key)
		popup.add_child(child_popup)
		child_popup.name = shader.category
		popup.add_submenu_item(shader.category, shader.category)
	popup.connect("id_pressed", self, "_on_Include_item_pressed")
	return popup

# only used for the root, in a multithreaded environment
func add_shaders_to_popup_threadsafe(popup: PopupMenu, shaders: Array, path: String = "", index: int = 0) -> PopupMenu:
	var dirs := Dictionary()
	for idx in shaders.size():
		var shader = shaders[idx]
		if shader is String:
			if not (shader as String).get_extension():
				popup.call_deferred("add_icon_item", preload("res://addons/sisilicon.shaders.extended-shader/icon_extended_shader.svg"),\
					shader,
					flattened_shaders_list.size()
				)
				flattened_shaders_list.append(path + "/" + shader)
		else:
			dirs[index + idx] = shader
	for shader_key in dirs.keys():
		var shader = dirs[shader_key]
		var child_popup := add_shaders_to_popup(PopupMenu.new(), shader.children,\
			path + shader.category, shader_key)
		child_popup.name = shader.category
		popup.call_deferred("add_child", child_popup)
		popup.call_deferred("add_submenu_item", shader.category, shader.category)
	popup.call_deferred("connect", "id_pressed", self, "_on_Include_item_pressed")
	return popup

func _threaded_shaders_init(_userdata):
	
	var include : PopupMenu = $Tools/AddInclude.get_popup()
	var shaders = singleton.get_builtin_shaders()
	add_shaders_to_popup(include, shaders)
	shader_func_regex = ExtendedShader.create_reg_exp(
		"\\s*(?<return>(?:[biu]?(?:vec|mat)[234])|(?:float)|(?:[biu]?sampler(?:[23]D(?:Array)?|Cube))|(?:u?int)|(?:void)|(?:bool))\\s+(?<name>[a-zA-Z_][a-zA-Z0-9_]*)\\s*\\((?<arguments>[a-zA-Z0-9,_\\s]*?)\\)\\s*?{")
	argument_regex = ExtendedShader.create_reg_exp(
		"(?<type>(?:(?:out|in|inout)\\s+)?(?:(?:[biu]?(?:vec|mat)[234])|(?:float)|(?:[biu]?sampler(?:[23]D(?:Array)?|Cube))|(?:u?int)|(?:void)|(?:bool)))\\s*(?<name>[a-zA-Z_][a-zA-Z0-9_]*)"
	)

var thread

func _ready() -> void:
	error_lbl_regex.compile("^error\\((.+?)\\): (.*)$")
	var search : PopupMenu = $Tools/Search.get_popup()
	var edit : PopupMenu = $Tools/Edit.get_popup()
	var goto : PopupMenu = $Tools/GoTo.get_popup()
	var help : PopupMenu = $Tools/Help.get_popup()
	var functions : PopupMenu = $Tools/Functions.get_popup()
	thread = Thread.new()
	thread.start(self, "_threaded_shaders_init")
#	help.set_item_icon(help.get_item_index(ONLINE_DOCS),
#		get_icon("Instance"))
		
	
	search.connect(  "id_pressed",  self, "_on_Menu_item_pressed")
	edit.connect(    "id_pressed",  self, "_on_Menu_item_pressed")
	goto.connect(    "id_pressed",  self, "_on_Menu_item_pressed")
	help.connect(    "id_pressed",  self, "_on_Menu_item_pressed")
	functions.connect("id_pressed", self, "_on_Functions_item_pressed")
	
	search.set_item_shortcut(search.get_item_index(FIND), shortcut(KEY_F, true, false, false))
	search.set_item_shortcut(search.get_item_index(FIND_NEXT), shortcut(KEY_F3, false, false, false))
	search.set_item_shortcut(search.get_item_index(FIND_PREVIOUS), shortcut(KEY_F3, false, true, false))
	search.set_item_shortcut(search.get_item_index(REPLACE), shortcut(KEY_R, true, false, false))
	search.set_item_shortcut(search.get_item_index(GOTO_LINE), shortcut(KEY_L, true, false, false))

	edit.set_item_shortcut(edit.get_item_index(UNDO), shortcut(KEY_Z, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(REDO), shortcut(KEY_Y, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(CUT), shortcut(KEY_X, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(COPY), shortcut(KEY_C, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(PASTE), shortcut(KEY_V, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(SELECT_ALL), shortcut(KEY_A, true, false, false))

	edit.set_item_shortcut(edit.get_item_index(MOVE_UP), shortcut(KEY_UP, false, false, true))
	edit.set_item_shortcut(edit.get_item_index(MOVE_DOWN), shortcut(KEY_DOWN, false, false, true))
	edit.set_item_shortcut(edit.get_item_index(DELETE_LINE), shortcut(KEY_K, true, true, false))
	edit.set_item_shortcut(edit.get_item_index(TOGGLE_COMMENT), shortcut(KEY_K, true, false, false))
	edit.set_item_shortcut(edit.get_item_index(CLONE_DOWN), shortcut(KEY_B, true, false, false))

	edit.set_item_shortcut(edit.get_item_index(COMPLETE_SYMBOL), shortcut(KEY_SPACE, true, false, false))
	
	yield(get_tree(), "idle_frame")
	get_tree().root.add_child(singleton)
	
	edit(shader, true)

func _on_Include_item_pressed(ID : int) -> void:
	var line_idx = text_edit.cursor_get_line()
	text_edit.set_line(line_idx, "#include <\"" + (flattened_shaders_list[ID] as String).trim_prefix("/") + "\">\n" + text_edit.get_line(line_idx))
	text_edit.cursor_set_line(line_idx + 1)
	
func parse_settings(settings: EditorSettings):
	print(settings.get_setting("text_editor/highlighting/background_color"))
	text_edit.add_color_override("background_color", settings.get_setting("text_editor/highlighting/background_color"))
	text_edit.add_color_override("completion_background_color", settings.get_setting("text_editor/highlighting/completion_background_color"))
	text_edit.add_color_override("completion_selected_color", settings.get_setting("text_editor/highlighting/completion_selected_color"))
	text_edit.add_color_override("completion_existing_color", settings.get_setting("text_editor/highlighting/completion_existing_color"))
	text_edit.add_color_override("completion_scroll_color", settings.get_setting("text_editor/highlighting/completion_scroll_color"))
	text_edit.add_color_override("completion_font_color", settings.get_setting("text_editor/highlighting/completion_font_color"))
	text_edit.add_color_override("font_color", settings.get_setting("text_editor/highlighting/text_color"))
	var readonly_col: Color = settings.get_setting("text_editor/highlighting/text_color")
	readonly_col.a *= 0.8
	text_edit.add_color_override("font_color_readonly", readonly_col)
	text_edit.add_color_override("line_number_color", settings.get_setting("text_editor/highlighting/line_number_color"))
	text_edit.add_color_override("caret_color", settings.get_setting("text_editor/highlighting/caret_color"))
	text_edit.add_color_override("caret_background_color", settings.get_setting("text_editor/highlighting/caret_background_color"))
	text_edit.add_color_override("text_selected_color", settings.get_setting("text_editor/highlighting/text_selected_color"))
	text_edit.add_color_override("selection_color", settings.get_setting("text_editor/highlighting/selection_color"))
	text_edit.add_color_override("brace_mismatch_color", settings.get_setting("text_editor/highlighting/brace_mismatch_color"))
	text_edit.add_color_override("current_line_color", settings.get_setting("text_editor/highlighting/current_line_color"))
	text_edit.add_color_override("line_length_guideline_color", settings.get_setting("text_editor/highlighting/line_length_guideline_color"))
	text_edit.add_color_override("word_highlighted_color", settings.get_setting("text_editor/highlighting/word_highlighted_color"))
	text_edit.add_color_override("number_color", settings.get_setting("text_editor/highlighting/number_color"))
	text_edit.add_color_override("function_color", settings.get_setting("text_editor/highlighting/function_color"))
	text_edit.add_color_override("member_variable_color", settings.get_setting("text_editor/highlighting/member_variable_color"))
	text_edit.add_color_override("mark_color", settings.get_setting("text_editor/highlighting/mark_color"))
	text_edit.add_color_override("bookmark_color", settings.get_setting("text_editor/highlighting/bookmark_color"))
	text_edit.add_color_override("breakpoint_color", settings.get_setting("text_editor/highlighting/breakpoint_color"))
	text_edit.add_color_override("executing_line_color", settings.get_setting("text_editor/highlighting/executing_line_color"))
	text_edit.add_color_override("code_folding_color", settings.get_setting("text_editor/highlighting/code_folding_color"))
	text_edit.add_color_override("search_result_color", settings.get_setting("text_editor/highlighting/search_result_color"))
	text_edit.add_color_override("search_result_border_color", settings.get_setting("text_editor/highlighting/search_result_border_color"))
	text_edit.add_color_override("symbol_color", settings.get_setting("text_editor/highlighting/symbol_color"))
	text_edit.add_color_override("keyword_color", settings.get_setting("text_editor/highlighting/keyword_color"))
	text_edit.add_color_override("comment_color", settings.get_setting("text_editor/highlighting/comment_color"))
	text_edit.draw_spaces = settings.get_setting("text_editor/indent/draw_spaces")
	text_edit.draw_tabs = settings.get_setting("text_editor/indent/draw_tabs")
	
func save_external_data() -> void:
	if not shader:
		return
	
	apply_shaders()
	if shader.resource_path != "" && shader.resource_path.find("local://") == -1 && shader.resource_path.find("::") == -1:
		#external shader, save it
		ResourceSaver.save(shader.resource_path, shader)

func validate_filename():
	if shader and shader.resource_path and shader.resource_path.ends_with(".shader"):
		printerr("ExtendedShader ", shader.resource_path.get_basename(), " is saved as .shader! This will break on reloading the editor!")
		print("Attempting to change file path")
		var old_path = shader.resource_path
		shader.resource_path = shader.resource_path.trim_suffix(".shader") + ".extshader"
		var dir = Directory.new()
		if dir.open(old_path.get_base_dir()):
			printerr("error on opening dir")
		if dir.rename(old_path, shader.resource_path):
			printerr("error on renaming file")
		if fs: 
			fs.scan()

func edit(shader : ExtendedShader, dry_run: bool = false) -> void:
	if not shader:
		return
	shader.singleton = singleton
	validate_filename()
	if raw_view:
		$Tools/RawView.pressed = false
	if self.shader != shader:
		if not shader_timer.is_connected("timeout", self, "_on_PollForErrors_timeout"):
			shader_timer.connect("timeout", self, "_on_PollForErrors_timeout")
		self.shader = shader
		if not shader.is_connected("error", self, "_on_Shader_error"):
			shader.connect("error", self, "_on_Shader_error")
		if not shader.is_connected("error", self, "_on_Preproc_error"):
			shader.connect("error", self, "_on_Preproc_error")
		text_edit = $TextEdit
		
		_on_TextEdit_cursor_changed()
		text_edit.text = shader.raw_code
		apply_shaders(dry_run)
		
		if had_focus:
			text_edit.grab_focus()
			had_focus = false
	

func apply_shaders(dry_run: bool = false) -> void:
	validate_filename()
	
	if text_edit and shader and not raw_view:
		$InfoBar/ErrorBar.text = ""
		if not dry_run:
			var editor_code : String = text_edit.text
			shader.set_code(editor_code)
			text_edit.set_shader_mode(shader.get_mode())
			var fn_menu: PopupMenu = $Tools/Functions.get_popup()
			fn_menu.clear()
			functions = parse_shader_functions()
			for function in functions:
				fn_menu.add_item(function.name)
		
		had_focus = true

func _on_TextEdit_cursor_changed():
	$InfoBar/Cursor.text = "(%3d,%3d)" % [text_edit.cursor_get_line(), text_edit.cursor_get_column()]



func _on_TextEdit_text_changed():
	if not raw_view:
		$Timer.start()

var preproc_errored = false

func _on_Preproc_error(_line: int, _error_msg: String):
	preproc_errored = true
	

func _on_Timer_timeout():
	preproc_errored = false
	error_line = -1
	apply_shaders()
	yield(get_tree(), "idle_frame")
	if not preproc_errored:
		var cse_textedit := classic_shader_editor.get_child(1).get_child(1).get_child(0) as TextEdit
		cse_textedit.set_text(shader.get_code())
		(classic_shader_editor.get_child(1).get_child(1).get_child(3) as Timer).start(0.01)
		text_edit.grab_focus()
		yield(get_tree(), "idle_frame")
		text_edit.grab_focus()
	

var firstchar_regex = ExtendedShader.create_reg_exp("^\\s*")

func _on_Functions_item_pressed(ID: int):
	var fn: Dictionary = functions[ID]
	var combined: String = fn.name + "("
	if fn.has("arguments"):
		var arguments: Array = fn.arguments
		if arguments.size() > 1:
			for arg_idx in arguments.size() - 1:
				var arg = arguments[arg_idx]
				combined = combined + arg.name + " /* " + arg.type + " */, "
		combined = combined + arguments[arguments.size() - 1].name + " /* " + arguments[arguments.size() - 1].type + " */)"
	else:
		combined += ")"
	var Match = firstchar_regex.search(text_edit.get_line(text_edit.cursor_get_line()))
	if not Match:
		printerr("irrefutable pattern failed??")
		return
	if Match.get_end() >= text_edit.cursor_get_column():
		combined += ";"
	
	text_edit.insert_text_at_cursor(combined)
	

func get_flags_for_search() -> int:
	var flags = TextEdit.SEARCH_MATCH_CASE if $SearchBar/Settings/Main/MatchCase.pressed else 0
	flags += TextEdit.SEARCH_WHOLE_WORDS if $SearchBar/Settings/Main/WholeWords.pressed else 0
	return flags

func move_cursor_back(move: int) -> void:
	var target_column := text_edit.cursor_get_column() - move - 1
	if target_column < 0:
		text_edit.cursor_set_line(text_edit.cursor_get_line() - 1)
		target_column = text_edit.get_line(text_edit.cursor_get_line()).length() + target_column - 1
	text_edit.cursor_set_column(target_column)

func find_and_select(flags: int):
	var text = $SearchBar/SearchField/Find.text
	if flags & TextEdit.SEARCH_BACKWARDS:
		move_cursor_back(text.length())
	var result := text_edit.search(text, flags, text_edit.cursor_get_line(), text_edit.cursor_get_column())
	if result.size() > 0:
		var res_line = result[TextEdit.SEARCH_RESULT_LINE]
		var res_column = result[TextEdit.SEARCH_RESULT_COLUMN]
		text_edit.select(res_line, res_column, res_line, res_column + text.length())
		text_edit.cursor_set_line(res_line)
		text_edit.cursor_set_column(res_column + text.length())

func move_line_up():
	if text_edit.is_selection_active():
		var from_line = text_edit.get_selection_from_line()
		var to_line = text_edit.get_selection_to_line()
		var up_line = from_line - 1
		var line_to_move = text_edit.get_line(up_line)
		for line in range(from_line, to_line + 1):
			text_edit.set_line(line - 1, text_edit.get_line(line))
		text_edit.set_line(to_line, line_to_move)
		text_edit.select(from_line - 1, text_edit.get_selection_from_column(), 
			to_line - 1, text_edit.get_selection_to_column())
	else:
		var from_line = text_edit.get_line(text_edit.cursor_get_line())
		text_edit.set_line(text_edit.cursor_get_line(), text_edit.get_line(text_edit.cursor_get_line() - 1))
		text_edit.set_line(text_edit.cursor_get_line() - 1, from_line)
	text_edit.cursor_set_line(text_edit.cursor_get_line() - 1)
	
func move_line_down():
	if text_edit.is_selection_active():
		var from_line = text_edit.get_selection_from_line()
		var to_line = text_edit.get_selection_to_line()
		var up_line = to_line + 1
		var line_to_move = text_edit.get_line(up_line)
		for line in range(to_line, from_line - 1, -1):
			text_edit.set_line(line + 1, text_edit.get_line(line))
		text_edit.set_line(from_line, line_to_move)
		
		text_edit.select(from_line + 1, text_edit.get_selection_from_column(), 
			to_line + 1, text_edit.get_selection_to_column())
	else:
		var from_line = text_edit.get_line(text_edit.cursor_get_line())
		text_edit.set_line(text_edit.cursor_get_line(), text_edit.get_line(text_edit.cursor_get_line() + 1))
		text_edit.set_line(text_edit.cursor_get_line() + 1, from_line)
	text_edit.cursor_set_line(text_edit.cursor_get_line() + 1)

func _on_Menu_item_pressed(ID : int) -> void:
	match ID:
		FIND: 
			$SearchBar.visible = true
			$SearchBar/SearchField/Find.grab_focus()
			$SearchBar/SearchField/Replace.visible = false
			$SearchBar/MatchesPanel/ReplaceOptions.visible = false
			$SearchBar/Settings/Replace.visible = false
			
		FIND_NEXT: 
			find_and_select(get_flags_for_search())
		FIND_PREVIOUS: 
			find_and_select(get_flags_for_search() + TextEdit.SEARCH_BACKWARDS)
		REPLACE: if not raw_view:
			$SearchBar.visible = true
			$SearchBar/SearchField/Find.grab_focus()
			$SearchBar/SearchField/Replace.visible = true
			$SearchBar/MatchesPanel/ReplaceOptions.visible = true
			$SearchBar/Settings/Replace.visible = true
		GOTO_LINE: 
			$"../Goto/GotoLineDialog".popup()
		
		UNDO: text_edit.undo()
		REDO: text_edit.redo()
		
		CUT: text_edit.cut()
		COPY: text_edit.copy()
		PASTE: text_edit.paste()
		
		SELECT_ALL: text_edit.select_all()
		
		MOVE_UP: if not raw_view: move_line_up()
		MOVE_DOWN: if not raw_view: move_line_down()
		INDENT_LEFT: if not raw_view: 
			if text_edit.is_selection_active():
				for line in range(text_edit.get_selection_from_line(), text_edit.get_selection_to_line() + 1):
					var text = text_edit.get_line(line)
					if text.begins_with("\t"):
						text_edit.set_line(line, text.substr(1))
			else:
				var text = text_edit.get_line(text_edit.cursor_get_line())
				if text.begins_with("\t"):
					text_edit.set_line(text_edit.cursor_get_line(), text.substr(1))
		INDENT_RIGHT: if not raw_view:
			if text_edit.is_selection_active():
				for line in range(text_edit.get_selection_from_line(), text_edit.get_selection_to_line() + 1):
					var text = text_edit.get_line(line)
					text_edit.set_line(line, "\t" + text)
			else:
				var text = text_edit.get_line(text_edit.cursor_get_line())
				text_edit.set_line(text_edit.cursor_get_line(), "\t" + text)
				
#		DELETE_LINE: pass
#		TOGGLE_COMMENT: pass
#		CLONE_DOWN: pass
#		
#		COMPLETE_SYMBOL: pass
		
		ONLINE_DOCS:
			OS.shell_open("https://docs.godotengine.org/en/stable/tutorials/shading/shading_reference/index.html")
		EXTENDED_DOCS:
			OS.shell_open("https://github.com/Setadokalo/Extended-Shader-Plugin")
		
		_:
			_on_Shader_error(-1, "Sorry! This feature is currently unsupported. :(")
			printerr("Sorry! This feature is currently unsupported. :(")


func shortcut(scancode : int, ctrl : bool = false, shift : bool = false, alt : bool = false) -> ShortCut:
	var shortcut := ShortCut.new()
	var input := InputEventKey.new()
	input.scancode = scancode
	input.control = ctrl
	input.shift = shift
	input.alt = alt
	shortcut.shortcut = input
	
	return shortcut


func _on_CloseSearchButton_pressed() -> void:
	$SearchBar.visible = false


func _on_Next_pressed() -> void:
	find_and_select(get_flags_for_search())
func _on_Previous_pressed() -> void:
	find_and_select(get_flags_for_search() + TextEdit.SEARCH_BACKWARDS)


var old_text := ""

func _on_Find_text_changed(new_text: String) -> void:
	$SearchBar/SearchField/Find/Timer2.start()


func _on_Find_Field_timeout() -> void:
	var text = $SearchBar/SearchField/Find.text
	move_cursor_back(old_text.length())
	find_and_select(get_flags_for_search())
	
	var matches := text_edit.text.count(text)\
		if $SearchBar/Settings/Main/MatchCase.pressed else\
		text_edit.text.countn(text)
	
	$SearchBar/MatchesPanel/FindOptions/MatchesLabel.text = "%d matches" % matches
	if matches == 0:
		($SearchBar/MatchesPanel/FindOptions/MatchesLabel as Label)\
			.add_color_override("font_color", Color(1, 0.470588, 0.419608))
	else:
		($SearchBar/MatchesPanel/FindOptions/MatchesLabel as Label)\
			.add_color_override("font_color", Color(0.8, 0.807843, 0.827451))
	
	old_text = text



func _on_Goto_Ok_pressed() -> void:
	$"../Goto/GotoLineDialog".hide()
	var line = int($"../Goto/GotoLineDialog/LineBox/Line".text)
	$TextEdit.cursor_set_line(line - 1)


func _on_Goto_Cancel_pressed() -> void:
	$"../Goto/GotoLineDialog".hide()


func _on_PollForErrors_timeout():
	shader_timer.wait_time = 2.0
	if not visible:
		return
	
	if not error_label:
		print("error label not set!")
		return
	if error_label.text == error_msg:
		return
	error_msg = error_label.text
	var Match = error_lbl_regex.search(error_msg)
	if Match:
		_on_Shader_error(int(Match.get_string(1)), Match.get_string(2))
	

var error_line: int = -1

func _on_Shader_error(line: int, error_msg: String):
	self.error_msg = error_msg
	if error_line != -1 and raw_view:
		text_edit.set_line_as_safe(error_line, false)
	if line != -1:
		if raw_view:
			text_edit.set_line_as_safe(line - 1, true)
		error_line = line - 1
		$InfoBar/ErrorBar.text = "error(%d): %s" % [line, error_msg]
	else:
		error_line = -1
		$InfoBar/ErrorBar.text = "error: %s" % error_msg

func _on_RawView_toggled(button_pressed):
	raw_view = button_pressed
	text_edit.readonly = button_pressed
	if not button_pressed:
		text_edit.text = shader.raw_code
	else:
		# Raw view mode - show error lint
		text_edit.text = shader.code
		if error_line != -1:
			text_edit.set_line(error_line, text_edit.get_line(error_line) + " /!!!! ERROR: " + error_msg + " !!!!/")
			text_edit.set_line_as_safe(error_line, true)


func parse_shader_functions() -> Array:
	if not shader_func_regex or not argument_regex:
		# can't parse without the regexes, let them finish generating off-thread
		return []
	if not shader:
		printerr("tried to parse functions with null shader")
		return []
	var functions: Array
	var code = shader.code # we want fully compiled code for this
	var Matches = shader_func_regex.search_all(code)
	for Match in Matches:
		var function = Dictionary()
		function["return"] = Match.get_string("return")
		function["name"] = Match.get_string("name")
		if (Match.get_string("arguments") as String).length() > 0:
			var arguments = Match.get_string("arguments").split(",")
			var parsed_arguments = []
			for argument in arguments:
				var ArgMatch = argument_regex.search(argument)
				if ArgMatch:
					parsed_arguments.append({
						"type": ArgMatch.get_string("type"),
						"name": ArgMatch.get_string("name")
					})
				else:
					_on_Shader_error(-1, "Failed to parse arguments for function '" + function["name"] + "'")
			function["arguments"] = parsed_arguments
		functions.append(function)
	return functions


func _on_PrintFuncTable_pressed() -> void:
	print(parse_shader_functions())


func _exit_tree() -> void:
	thread.wait_to_finish()
