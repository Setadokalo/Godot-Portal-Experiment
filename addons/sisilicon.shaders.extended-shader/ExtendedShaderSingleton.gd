tool
extends Node

# TODO: Conditionally remove cached shaders (based on memory usage? reference counting? idk)

# Contains the cached state for every loaded shader.
# Key should be the path String with a `res://` prefix.
# Value should be a String of the contents. 
var _shader_cache: Dictionary = Dictionary()

func get_raw_shader(key: String) -> String:
	if not key or not _shader_cache.has(key):
		return ""
	var value: CacheResult = _shader_cache.get(key)
	value._timeout = 1200.0
	_shader_cache[key] = value
	return value.compiled_code

func put_raw_shader(key: String, value: String):
	if not key or not value:
		return
	var wrapped_value = CacheResult.new(value)
	wrapped_value._timeout = 1200.0
	_shader_cache[key] = wrapped_value

func remove_raw_shader(key: String):
	if _shader_cache.has(key):
		_shader_cache.erase(key)

# Contains the compiled cached state for every loaded shader.
# Key should be a DefineCacheAccess object with the parent shaders' define state.
# Value should be a DefineCacheResult object.
var _compiled_shader_cache: Dictionary = Dictionary()

func get_compiled_shader(key: DefineCacheAccess) -> DefineCacheResult:
	if not key or not _compiled_shader_cache.has(key):
		return null
	var value: DefineCacheResult = _compiled_shader_cache.get(key)
	value._timeout = 1200.0
	_compiled_shader_cache[key] = value
	return value

func put_compiled_shader(key: DefineCacheAccess, value: DefineCacheResult):
	if not key or not value:
		return
	value._timeout = 1200.0
	_compiled_shader_cache[key] = value

var _combined_delta := 0.0

func _process(delta: float) -> void:
	_combined_delta += delta
	# only check for dead shaders ~once a minute
	if _combined_delta > 60.0:
#		for key in _compiled_shader_cache.keys():
#			var value: DefineCacheResult = _compiled_shader_cache[key]
#
#			value._timeout -= _combined_delta
#			if value._timeout <= 0.0:
#				_compiled_shader_cache.erase(key)
#			else:
#				_compiled_shader_cache[key] = value
		for key in _shader_cache.keys():
			var value: CacheResult = _shader_cache[key]
			
			value._timeout -= _combined_delta
			if value._timeout <= 0.0:
				_shader_cache.erase(key)
			else:
				_shader_cache[key] = value
		_combined_delta = 0.0

class DefineCacheAccess:
	var defines: Dictionary
	var path: String
	func _init(path_: String, defines_ : Dictionary):
		defines = defines_
		path = path_

static func def_cache_access(path: String, defines: Dictionary) -> DefineCacheAccess:
	return DefineCacheAccess.new(path, defines)

class CacheResult:
	# the preprocessed code for this shader
	var compiled_code: String
	# timeout of 20 minutes - after 20 minutes of not being accessed,
	# the shader will be deleted from the cache
	var _timeout: float = 1200.0
	
	func _init(code: String):
		compiled_code = code

class DefineCacheResult extends CacheResult:
	# the shader-global defines state after this shader had been processed
	var mutated_defines: Dictionary
	
	func _init(code: String, defines: Dictionary).(code):
		mutated_defines = defines

var builtins: Array

func get_builtin_shaders() -> Array:
	if builtins:
		return builtins
	
	var dir: Directory = Directory.new()
	var ret := get_shaders_for_dir("res://addons/sisilicon.shaders.extended-shader/builtin_shaders")
	return ret

func get_shaders_for_dir(dir_path: String) -> Array:
	var dir: Directory = Directory.new()
	var ret := []
	dir.open(dir_path)
	dir.list_dir_begin(true, true)
	var next : String = dir.get_next()
	while next:
		if dir.dir_exists(next):
			ret.append(NamedSubCategory.new(next, get_shaders_for_dir(dir_path + "/" + next)))
		else:
			ret.append(next.trim_suffix(".extshader"))
		next = dir.get_next()
	ret.sort()
	builtins = ret
	return builtins

class NamedSubCategory:
	var category: String
	var children: Array
	func _init(cat: String, chldrn: Array) -> void:
		category = cat
		children = chldrn
