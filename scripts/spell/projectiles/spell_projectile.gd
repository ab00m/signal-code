class_name SpellProjectile
extends Node2D

var request: SpawnRequest
var velocity: Vector2 = Vector2.ZERO
var lifetime_remaining: float = 1.0


func configure(spawn_request: SpawnRequest) -> void:
	request = spawn_request.duplicate_request()
	global_position = request.origin
	velocity = request.direction.normalized() * request.speed
	lifetime_remaining = request.lifetime
	queue_redraw()


func _ready() -> void:
	if request == null:
		queue_free()


func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
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
