class_name SpellProjectile
extends Node2D

const SPELL_BASE_SCENE: PackedScene = preload("res://resources/spells/spell_base.tscn")

var request: SpawnRequest
var payload_factory: ProjectileFactory
var velocity: Vector2 = Vector2.ZERO
var lifetime_remaining: float = 1.0
var pierce_left: int = 0
var bounce_left: int = 0

var _trigger_timer_remaining: float = -1.0
var _payload_triggered: bool = false
var _spell_body: Node2D
var _hit_area: Area2D
var _spell_sprite: Sprite2D


func configure(spawn_request: SpawnRequest) -> void:
	request = spawn_request.duplicate_request()
	global_position = request.origin
	velocity = request.direction.normalized() * request.speed
	rotation = request.direction.angle()
	lifetime_remaining = request.lifetime
	pierce_left = request.pierce
	bounce_left = request.bounce
	_trigger_timer_remaining = request.trigger_delay
	queue_redraw()


func _ready() -> void:
	if request == null:
		queue_free()
		return
	_setup_spell_body()


func _process(delta: float) -> void:
	if request == null:
		return

	global_position += velocity * delta
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()
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


func _setup_spell_body() -> void:
	_spell_body = SPELL_BASE_SCENE.instantiate() as Node2D
	if _spell_body == null:
		return

	_spell_body.scale *= _get_spell_size_scale()
	add_child(_spell_body)

	_spell_sprite = _spell_body.get_node_or_null("Sprite2D") as Sprite2D
	if _spell_sprite != null:
		_spell_sprite.modulate = request.projectile_color

	_hit_area = _spell_body.get_node_or_null("Area2D") as Area2D
	if _hit_area == null:
		return

	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 1
	_hit_area.monitoring = true
	_hit_area.monitorable = false
	_hit_area.body_entered.connect(_on_hit_body_entered)
	_hit_area.area_entered.connect(_on_hit_area_entered)


func _get_spell_size_scale() -> float:
	if request == null:
		return 1.0
	return maxf(0.1, request.spell_size)


func _on_hit_body_entered(body: Node2D) -> void:
	_handle_hit(body)


func _on_hit_area_entered(area: Area2D) -> void:
	if area == _hit_area:
		return
	_handle_hit(area)


func _handle_hit(hit_source: Node = null) -> void:
	if request == null:
		return

	var hit_applied := _apply_enemy_hit(hit_source)
	if not hit_applied:
		return

	if request.trigger_mode == TriggerActionCardData.TriggerMode.ON_HIT:
		_trigger_payload(global_position, _get_move_direction())

	if request.explosion_radius > 0.0:
		_apply_explosion_hits(global_position)
		_spawn_explosion_radius_indicator()

	if pierce_left > 0:
		pierce_left -= 1
		return

	queue_free()


func _apply_enemy_hit(hit_source: Node) -> bool:
	var enemy := _find_enemy_source(hit_source)
	if enemy == null or not enemy.has_method("apply_hit"):
		return false

	var hit := HitData.new()
	hit.damage = request.damage
	hit.hit_point = global_position
	hit.hit_direction = _get_move_direction()
	hit.knockback_force = request.knockback_force
	hit.source = self
	return bool(enemy.call("apply_hit", hit))


func _find_enemy_source(source: Node) -> Node:
	var node := source
	while node != null:
		if node.is_in_group(&"enemy"):
			return node
		node = node.get_parent()
	return null


func _apply_explosion_hits(origin: Vector2) -> void:
	if request == null or request.explosion_damage <= 0.0:
		return

	var radius_squared := request.explosion_radius * request.explosion_radius
	for enemy in get_tree().get_nodes_in_group(&"enemy"):
		if not enemy is Node2D or not enemy.has_method("apply_hit"):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node.global_position.distance_squared_to(origin) > radius_squared:
			continue

		var hit := HitData.new()
		hit.damage = request.explosion_damage
		hit.hit_point = origin
		hit.hit_direction = (enemy_node.global_position - origin).normalized()
		if hit.hit_direction == Vector2.ZERO:
			hit.hit_direction = _get_move_direction()
		hit.knockback_force = 0.0
		hit.source = self
		enemy.call("apply_hit", hit)


func _trigger_payload(origin: Vector2, direction: Vector2) -> void:
	_payload_triggered = true
	if request.trigger_payload.is_empty() or payload_factory == null:
		return
	payload_factory.spawn_trigger_payload(request.trigger_payload, origin, direction, request.direction)


func _spawn_explosion_radius_indicator() -> void:
	var indicator := ExplosionRadiusIndicator.new()
	indicator.explosion_radius = request.explosion_radius
	indicator.color = request.projectile_color
	var explosion_position := global_position

	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		return
	parent.add_child(indicator)
	indicator.global_position = explosion_position


func _get_move_direction() -> Vector2:
	var direction := velocity.normalized()
	if direction == Vector2.ZERO and request != null:
		direction = request.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	return direction


class ExplosionRadiusIndicator:
	extends Node2D

	const LIFETIME := 0.28

	var explosion_radius: float = 16.0
	var color: Color = Color.WHITE
	var _time_remaining := LIFETIME


	func _ready() -> void:
		queue_redraw()


	func _process(delta: float) -> void:
		_time_remaining -= delta
		if _time_remaining <= 0.0:
			queue_free()
			return
		queue_redraw()


	func _draw() -> void:
		var progress := 1.0 - clampf(_time_remaining / LIFETIME, 0.0, 1.0)
		var alpha := lerpf(0.55, 0.0, progress)
		var ring_color := Color(color.r, color.g, color.b, alpha)
		var fill_color := Color(color.r, color.g, color.b, alpha * 0.18)
		draw_circle(Vector2.ZERO, explosion_radius, fill_color)
		draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 64, ring_color, 2.0)
