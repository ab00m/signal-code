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
@export var enemy_locator_path: NodePath
@export var wand_runtime_path: NodePath
@export var screen_clear_service_path: NodePath
@export var settings_path: NodePath
@export var run_modifier_controller_path: NodePath
@export var experience_system_path: NodePath

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
var run_modifier_controller: RunModifierController
var experience_system: ExperienceSystem

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


func bind_dependencies(
	locator: EnemyLocator,
	runtime: WandRuntime,
	clear_service: ScreenClearService,
	settings_ref: GameSettings,
	modifier_ref: RunModifierController = null,
	experience_ref: ExperienceSystem = null
) -> void:
	enemy_locator = locator
	wand_runtime = runtime
	screen_clear_service = clear_service
	settings = settings_ref
	run_modifier_controller = modifier_ref
	experience_system = experience_ref


func reset_player() -> void:
	current_hp = maxi(1, get_effective_max_hp())
	current_xp = 0
	current_gold = 0
	is_dead = false
	cast_cd_timer = 0.0
	hurt_invincible_timer = 0.0
	_last_cast_direction = _normalized_or_idle(idle_cast_direction)
	_last_target_name = "none"
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hp_changed.emit(current_hp, get_effective_max_hp())
	xp_changed.emit(current_xp)
	gold_changed.emit(current_gold)


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


func reset_cast_cooldown() -> void:
	var cast_rate_multiplier := 1.0
	if run_modifier_controller != null:
		cast_rate_multiplier = run_modifier_controller.get_cast_rate_multiplier()
	cast_cd_timer = maxf(0.0, cast_cooldown / cast_rate_multiplier)


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
	hp_changed.emit(current_hp, get_effective_max_hp())
	damaged.emit(current_hp)

	if current_hp <= 0:
		die()
		return

	trigger_screen_clear()


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	if experience_system != null:
		experience_system.add_exp(float(amount))
		current_xp = floori(experience_system.current_exp)
		xp_changed.emit(current_xp)
		return
	current_xp += amount
	xp_changed.emit(current_xp)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	current_gold += amount
	gold_changed.emit(current_gold)


func get_effective_max_hp() -> int:
	var bonus := 0
	if run_modifier_controller != null:
		bonus = run_modifier_controller.get_max_hp_bonus()
	return maxi(1, max_hp + bonus)


func sync_runtime_modifiers() -> void:
	var effective_max_hp := get_effective_max_hp()
	current_hp = clampi(current_hp, 0, effective_max_hp)
	hp_changed.emit(current_hp, effective_max_hp)


func restore_hit(amount: int = 1) -> void:
	if amount <= 0 or is_dead:
		return
	var effective_max_hp := get_effective_max_hp()
	var previous_hp := current_hp
	current_hp = mini(effective_max_hp, current_hp + amount)
	if current_hp != previous_hp:
		hp_changed.emit(current_hp, effective_max_hp)


func get_gold_drop_chance_bonus() -> float:
	if run_modifier_controller == null:
		return 0.0
	return run_modifier_controller.get_gold_drop_chance_bonus()


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
	if not run_modifier_controller_path.is_empty():
		run_modifier_controller = get_node_or_null(run_modifier_controller_path) as RunModifierController
	if not experience_system_path.is_empty():
		experience_system = get_node_or_null(experience_system_path) as ExperienceSystem


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
