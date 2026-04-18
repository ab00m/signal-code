class_name SpellGroup
extends RefCounted

var actions: Array[ActionCardData] = []
var modifiers: Array[ModifierCardData] = []
var target_action_count: int = 1


func is_empty() -> bool:
	return actions.is_empty()


func get_consumed_action_count() -> int:
	return actions.size()


func describe() -> String:
	var action_names: Array[String] = []
	for action in actions:
		action_names.append(action.get_display_name())

	var modifier_names: Array[String] = []
	for modifier in modifiers:
		modifier_names.append(modifier.get_display_name())

	return "动作=%s 修饰器=%s 目标动作数=%d" % [
		_join_names(action_names),
		_join_names(modifier_names),
		target_action_count,
	]


func _join_names(names: Array[String]) -> String:
	var result := ""
	for index in range(names.size()):
		if index > 0:
			result += ", "
		result += names[index]
	return result
