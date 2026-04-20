class_name EnemyBase
extends Area2D

signal spawned(enemy: EnemyBase)
signal damaged(enemy: EnemyBase, damage: float, current_hp: float)
signal died(enemy: EnemyBase)
signal contacted_player(enemy: EnemyBase)

@export var config: EnemyConfig
@export var knockback_decay: float = 520.0
@export var contact_reenable_delay: float = 0.35

var player: Node2D
var drop_receiver: Node
var boss_reset_anchor: Node2D
var current_hp: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var is_dead: bool = false
var is_contact_disabled: bool = false
var has_entered_active_window: bool = false
var spawn_origin: Vector2 = Vector2.ZERO

var _collision_shape: CollisionShape2D
var _body_root: Node2D
var _body_instance: Node2D
var _body_collision_source: CollisionShape2D
var _flash_timer: float = 0.0
var _flash_duration: float = 0.0
var _contact_disable_timer: float = 0.0


func _ready() -> void:
	_configure_area()
	if config != null:
		_apply_config()


func setup(enemy_config: EnemyConfig, player_ref: Node2D, services: Dictionary = {}) -> void:
	config = enemy_config
	player = player_ref
	drop_receiver = services.get("drop_receiver", player) as Node
	boss_reset_anchor = services.get("boss_reset_anchor", null) as Node2D
	spawn_origin = global_position
	_apply_config()
	spawned.emit(self)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_active_window_state()
	_update_timers(delta)
	var seek_velocity := _compute_seek_velocity()
	var separation_velocity := _compute_separation_velocity()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	velocity = seek_velocity + separation_velocity + knockback_velocity
	global_position += velocity * delta
	queue_redraw()


func _draw() -> void:
	if config == null or _body_instance != null:
		return

	var body_color := config.body_color
	var outline_color := config.outline_color
	if _flash_timer > 0.0 and _flash_duration > 0.0:
		var flash_ratio := clampf(_flash_timer / _flash_duration, 0.0, 1.0)
		var intensity := clampf(config.hit_flash_intensity, 0.0, 1.0)
		body_color = body_color.lerp(Color.WHITE, flash_ratio * intensity)

	var radius := maxf(1.0, config.collision_radius)
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 36, outline_color, 1.5)
	if _is_boss():
		draw_line(Vector2(-radius * 0.62, 0.0), Vector2(radius * 0.62, 0.0), Color(1.0, 1.0, 1.0, 0.75), 2.0)
		draw_line(Vector2(0.0, -radius * 0.62), Vector2(0.0, radius * 0.62), Color(1.0, 1.0, 1.0, 0.75), 2.0)


func apply_hit(hit: HitData) -> bool:
	if is_dead or not can_receive_combat_effects():
		return false

	var damage_amount := maxf(0.0, hit.damage)
	current_hp -= damage_amount
	_flash_timer = maxf(0.0, config.hit_flash_duration)
	_flash_duration = _flash_timer

	var hit_direction := hit.hit_direction.normalized()
	if hit_direction == Vector2.ZERO and hit.source is Node2D:
		hit_direction = (global_position - (hit.source as Node2D).global_position).normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.LEFT
	if not _is_boss():
		knockback_velocity += hit_direction * hit.knockback_force * config.knockback_multiplier

	damaged.emit(self, damage_amount, current_hp)
	if current_hp <= 0.0:
		die(hit)
	return true


func die(hit: HitData = null) -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(self)
	_spawn_death_rewards()
	queue_free()


func die_by_screen_clear() -> void:
	if is_dead:
		return
	is_dead = true
	queue_free()


func on_player_screen_clear() -> void:
	if is_dead:
		return
	if _is_boss():
		reset_to_anchor()
	else:
		die_by_screen_clear()


func reset_to_anchor() -> void:
	if boss_reset_anchor == null:
		boss_reset_anchor = _resolve_boss_reset_anchor()
	if boss_reset_anchor == null:
		return

	global_position = boss_reset_anchor.global_position
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	is_contact_disabled = true
	_contact_disable_timer = contact_reenable_delay
	queue_redraw()


func can_contact_player() -> bool:
	return not is_dead and not is_contact_disabled


func can_be_targeted() -> bool:
	return not is_dead and has_entered_active_window


func can_receive_combat_effects() -> bool:
	return not is_dead and _is_inside_active_window()


func _configure_area() -> void:
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true

	if _body_root == null:
		_body_root = Node2D.new()
		_body_root.name = "BodyRoot"
		add_child(_body_root)

	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)


