extends Node2D

@export var wand_data: WandData

@onready var caster: Marker2D = %Caster
@onready var projectile_factory: ProjectileFactory = %ProjectileFactory
@onready var wand_runtime: WandRuntime = %WandRuntime
@onready var status_label: Label = %StatusLabel
@onready var log_label: RichTextLabel = %LogLabel

var _last_request_count: int = -1
var _target_positions: Array[Vector2] = [
	Vector2(470.0, 150.0),
	Vector2(500.0, 235.0),
]


func _ready() -> void:
	if wand_data == null:
		wand_data = _build_default_wand()
	wand_runtime.wand_data = wand_data
	wand_runtime.projectile_factory = projectile_factory
	_build_debug_targets()
	_update_hud()


func _process(_delta: float) -> void:
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_cast_toward_mouse()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_cast_toward_mouse()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.12, 1.0), true)
	draw_line(Vector2(0.0, caster.position.y), Vector2(size.x, caster.position.y), Color(0.18, 0.24, 0.26, 1.0), 1.0)
	draw_line(Vector2(caster.position.x, 0.0), Vector2(caster.position.x, size.y), Color(0.18, 0.24, 0.26, 1.0), 1.0)
	draw_circle(caster.position, 12.0, Color(0.95, 0.93, 0.62, 1.0))
	draw_arc(caster.position, 16.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.55), 1.5)

	var aim_direction := _get_aim_direction()
	draw_line(caster.position, caster.position + aim_direction * 48.0, Color(0.95, 0.93, 0.62, 0.8), 2.0)

	for target_position in _target_positions:
		draw_circle(target_position, 14.0, Color(0.95, 0.28, 0.32, 0.9))
		draw_arc(target_position, 18.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.45), 1.5)


func _cast_toward_mouse() -> void:
	var origin := caster.global_position
	var requests := wand_runtime.cast_once(self, origin, _get_aim_direction())
	_last_request_count = requests.size()
	_update_hud()


func _get_aim_direction() -> Vector2:
	var direction := caster.global_position.direction_to(get_global_mouse_position())
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	return direction.normalized()


func _update_hud() -> void:
	var deck_size := 0
	var deck_index := 0
	if wand_data != null:
		deck_size = wand_data.deck.size()
		deck_index = wand_runtime.get_deck_index()

	var request_text := ""
	if _last_request_count >= 0:
		request_text = "\n上次发射请求数：%d" % _last_request_count

	status_label.text = "Noita 风格法术沙盒\n施法：空格 / 回车 / 鼠标左键\n牌组索引：%d / %d\n冷却剩余：%.2f 秒%s\n\n%s" % [
		deck_index,
		deck_size,
		wand_runtime.get_cooldown_remaining(),
		request_text,
		_get_deck_text(deck_index),
	]

	var log_text := ""
	for line in wand_runtime.last_debug_lines:
		log_text += line + "\n"
	log_label.text = log_text


func _get_deck_text(deck_index: int) -> String:
	if wand_data == null or wand_data.deck.is_empty():
		return "牌组：空"

	var lines := "牌组：\n"
	for index in range(wand_data.deck.size()):
		var card := wand_data.deck[index]
		var marker := "  "
		if index == deck_index:
			marker = "> "
		lines += "%s%02d %s\n" % [marker, index + 1, card.get_display_name()]
	return lines


