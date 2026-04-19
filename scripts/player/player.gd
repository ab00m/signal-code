class_name Player
extends Node2D

signal hp_changed(current_hp: int, max_hp: int)
signal damaged(current_hp: int)
signal xp_changed(current_xp: int)
signal gold_changed(current_gold: int)
signal screen_cleared()
signal died()
signal cast_requested(direction: Vector2)

@export var max_hp: int = 3
@export var cast_cooldown: float = 0.35
@export var hurt_invincible_duration: float = 0.5
@export var idle_cast_direction: Vector2 = Vector2.RIGHT
@export var debug_draw_enabled: bool = true
@export var enemy_locator_path: NodePath
@export var wand_runtime_path: NodePath
@export var screen_clear_service_path: NodePath
@export var settings_path: NodePath

@onready var hurtbox: Area2D = %Hurtbox
@onready var cast_origin: Marker2D = %CastOrigin

var current_hp: int
var current_xp: int = 0
var current_gold: int = 0
var is_dead: bool = false
var cast_cd_timer: float = 0.0
var hurt_invincible_timer: float = 0.0
var enemy_locator: EnemyLocator
var wand_runtime: WandRuntime
var screen_clear_service: ScreenClearService
var settings: GameSettings

var _last_cast_direction: Vector2 = Vector2.RIGHT
var _last_target_name: String = "none"


func _ready() -> void:
	_resolve_dependencies()
	_connect_hurtbox()
	reset_player()


func _process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)
	if can_cast_now():
		perform_auto_cast()

	if debug_draw_enabled:
		queue_redraw()


func _draw() -> void:
	if not debug_draw_enabled:
		return

	var body_color := Color(0.24, 0.72, 1.0, 1.0)
	if is_dead:
		body_color = Color(0.25, 0.28, 0.32, 1.0)
	elif hurt_invincible_timer > 0.0:
		body_color = Color(1.0, 0.9, 0.36, 1.0)

	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.58), 1.5)

	var direction := _last_cast_direction.normalized()
	if direction == Vector2.ZERO:
		direction = idle_cast_direction.normalized()
	draw_line(Vector2.ZERO, direction * 72.0, Color(0.7, 1.0, 0.74, 0.9), 2.0)


func bind_dependencies(
	locator: EnemyLocator,
	runtime: WandRuntime,
	clear_service: ScreenClearService,
	settings_ref: GameSettings
) -> void:
	enemy_locator = locator
	wand_runtime = runtime
	screen_clear_service = clear_service
	settings = settings_ref


func reset_player() -> void:
	current_hp = maxi(1, max_hp)
	current_xp = 0
	current_gold = 0
	is_dead = false
	cast_cd_timer = 0.0
	hurt_invincible_timer = 0.0
	_last_cast_direction = _normalized_or_idle(idle_cast_direction)
	_last_target_name = "none"
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hp_changed.emit(current_hp, max_hp)
	xp_changed.emit(current_xp)
	gold_changed.emit(current_gold)
	queue_redraw()


func can_cast_now() -> bool:
	if is_dead or cast_cd_timer > 0.0:
		return false
	if wand_runtime != null:
		return wand_runtime.can_cast()
	return true


func perform_auto_cast() -> void:
	var direction := get_cast_direction()
	_last_cast_direction = direction
	if wand_runtime != null:
		wand_runtime.cast_once(self, cast_origin.global_position, direction)
	cast_requested.emit(direction)
	reset_cast_cooldown()
	queue_redraw()


func reset_cast_cooldown() -> void:
	cast_cd_timer = maxf(0.0, cast_cooldown)


func get_cast_direction() -> Vector2:
	var origin := cast_origin.global_position
	if _is_auto_aim_enabled():
		var enemy := _get_nearest_enemy(origin)
		if enemy != null:
			_last_target_name = enemy.name
			return _normalized_or_idle(enemy.global_position - origin)
		_last_target_name = "none"
		return _normalized_or_idle(idle_cast_direction)

	_last_target_name = "mouse"
	return _normalized_or_idle(get_global_mouse_position() - origin)


func take_damage_from_enemy(_source: Node) -> void:
	if is_dead or hurt_invincible_timer > 0.0:
		return

	current_hp = maxi(0, current_hp - 1)
	hurt_invincible_timer = hurt_invincible_duration
	hp_changed.emit(current_hp, max_hp)
	damaged.emit(current_hp)

	if current_hp <= 0:
		die()
		return

	trigger_screen_clear()
	queue_redraw()


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount
	xp_changed.emit(current_xp)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	current_gold += amount
	gold_changed.emit(current_gold)


func trigger_screen_clear() -> void:
	if screen_clear_service != null:
		screen_clear_service.execute_player_screen_clear()
	screen_cleared.emit()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	died.emit()
	queue_redraw()


func get_last_cast_direction() -> Vector2:
	return _last_cast_direction


func get_last_target_name() -> String:
	return _last_target_name


func _update_timers(delta: float) -> void:
	if hurt_invincible_timer > 0.0:
		hurt_invincible_timer = maxf(0.0, hurt_invincible_timer - delta)
	if cast_cd_timer > 0.0:
		cast_cd_timer = maxf(0.0, cast_cd_timer - delta)


func _connect_hurtbox() -> void:
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if not hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _resolve_dependencies() -> void:
	if not enemy_locator_path.is_empty():
		enemy_locator = get_node_or_null(enemy_locator_path) as EnemyLocator
	if not wand_runtime_path.is_empty():
		wand_runtime = get_node_or_null(wand_runtime_path) as WandRuntime
	if not screen_clear_service_path.is_empty():
		screen_clear_service = get_node_or_null(screen_clear_service_path) as ScreenClearService
	if not settings_path.is_empty():
		settings = get_node_or_null(settings_path) as GameSettings


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var enemy := _find_enemy_source(area)
	if enemy != null and _can_enemy_contact_player(enemy):
		take_damage_from_enemy(enemy)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	var enemy := _find_enemy_source(body)
	if enemy != null and _can_enemy_contact_player(enemy):
		take_damage_from_enemy(enemy)


func _find_enemy_source(source: Node) -> Node:
	var node := source
	while node != null and node != self:
		if node.is_in_group(&"enemy"):
			return node
		node = node.get_parent()
	return null


func _can_enemy_contact_player(enemy: Node) -> bool:
	if enemy.has_method("can_contact_player"):
		return bool(enemy.call("can_contact_player"))
	return true


func _get_nearest_enemy(from_position: Vector2) -> Node2D:
	if enemy_locator == null:
		return null
	return enemy_locator.get_nearest_enemy(from_position)


func _is_auto_aim_enabled() -> bool:
	if settings == null:
		return true
	return settings.auto_aim_enabled


func _normalized_or_idle(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.0001:
		return idle_cast_direction.normalized()
	return direction.normalized()
