class_name ProjectileFactory
extends Node

@export var projectile_parent_path: NodePath


func spawn_requests(requests: Array[SpawnRequest]) -> Array[SpellProjectile]:
	var spawned: Array[SpellProjectile] = []
	var parent := get_projectile_parent()
	for request in requests:
		var projectile := SpellProjectile.new()
		projectile.configure(request)
		parent.add_child(projectile)
		spawned.append(projectile)
	return spawned


func get_projectile_parent() -> Node:
	if not projectile_parent_path.is_empty():
		var parent := get_node_or_null(projectile_parent_path)
		if parent != null:
			return parent
	return self
