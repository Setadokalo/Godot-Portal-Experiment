tool
extends ResourceFormatLoader
class_name ResourceLoaderExtShader

const ExtendedShader = preload("ExtendedShader.gd")

func get_dependencies(path : String, add_types : String) -> void:
	print(path + ", " + add_types)
	pass

func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["extshader"])

func get_resource_type(path : String) -> String:
	if path.ends_with(".extshader"):
		return "Shader"
	else:
		return ""

func handles_type(typename : String) -> bool:
	return typename == "Shader"

func load(path : String, original_path : String):
	var file := File.new()
	file.open(path, File.READ)
	if file.get_error():
		return file.get_error()
	if file.eof_reached():
		return ERR_FILE_CORRUPT
	file
	var code : String = file.get_var() as String
	if file.eof_reached():
		return ERR_FILE_CORRUPT
	var raw_code_ordefines = file.get_var()
	var defines: Dictionary
	var raw_code: String
	if typeof(raw_code_ordefines) == TYPE_DICTIONARY:
		defines = raw_code_ordefines
	else:
		raw_code = raw_code_ordefines
		defines = file.get_var()
	file.close()
	
	if code:
		var shader := ExtendedShader.new()
		shader.set_code_noprocess(code)
		if raw_code and raw_code != "":
			shader.apply_cached_code(raw_code)
		if defines:
			shader.defines = defines
		return shader
	else:
		return ERR_PARSE_ERROR