func _apply_config() -> void:
	if config == null:
		return

	_configure_area()
	current_hp = maxf(1.0, config.max_hp)
	if _collision_shape.shape == null:
		_collision_shape.shape = CircleShape2D.new()
	var circle := _collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = maxf(1.0, config.collision_radius)

	add_to_group(&"enemy")
	if _is_boss():
		add_to_group(&"boss")
		set_meta(&"ignore_player_screen_clear", true)
	else:
		remove_from_group(&"boss")
		if has_meta(&"ignore_player_screen_clear"):
			remove_meta(&"ignore_player_screen_clear")

	_rebuild_body_scene()
	queue_redraw()


func _rebuild_body_scene() -> void:
	if _body_instance != null:
		_body_instance.queue_free()
		_body_instance = null
	_body_collision_source = null
	if config.body_scene == null or _body_root == null:
		return

	var instance := config.body_scene.instantiate()
	if instance is Node2D:
		_body_instance = instance as Node2D
		var scale_factor := maxf(0.01, config.body_scale)
		_body_instance.scale *= Vector2(scale_factor, scale_factor)
		_body_root.add_child(_body_instance)
		_apply_body_scene_collision_shape()
	else:
		instance.queue_free()


func _apply_body_scene_collision_shape() -> void:
	if _body_instance == null or _collision_shape == null:
		return

	var source_collision := _find_first_collision_shape(_body_instance)
	if source_collision == null or source_collision.shape == null:
		return

	_body_collision_source = source_collision
	_collision_shape.shape = source_collision.shape.duplicate()
	_collision_shape.transform = global_transform.affine_inverse() * source_collision.global_transform
	_disable_body_scene_collision(source_collision)


func _find_first_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		return node as CollisionShape2D

	for child in node.get_children():
		var collision := _find_first_collision_shape(child)
		if collision != null:
			return collision
	return null


func _disable_body_scene_collision(source_collision: CollisionShape2D) -> void:
	source_collision.disabled = true
	var owner := source_collision.get_parent()
	if owner is Area2D:
		var area := owner as Area2D
		area.collision_layer = 0
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = false


func _update_timers(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
	if _contact_disable_timer > 0.0:
		_contact_disable_timer = maxf(0.0, _contact_disable_timer - delta)
		if _contact_disable_timer <= 0.0:
			is_contact_disabled = false


func _update_active_window_state() -> void:
	if has_entered_active_window:
		return
	if _is_inside_active_window():
		has_entered_active_window = true


func _is_inside_active_window() -> bool:
	var visible_rect := get_viewport().get_visible_rect()
	return visible_rect.has_point(global_position)


func _compute_seek_velocity() -> Vector2:
	if player == null or not player.is_inside_tree() or config == null:
		return Vector2.ZERO

	var direction := global_position.direction_to(player.global_position)
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction * config.move_speed


func _compute_separation_velocity() -> Vector2:
	if config == null or config.separation_radius <= 0.0:
		return Vector2.ZERO

	var result := Vector2.ZERO
	for node in get_tree().get_nodes_in_group(&"enemy"):
		if node == self or not (node is Node2D):
			continue
		var other := node as Node2D
		if other.is_queued_for_deletion() or not other.is_inside_tree():
			continue

		var offset := global_position - other.global_position
		var distance := offset.length()
		if distance <= 0.001 or distance >= config.separation_radius:
			continue

		var weight := 1.0 - distance / config.separation_radius
		result += offset.normalized() * weight

	if result == Vector2.ZERO:
		return Vector2.ZERO
	return result.normalized() * config.separation_strength


func _spawn_death_rewards() -> void:
	if config == null or drop_receiver == null:
		return

	if config.guaranteed_xp_drop > 0 and drop_receiver.has_method("add_xp"):
		drop_receiver.call("add_xp", config.guaranteed_xp_drop)

	if not drop_receiver.has_method("add_gold"):
		return
	var gold_drop_chance := config.gold_drop_chance
	if drop_receiver.has_method("get_gold_drop_chance_bonus"):
		gold_drop_chance += float(drop_receiver.call("get_gold_drop_chance_bonus"))
	gold_drop_chance = clampf(gold_drop_chance, 0.0, 1.0)
	if gold_drop_chance <= 0.0:
		return
	if randf() > gold_drop_chance:
		return

	var min_amount := mini(config.gold_drop_amount_min, config.gold_drop_amount_max)
	var max_amount := maxi(config.gold_drop_amount_min, config.gold_drop_amount_max)
	var amount := randi_range(maxi(0, min_amount), maxi(0, max_amount))
	if amount > 0:
		drop_receiver.call("add_gold", amount)


func _resolve_boss_reset_anchor() -> Node2D:
	if config == null or config.boss_reset_anchor_path.is_empty():
		return null
	return get_node_or_null(config.boss_reset_anchor_path) as Node2D


func _is_boss() -> bool:
	return config != null and config.enemy_type == EnemyType.Value.BOSS
