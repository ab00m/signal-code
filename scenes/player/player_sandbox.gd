extends Node2D

const NORMAL_ENEMY_CONFIG := preload("res://resources/enemies/enemy_normal_signal.tres")
const ELITE_ENEMY_CONFIG := preload("res://resources/enemies/enemy_elite_signal.tres")
const BOSS_ENEMY_CONFIG := preload("res://resources/enemies/enemy_boss_signal.tres")
const DEFAULT_WAND: WandData = preload("res://resources/spells/wands/player_sandbox_wand.tres")

@onready var player: Player = %Player
@onready var projectile_factory: ProjectileFactory = %ProjectileFactory
@onready var wand_runtime: WandRuntime = %WandRuntime
@onready var enemy_locator: EnemyLocator = %EnemyLocator
@onready var screen_clear_service: ScreenClearService = %ScreenClearService
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var game_settings: GameSettings = %GameSettings
@onready var status_label: Label = %StatusLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var auto_aim_check_box: CheckBox = %AutoAimCheckBox
@onready var result_label: Label = %ResultLabel

var _damage_events: int = 0
var _screen_clear_events: int = 0


func _ready() -> void:
	wand_runtime.wand_data = DEFAULT_WAND.duplicate(true) as WandData
	wand_runtime.projectile_factory = projectile_factory
	player.bind_dependencies(enemy_locator, wand_runtime, screen_clear_service, game_settings)
	_configure_enemy_spawner()
	_connect_player_signals()
	_connect_ui()
	_reset_sandbox()


func _process(_delta: float) -> void:
	_update_hud()
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.09, 0.1, 1.0), true)
	draw_line(Vector2(0.0, player.global_position.y), Vector2(size.x, player.global_position.y), Color(0.18, 0.22, 0.23, 1.0), 1.0)
	draw_line(Vector2(player.global_position.x, 0.0), Vector2(player.global_position.x, size.y), Color(0.18, 0.22, 0.23, 1.0), 1.0)


func _connect_player_signals() -> void:
	if not player.damaged.is_connected(_on_player_damaged):
		player.damaged.connect(_on_player_damaged)
	if not player.screen_cleared.is_connected(_on_player_screen_cleared):
		player.screen_cleared.connect(_on_player_screen_cleared)
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if not player.cast_requested.is_connected(_on_player_cast_requested):
		player.cast_requested.connect(_on_player_cast_requested)


func _connect_ui() -> void:
	auto_aim_check_box.button_pressed = game_settings.auto_aim_enabled
	if not auto_aim_check_box.toggled.is_connected(_on_auto_aim_toggled):
		auto_aim_check_box.toggled.connect(_on_auto_aim_toggled)
	if not %ResetButton.pressed.is_connected(_reset_sandbox):
		%ResetButton.pressed.connect(_reset_sandbox)
	if not %SpawnButton.pressed.is_connected(_spawn_enemy_wave):
		%SpawnButton.pressed.connect(_spawn_enemy_wave)


func _configure_enemy_spawner() -> void:
	enemy_spawner.normal_configs.clear()
	enemy_spawner.normal_configs.append(NORMAL_ENEMY_CONFIG)
	enemy_spawner.elite_configs.clear()
	enemy_spawner.elite_configs.append(ELITE_ENEMY_CONFIG)
	enemy_spawner.boss_config = BOSS_ENEMY_CONFIG


func _reset_sandbox() -> void:
	_clear_enemies()
	_damage_events = 0
	_screen_clear_events = 0
	wand_runtime.reset_runtime()
	player.reset_player()
	result_label.visible = false
	_spawn_enemy_wave()
	_update_hud()


func _spawn_enemy_wave() -> void:
	enemy_spawner.spawn_normal_random_y(NORMAL_ENEMY_CONFIG)
	enemy_spawner.spawn_normal_random_y(NORMAL_ENEMY_CONFIG)
	enemy_spawner.spawn_elite(ELITE_ENEMY_CONFIG)
	enemy_spawner.spawn_boss(BOSS_ENEMY_CONFIG)


func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group(&"enemy"):
		if node is Node:
			node.queue_free()


func _update_hud() -> void:
	var enemy_count := 0
	var boss_count := 0
	for node in get_tree().get_nodes_in_group(&"enemy"):
		if node is Node and not node.is_queued_for_deletion():
			enemy_count += 1
			if node.is_in_group(&"boss"):
				boss_count += 1

	var direction := player.get_last_cast_direction()
	status_label.text = (
		"玩家主角沙盒\n"
		+ "自动瞄准：%s\n" % ("开启" if game_settings.auto_aim_enabled else "关闭")
		+ "HP：%d / %d\n" % [player.current_hp, player.max_hp]
		+ "XP：%d  金币：%d\n" % [player.current_xp, player.current_gold]
		+ "无敌剩余：%.2f 秒\n" % player.hurt_invincible_timer
		+ "施法 CD：%.2f 秒\n" % player.cast_cd_timer
		+ "法杖 CD：%.2f 秒\n" % wand_runtime.get_cooldown_remaining()
		+ "上次方向：%s\n" % _format_vector(direction)
		+ "目标：%s\n" % player.get_last_target_name()
		+ "敌人：%d（Boss %d）\n" % [enemy_count, boss_count]
		+ "受伤次数：%d  清屏次数：%d" % [_damage_events, _screen_clear_events]
	)

	var log_text := ""
	for line in wand_runtime.last_debug_lines:
		log_text += line + "\n"
	log_label.text = log_text


func _format_vector(value: Vector2) -> String:
	return "(%.2f, %.2f)" % [value.x, value.y]


func _on_auto_aim_toggled(enabled: bool) -> void:
	game_settings.set_auto_aim_enabled(enabled)
	_update_hud()


func _on_player_damaged(_current_hp: int) -> void:
	_damage_events += 1
	_update_hud()


func _on_player_screen_cleared() -> void:
	_screen_clear_events += 1
	_update_hud()


func _on_player_died() -> void:
	result_label.visible = true
	result_label.text = "玩家死亡\n结算界面占位"
	_update_hud()


func _on_player_cast_requested(_direction: Vector2) -> void:
	_update_hud()