func _build_default_wand() -> WandData:
	var wand := WandData.new()
	wand.draws_per_cast = 1
	wand.cast_delay = 0.08
	wand.recharge_time = 0.12
	wand.deck = [
		_modifier(&"damage_up", "伤害提升", ModifierCardData.ModifierType.DAMAGE_MULTIPLY, 1.5, 0),
		_action(&"spark_bolt", "火花弹", 5.0, 480.0, 1.0, 4.0, 1, 0.0, 0.0, Color(0.45, 0.8, 1.0, 1.0)),
		_modifier(&"double_cast", "双重施放", ModifierCardData.ModifierType.MULTICAST, 0.0, 2),
		_modifier(&"damage_up", "伤害提升", ModifierCardData.ModifierType.DAMAGE_MULTIPLY, 1.5, 0),
		_action(&"spark_bolt", "火花弹", 5.0, 480.0, 1.0, 4.0, 1, 0.0, 0.0, Color(0.45, 0.8, 1.0, 1.0)),
		_action(&"fireball", "火球", 12.0, 330.0, 1.4, 8.0, 1, 0.0, 18.0, Color(1.0, 0.42, 0.18, 1.0)),
		_modifier(&"echo", "回响", ModifierCardData.ModifierType.ECHO, 0.28, 0),
		_trigger_action(&"timer_bolt", "计时弹", TriggerActionCardData.TriggerMode.ON_TIMER, 0.35, 1, 4.0, 360.0, 1.2, 5.0, Color(0.65, 0.48, 1.0, 1.0)),
		_modifier(&"spread", "散射", ModifierCardData.ModifierType.ADD_SPREAD, 18.0, 0),
		_action(&"fireball", "火球", 12.0, 330.0, 1.4, 8.0, 1, 0.0, 18.0, Color(1.0, 0.42, 0.18, 1.0)),
		_trigger_action(&"trigger_bolt", "触发弹", TriggerActionCardData.TriggerMode.ON_HIT, 0.0, 1, 4.0, 440.0, 1.4, 5.0, Color(0.62, 1.0, 0.55, 1.0)),
		_modifier(&"damage_up", "伤害提升", ModifierCardData.ModifierType.DAMAGE_MULTIPLY, 1.5, 0),
		_action(&"bomb", "炸弹", 25.0, 210.0, 1.8, 10.0, 1, 0.0, 30.0, Color(0.9, 0.78, 0.24, 1.0)),
		_modifier(&"speed_up", "速度提升", ModifierCardData.ModifierType.SPEED_MULTIPLY, 1.35, 0),
		_modifier(&"plus_one", "弹丸数量 +1", ModifierCardData.ModifierType.ADD_PROJECTILE_COUNT, 0.0, 1),
		_action(&"spark_bolt", "火花弹", 5.0, 480.0, 1.0, 4.0, 1, 0.0, 0.0, Color(0.45, 0.8, 1.0, 1.0)),
	]
	return wand


func _action(
	id: StringName,
	display_name: String,
	damage: float,
	speed: float,
	lifetime: float,
	radius: float,
	projectile_count: int,
	spread_degrees: float,
	explosion_radius: float,
	projectile_color: Color
) -> ActionCardData:
	var card := ActionCardData.new()
	card.id = id
	card.display_name = display_name
	card.damage = damage
	card.speed = speed
	card.lifetime = lifetime
	card.radius = radius
	card.projectile_count = projectile_count
	card.spread_degrees = spread_degrees
	card.explosion_radius = explosion_radius
	card.projectile_color = projectile_color
	return card


func _trigger_action(
	id: StringName,
	display_name: String,
	trigger_mode,
	timer_delay: float,
	payload_action_count: int,
	damage: float,
	speed: float,
	lifetime: float,
	radius: float,
	projectile_color: Color
) -> TriggerActionCardData:
	var card := TriggerActionCardData.new()
	card.id = id
	card.display_name = display_name
	card.trigger_mode = trigger_mode
	card.timer_delay = timer_delay
	card.payload_action_count = payload_action_count
	card.damage = damage
	card.speed = speed
	card.lifetime = lifetime
	card.radius = radius
	card.projectile_count = 1
	card.spread_degrees = 0.0
	card.explosion_radius = 0.0
	card.projectile_color = projectile_color
	return card


func _modifier(
	id: StringName,
	display_name: String,
	modifier_type,
	value_float: float,
	value_int: int
) -> ModifierCardData:
	var card := ModifierCardData.new()
	card.id = id
	card.display_name = display_name
	card.modifier_type = modifier_type
	card.value_float = value_float
	card.value_int = value_int
	return card


func _build_debug_targets() -> void:
	for index in range(_target_positions.size()):
		var target := Area2D.new()
		target.name = "DebugTarget%d" % (index + 1)
		target.position = _target_positions[index]
		target.collision_layer = 1
		target.collision_mask = 0
		target.monitoring = false
		target.monitorable = true

		var circle := CircleShape2D.new()
		circle.radius = 16.0

		var collision_shape := CollisionShape2D.new()
		collision_shape.shape = circle
		target.add_child(collision_shape)
		add_child(target)
