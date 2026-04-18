class_name SpawnRequest
extends RefCounted

var source_card: ActionCardData
var display_name: String = ""
var origin: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var damage: float = 0.0
var speed: float = 0.0
var lifetime: float = 1.0
var radius: float = 4.0
var pierce: int = 0
var bounce: int = 0
var explosion_radius: float = 0.0
var projectile_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var on_hit_effects: Array[StringName] = []
var trigger_payload: Array[SpawnRequest] = []
var trigger_mode: int = -1
var trigger_delay: float = 0.0
var echo_delay: float = -1.0


func duplicate_request() -> SpawnRequest:
	var request := SpawnRequest.new()
	request.source_card = source_card
	request.display_name = display_name
	request.origin = origin
	request.direction = direction
	request.damage = damage
	request.speed = speed
	request.lifetime = lifetime
	request.radius = radius
	request.pierce = pierce
	request.bounce = bounce
	request.explosion_radius = explosion_radius
	request.projectile_color = projectile_color
	request.on_hit_effects = on_hit_effects.duplicate()
	for payload_request in trigger_payload:
		if payload_request != null:
			request.trigger_payload.append(payload_request.duplicate_request())
	request.trigger_mode = trigger_mode
	request.trigger_delay = trigger_delay
	request.echo_delay = echo_delay
	return request
