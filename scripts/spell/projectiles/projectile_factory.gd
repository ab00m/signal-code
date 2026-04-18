class_name ProjectileFactory
extends Node

@export var projectile_parent_path: NodePath


func spawn_requests(requests: Array[SpawnRequest]) -> Array[SpellProjectile]:
	var spawned: Array[SpellProjectile] = []
	var parent := get_projectile_parent()
	for request in requests:
		var projectile := _spawn_request(request, parent)
		spawned.append(projectile)
	return spawned


func spawn_trigger_payload(
	requests: Array[SpawnRequest],
	origin: Vector2,
	direction: Vector2,
	basis_direction: Vector2
) -> Array[SpellProjectile]:
	var retargeted_requests: Array[SpawnRequest] = []
	var target_direction := direction.normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.RIGHT

	var basis := basis_direction.normalized()
	if basis == Vector2.ZERO:
		basis = Vector2.RIGHT

	for request in requests:
		var retargeted := request.duplicate_request()
		var request_direction := retargeted.direction.normalized()
		if request_direction == Vector2.ZERO:
			request_direction = basis

		var relative_angle := basis.angle_to(request_direction)
		retargeted.origin = origin
		retargeted.direction = target_direction.rotated(relative_angle)
		retargeted_requests.append(retargeted)

	return spawn_requests(retargeted_requests)


func get_projectile_parent() -> Node:
	if not projectile_parent_path.is_empty():
		var parent := get_node_or_null(projectile_parent_path)
		if parent != null:
			return parent
	return self


func _spawn_request(request: SpawnRequest, parent: Node) -> SpellProjectile:
	var projectile := SpellProjectile.new()
	projectile.payload_factory = self
	projectile.configure(request)
	parent.add_child(projectile)
	_schedule_echo(request)
	return projectile


func _schedule_echo(request: SpawnRequest) -> void:
	if request.echo_delay <= 0.0:
		return

	var echo_request := request.duplicate_request()
	echo_request.echo_delay = -1.0
	var timer := get_tree().create_timer(request.echo_delay)
	timer.timeout.connect(func() -> void:
		var echo_requests: Array[SpawnRequest] = [echo_request]
		spawn_requests(echo_requests)
	)
