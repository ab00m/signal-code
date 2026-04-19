class_name ExperienceSystem
extends Node

signal exp_changed(current_exp: float, threshold: float)
signal level_changed(new_level: int)
signal level_up_requested(new_level: int)

const DYNAMIC_THRESHOLD_START_LEVEL := 10
const DYNAMIC_THRESHOLD_BASE := 120
const DYNAMIC_THRESHOLD_STEP := 20

@export var level_thresholds: Array[int] = [10, 20, 40, 60, 80, 100, 100, 100, 100]

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


func add_debug_exp_without_upgrade_requests(amount: float) -> void:
	if amount <= 0.0:
		return

	var multiplier := 1.0
	if run_modifier_controller != null:
		multiplier = run_modifier_controller.get_exp_gain_multiplier()
	current_exp += amount * multiplier
	while current_exp >= get_current_threshold():
		current_exp -= get_current_threshold()
		current_level += 1
		level_changed.emit(current_level)
	exp_changed.emit(current_exp, get_current_threshold())


func get_current_threshold() -> float:
	if current_level >= 1 and current_level <= level_thresholds.size():
		return float(level_thresholds[current_level - 1])

	var dynamic_threshold := (current_level - DYNAMIC_THRESHOLD_START_LEVEL) * DYNAMIC_THRESHOLD_STEP + DYNAMIC_THRESHOLD_BASE
	return float(maxi(1, dynamic_threshold))


func consume_pending_level_up() -> void:
	pending_level_ups = maxi(0, pending_level_ups - 1)


func _check_level_ups() -> void:
	while current_exp >= get_current_threshold():
		current_exp -= get_current_threshold()
		current_level += 1
		pending_level_ups += 1
		level_changed.emit(current_level)
		level_up_requested.emit(current_level)
