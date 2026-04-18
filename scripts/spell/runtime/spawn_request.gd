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
var explosion_radius: float = 0.0
var projectile_color: Color = Color(1.0, 1.0, 1.0, 1.0)


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
	request.explosion_radius = explosion_radius
	request.projectile_color = projectile_color
	return request
