class_name SpellProjectile
extends Node2D

var request: SpawnRequest
var payload_factory: ProjectileFactory
var velocity: Vector2 = Vector2.ZERO
var lifetime_remaining: float = 1.0
var pierce_left: int = 0
var bounce_left: int = 0

var _trigger_timer_remaining: float = -1.0
var _payload_triggered: bool = false
var _hit_area: Area2D


func configure(spawn_request: SpawnRequest) -> void:
	request = spawn_request.duplicate_request()
	global_position = request.origin
	velocity = request.direction.normalized() * request.speed
	lifetime_remaining = request.lifetime
	pierce_left = request.pierce
	bounce_left = request.bounce
	_trigger_timer_remaining = request.trigger_delay
	queue_redraw()


func _ready() -> void:
	if request == null:
		queue_free()
		return
	_setup_hit_area()


func _process(delta: float) -> void:
	if request == null:
		return

	global_position += velocity * delta
	if request.trigger_mode == TriggerActionCardData.TriggerMode.ON_TIMER and not _payload_triggered:
		_trigger_timer_remaining -= delta
		if _trigger_timer_remaining <= 0.0:
			_trigger_payload(global_position, _get_move_direction())
			queue_free()
			return

	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		if request.trigger_mode == TriggerActionCardData.TriggerMode.ON_TIMER and not _payload_triggered:
			_trigger_payload(global_position, _get_move_direction())
		queue_free()


func _draw() -> void:
	if request == null:
		return

	draw_circle(Vector2.ZERO, request.radius, request.projectile_color)
	draw_arc(Vector2.ZERO, request.radius + 2.0, 0.0, TAU, 24, Color(1, 1, 1, 0.55), 1.25)
	if request.explosion_radius > 0.0:
		draw_arc(
			Vector2.ZERO,
			minf(request.explosion_radius, 32.0),
			0.0,
			TAU,
			32,
			Color(1.0, 0.8, 0.35, 0.45),
			1.0
		)


func _setup_hit_area() -> void:
	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 1
	_hit_area.monitoring = true
	_hit_area.monitorable = false
	_hit_area.body_entered.connect(_on_hit_body_entered)
	_hit_area.area_entered.connect(_on_hit_area_entered)
	add_child(_hit_area)

	var circle := CircleShape2D.new()
	circle.radius = maxf(1.0, request.radius)

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = circle
	_hit_area.add_child(collision_shape)


func _on_hit_body_entered(_body: Node2D) -> void:
	_handle_hit()


func _on_hit_area_entered(area: Area2D) -> void:
	if area == _hit_area:
		return
	_handle_hit()


func _handle_hit() -> void:
	if request == null:
		return

	if request.trigger_mode == TriggerActionCardData.TriggerMode.ON_HIT:
		_trigger_payload(global_position, _get_move_direction())

	if pierce_left > 0:
		pierce_left -= 1
		return

	queue_free()


func _trigger_payload(origin: Vector2, direction: Vector2) -> void:
	_payload_triggered = true
	if request.trigger_payload.is_empty() or payload_factory == null:
		return
	payload_factory.spawn_trigger_payload(request.trigger_payload, origin, direction, request.direction)


func _get_move_direction() -> Vector2:
	var direction := velocity.normalized()
	if direction == Vector2.ZERO and request != null:
		direction = request.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	return direction
