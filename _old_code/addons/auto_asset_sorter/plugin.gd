@tool
extends EditorPlugin

var _importer: AutoGLBTextureSorterImporter

func _enter_tree() -> void:
    _importer = AutoGLBTextureSorterImporter.new()
    add_import_plugin(_importer)

func _exit_tree() -> void:
    if _importer:
        remove_import_plugin(_importer)
        _importer = null