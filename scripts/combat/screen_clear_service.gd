class_name ScreenClearService
extends Node

@export var enemy_group: StringName = &"enemy"
@export var boss_group: StringName = &"boss"
@export var ignore_metadata_key: StringName = &"ignore_player_screen_clear"


func execute_player_screen_clear() -> int:
	var cleared_count := 0
	for node in get_tree().get_nodes_in_group(enemy_group):
		if not (node is Node):
			continue
		var enemy := node as Node
		if enemy.is_queued_for_deletion() or _is_screen_clear_immune(enemy):
			continue

		if enemy.has_method("die_by_screen_clear"):
			enemy.call("die_by_screen_clear")
		else:
			enemy.queue_free()
		cleared_count += 1
	return cleared_count


func _is_screen_clear_immune(enemy: Node) -> bool:
	if enemy.is_in_group(boss_group):
		return true
	if enemy.has_meta(ignore_metadata_key):
		return enemy.get_meta(ignore_metadata_key) == true
	return false
