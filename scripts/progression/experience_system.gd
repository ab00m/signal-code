class_name ExperienceSystem
extends Node

signal exp_changed(current_exp: float, threshold: float)
signal level_changed(new_level: int)
signal level_up_requested(new_level: int)

@export var level_thresholds: Array[int] = [10, 18, 28, 40, 55, 72, 90, 110, 135]

var run_modifier_controller: RunModifierController
var current_level: int = 1
var current_exp: float = 0.0
var pending_level_ups: int = 0


func reset_progression() -> void:
	current_level = 1
	current_exp = 0.0
	pending_level_ups = 0
	level_changed.emit(current_level)
	exp_changed.emit(current_exp, get_current_threshold())


func add_exp(amount: float) -> void:
	if amount <= 0.0:
		return

	var multiplier := 1.0
	if run_modifier_controller != null:
		multiplier = run_modifier_controller.get_exp_gain_multiplier()
	current_exp += amount * multiplier
	_check_level_ups()
	exp_changed.emit(current_exp, get_current_threshold())


func get_current_threshold() -> float:
	if level_thresholds.is_empty():
		return 1.0
	var index := clampi(current_level - 1, 0, level_thresholds.size() - 1)
	return float(level_thresholds[index])


func consume_pending_level_up() -> void:
	pending_level_ups = maxi(0, pending_level_ups - 1)


func _check_level_ups() -> void:
	while current_exp >= get_current_threshold():
		current_exp -= get_current_threshold()
		current_level += 1
		pending_level_ups += 1
		level_changed.emit(current_level)
		level_up_requested.emit(current_level)
