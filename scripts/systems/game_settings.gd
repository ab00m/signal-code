class_name GameSettings
extends Node

signal auto_aim_changed(enabled: bool)

@export var auto_aim_enabled: bool = true


func set_auto_aim_enabled(enabled: bool) -> void:
	if auto_aim_enabled == enabled:
		return
	auto_aim_enabled = enabled
	auto_aim_changed.emit(auto_aim_enabled)
