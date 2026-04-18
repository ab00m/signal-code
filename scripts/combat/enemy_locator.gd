class_name EnemyLocator
extends Node

@export var enemy_group: StringName = &"enemy"


func get_nearest_enemy(from_position: Vector2) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance_sq := INF

	for node in get_tree().get_nodes_in_group(enemy_group):
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if enemy.is_queued_for_deletion() or not enemy.is_inside_tree():
			continue

		var distance_sq := from_position.distance_squared_to(enemy.global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_enemy = enemy

	return nearest_enemy
