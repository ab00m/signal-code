class_name DebugEnemy
extends Area2D

@export var is_boss: bool = false
@export var move_speed: float = 64.0
@export var radius: float = 14.0
@export var enemy_color: Color = Color(0.95, 0.22, 0.28, 1.0)
@export var boss_color: Color = Color(0.86, 0.36, 1.0, 1.0)

var target: Node2D


func configure(start_position: Vector2, boss: bool, target_node: Node2D) -> void:
	global_position = start_position
	is_boss = boss
	target = target_node
	if is_boss:
		radius = 26.0
		move_speed = 64.0


func _ready() -> void:
	add_to_group(&"enemy")
	if is_boss:
		add_to_group(&"boss")
		set_meta(&"ignore_player_screen_clear", true)

	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
	_add_collision_shape()
	queue_redraw()


func _process(delta: float) -> void:
	if target == null or not target.is_inside_tree():
		return
	var direction := global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		return
	global_position += direction * move_speed * delta


func _draw() -> void:
	var color := boss_color if is_boss else enemy_color
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.55), 1.5)
	if is_boss:
		draw_line(Vector2(-radius * 0.6, 0.0), Vector2(radius * 0.6, 0.0), Color(1.0, 1.0, 1.0, 0.75), 2.0)


func die_by_screen_clear() -> void:
	if is_boss:
		return
	queue_free()


func _add_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
