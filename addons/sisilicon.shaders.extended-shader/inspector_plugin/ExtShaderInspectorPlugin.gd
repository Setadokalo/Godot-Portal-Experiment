tool
extends EditorInspectorPlugin

const ExtendedShader = preload("../ExtendedShader.gd")

func can_handle(object):
	return object is ExtendedShader


func parse_property(object, type, path, hint, hint_text, usage):
	if path == "raw_code":
		# this should effectively hide the raw code export from the inspector
		# while allowing it to be saved in scene files (as an export var)
		 return true
	else:
		 return false
