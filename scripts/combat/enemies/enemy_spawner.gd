class_name EnemySpawner
extends Node

@export var enemy_parent_path: NodePath
@export var player_path: NodePath
@export var drop_receiver_path: NodePath
@export var boss_spawn_anchor_path: NodePath
@export var boss_reset_anchor_path: NodePath
@export var spawn_margin: float = 60.0
@export var vertical_padding: float = 34.0

var normal_configs: Array[EnemyConfig] = []
var elite_configs: Array[EnemyConfig] = []
var boss_config: EnemyConfig


func spawn_enemy(enemy_config: EnemyConfig, position: Vector2) -> EnemyBase:
	if enemy_config == null:
		return null

	var parent := get_enemy_parent()
	var enemy := EnemyBase.new()
	enemy.name = _build_enemy_name(enemy_config)
	enemy.global_position = position
	parent.add_child(enemy)
	enemy.setup(enemy_config, get_player(), {
		"drop_receiver": get_drop_receiver(),
		"boss_reset_anchor": get_boss_reset_anchor(),
	})
	return enemy


func spawn_normal_random_y(enemy_config: EnemyConfig = null) -> EnemyBase:
	var selected := enemy_config
	if selected == null:
		selected = _pick_weighted_config(normal_configs)
	return spawn_enemy(selected, _get_right_edge_random_y_position())


func spawn_elite(enemy_config: EnemyConfig = null) -> EnemyBase:
	var selected := enemy_config
	if selected == null:
		selected = _pick_weighted_config(elite_configs)
	return spawn_enemy(selected, _get_right_edge_random_y_position())


func spawn_boss(enemy_config: EnemyConfig = null, anchor: Node2D = null) -> EnemyBase:
	var selected := enemy_config
	if selected == null:
		selected = boss_config
	if anchor == null:
		anchor = get_boss_spawn_anchor()

	var position := _get_right_edge_random_y_position()
	if anchor != null:
		position = anchor.global_position
	return spawn_enemy(selected, position)


func get_enemy_parent() -> Node:
	if not enemy_parent_path.is_empty():
		var parent := get_node_or_null(enemy_parent_path)
		if parent != null:
			return parent
	return get_parent()


func get_player() -> Node2D:
	if player_path.is_empty():
		return null
	return get_node_or_null(player_path) as Node2D


func get_drop_receiver() -> Node:
	if not drop_receiver_path.is_empty():
		var receiver := get_node_or_null(drop_receiver_path)
		if receiver != null:
			return receiver
	return get_player()


func get_boss_spawn_anchor() -> Node2D:
	if boss_spawn_anchor_path.is_empty():
		return null
	return get_node_or_null(boss_spawn_anchor_path) as Node2D


func get_boss_reset_anchor() -> Node2D:
	if boss_reset_anchor_path.is_empty():
		return null
	return get_node_or_null(boss_reset_anchor_path) as Node2D


func _get_right_edge_random_y_position() -> Vector2:
	var rect := get_viewport().get_visible_rect()
	var min_y := rect.position.y + vertical_padding
	var max_y := rect.position.y + rect.size.y - vertical_padding
	if max_y < min_y:
		max_y = min_y
	return Vector2(rect.position.x + rect.size.x + spawn_margin, randf_range(min_y, max_y))


func _pick_weighted_config(configs: Array[EnemyConfig]) -> EnemyConfig:
	if configs.is_empty():
		return null

	var total_weight := 0.0
	for enemy_config in configs:
		if enemy_config != null:
			total_weight += maxf(0.0, enemy_config.spawn_weight)

	if total_weight <= 0.0:
		return configs[0]

	var roll := randf() * total_weight
	for enemy_config in configs:
		if enemy_config == null:
			continue
		roll -= maxf(0.0, enemy_config.spawn_weight)
		if roll <= 0.0:
			return enemy_config

	return configs[configs.size() - 1]


func _build_enemy_name(enemy_config: EnemyConfig) -> String:
	var base_name := "Enemy"
	if enemy_config.display_name != "":
		base_name = enemy_config.display_name
	elif enemy_config.enemy_id != &"":
		base_name = String(enemy_config.enemy_id)
	return base_name
