extends Control

signal level_lost
signal level_won(level_path: String)

const NORMAL_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_normal_signal.tres")
const FAST_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_fast_signal.tres")
const HEAVY_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_heavy_signal.tres")
const ELITE_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_elite_signal.tres")
const BOSS_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_boss_signal.tres")
const DAMAGE_UP_10: UpgradeOptionConfig = preload("res://resources/upgrades/damage_up_10.tres")
const RECHARGE_DOWN_01: UpgradeOptionConfig = preload("res://resources/upgrades/recharge_down_01.tres")
const KNOCKBACK_LEVEL_UP_1: UpgradeOptionConfig = preload("res://resources/upgrades/knockback_up_20.tres")
const AOE_UP_20: UpgradeOptionConfig = preload("res://resources/upgrades/aoe_up_20.tres")
const GOLD_BONUS_20: UpgradeOptionConfig = preload("res://resources/upgrades/gold_bonus_20.tres")
const MAX_HP_UP_1: UpgradeOptionConfig = preload("res://resources/upgrades/max_hp_up_1.tres")
const FALLBACK_DAMAGE_UP_5: UpgradeOptionConfig = preload("res://resources/upgrades/fallback_damage_up_5.tres")
const SPELL_CARD_DATABASE: SpellCardDatabase = preload("res://resources/spells/spell_card_database.tres")
const COMBAT_DEFAULT_WAND: WandData = preload("res://resources/spells/wands/combat_default_wand.tres")
const MAIN_MENU_SCENE_PATH := "res://scenes/menus/main_menu/main_menu.tscn"
const LEVEL_COUNT := 10
const DEFAULT_LEVEL_DURATION := 30.0
const FINAL_LEVEL_DURATION := -1.0
const LOW_ENEMY_COUNT_THRESHOLD := 10
const LOW_ENEMY_COUNT_INTERVAL_MULTIPLIER := 0.5
const LEVEL_TICK_SECONDS := 0.1
const ENEMY_HP_GROWTH_PER_TWO_LEVELS := 1.2
const DEBUG_GOLD_AMOUNT := 100
const DEBUG_EXP_AMOUNT := 10
const LEVEL_DEFS: Array[Dictionary] = [
	{
		"spawn_interval": 2.0,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [{"time": 20.0, "count": 1, "config": ELITE_ENEMY_CONFIG}],
	},
	{
		"spawn_interval": 1.6,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 3.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 1.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 10.0, "count": 2, "config": ELITE_ENEMY_CONFIG},
			{"time": 20.0, "count": 6, "same_type": true},
		],
	},
	{
		"spawn_interval": 1.4,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 3.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 3.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 3.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [{"time": 10.0, "count": 6}, {"time": 20.0, "count": 8}],
	},
	{
		"spawn_interval": 1.2,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 3.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 3.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 3.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6, "same_type": true},
			{"time": 15.0, "count": 8, "same_type": true},
			{"time": 25.0, "count": 10, "same_type": true},
		],
	},
	{
		"boss": true,
		"spawn_interval": 1.0,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 3.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 3.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 3.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
	{
		"spawn_interval": 0.8,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 4.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 4.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
	{
		"spawn_interval": 0.6,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 4.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 4.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
	{
		"spawn_interval": 0.6,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 4.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 4.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
	{
		"spawn_interval": 0.6,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 4.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 4.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
	{
		"boss": true,
		"duration": FINAL_LEVEL_DURATION,
		"boss_hp_multiplier": 4.0,
		"spawn_interval": 0.6,
		"spawn_pool": [
			{"config": NORMAL_ENEMY_CONFIG, "weight": 1.0},
			{"config": FAST_ENEMY_CONFIG, "weight": 4.0},
			{"config": HEAVY_ENEMY_CONFIG, "weight": 4.0},
			{"config": ELITE_ENEMY_CONFIG, "weight": 1.0},
		],
		"bursts": [
			{"time": 5.0, "count": 6},
			{"time": 15.0, "count": 8},
			{"time": 25.0, "count": 10},
		],
	},
]
const UPGRADE_POOL: Array[UpgradeOptionConfig] = [
	RECHARGE_DOWN_01,
	DAMAGE_UP_10,
	MAX_HP_UP_1,
	GOLD_BONUS_20,
	AOE_UP_20,
	KNOCKBACK_LEVEL_UP_1,
]

@export var start_delay: float = 0.8
@export var player_left_margin: float = 96.0
@export var boss_right_margin: float = 112.0

@onready var player: Player = %Player
@onready var player_spawn: Marker2D = %PlayerSpawn
@onready var boss_spawn: Marker2D = %BossSpawn
@onready var enemy_locator: EnemyLocator = %EnemyLocator
@onready var screen_clear_service: ScreenClearService = %ScreenClearService
@onready var settings: GameSettings = %GameSettings
@onready var run_modifier_controller: RunModifierController = %RunModifierController
@onready var experience_system: ExperienceSystem = %ExperienceSystem
@onready var upgrade_system: UpgradeSystem = %UpgradeSystem
@onready var upgrade_panel: UpgradeSelectionPanel = %UpgradeSelectionPanel
@onready var projectile_root: Node2D = %ProjectileRoot
@onready var projectile_factory: ProjectileFactory = %ProjectileFactory
@onready var wand_runtime: WandRuntime = %WandRuntime
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var title_label: Label = %TitleLabel
@onready var wave_label: Label = %WaveLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var player_label: Label = %PlayerLabel
@onready var experience_bar: ProgressBar = %ExperienceBar
@onready var boss_health_bar: ProgressBar = %BossHealthBar
@onready var level_timer_bar: ProgressBar = %LevelTimerBar
@onready var shop_button: Button = %ShopButton
@onready var debug_enemy_count_label: Label = %DebugEnemyCountLabel
@onready var debug_enemy_hp_scale_label: Label = %DebugEnemyHpScaleLabel
@onready var debug_damage_scale_label: Label = %DebugDamageScaleLabel
@onready var debug_add_gold_button: Button = %DebugAddGoldButton
@onready var debug_add_exp_button: Button = %DebugAddExpButton
@onready var spawn_log_check_button: CheckButton = %SpawnLogCheckButton
@onready var cast_log_check_button: CheckButton = %CastLogCheckButton
@onready var god_power_check_button: CheckButton = %GodPowerCheckButton
@onready var shop_layer: CanvasLayer = %ShopLayer
@onready var shop_page: ShopPage = %ShopPage
@onready var result_layer: CanvasLayer = %ResultLayer
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_summary_label: Label = %ResultSummaryLabel
@onready var result_stats_label: Label = %ResultStatsLabel
@onready var result_restart_button: Button = %ResultRestartButton
@onready var result_main_menu_button: Button = %ResultMainMenuButton

var active_enemies: Array[EnemyBase] = []
var boss_enemies: Array[EnemyBase] = []
var boss_enemy: EnemyBase
var current_level_boss_enemy: EnemyBase
var final_boss_enemy: EnemyBase
var current_wave_index: int = -1
var current_level_elapsed: float = 0.0
var status_text: String = "准备接收信号..."
var encounter_finished: bool = false
var is_spawning: bool = false
var spawn_log_enabled: bool = false
var cast_log_enabled: bool = false
var shop_run_state: RunState
var was_tree_paused_before_shop: bool = false


func _ready() -> void:
	randomize()
	_layout_combat_points()
	_configure_runtime()
	_connect_player_signals()
	_connect_result_buttons()
	_connect_debug_panel_signals()
	player.reset_player()
	_configure_shop_state()
	_connect_shop_signals()
	shop_layer.hide()
	result_layer.hide()
	_update_hud()
	call_deferred("_start_encounter")


func _process(_delta: float) -> void:
	_update_hud()


func _layout_combat_points() -> void:
	var rect := get_viewport_rect()
	var center_y := rect.size.y * 0.5
	var player_x := rect.position.x + player_left_margin
	var boss_x := rect.position.x + maxf(player_left_margin + 220.0, rect.size.x - boss_right_margin)

	player_spawn.global_position = Vector2(player_x, center_y)
	boss_spawn.global_position = Vector2(boss_x, center_y)
	player.global_position = player_spawn.global_position


func _configure_runtime() -> void:
	enemy_spawner.normal_configs = [NORMAL_ENEMY_CONFIG, FAST_ENEMY_CONFIG, HEAVY_ENEMY_CONFIG]
	enemy_spawner.elite_configs = [ELITE_ENEMY_CONFIG]
	enemy_spawner.boss_config = BOSS_ENEMY_CONFIG
	run_modifier_controller.reset_modifiers()
	experience_system.run_modifier_controller = run_modifier_controller
	experience_system.reset_progression()
	upgrade_system.upgrade_options = UPGRADE_POOL.duplicate()
	upgrade_system.fallback_option = FALLBACK_DAMAGE_UP_5
	upgrade_system.reset_run()
	upgrade_system.bind_dependencies(experience_system, run_modifier_controller, upgrade_panel, player)
	upgrade_system.start_run()
	wand_runtime.wand_data = COMBAT_DEFAULT_WAND.duplicate(true) as WandData
	wand_runtime.projectile_factory = projectile_factory
	wand_runtime.run_modifier_controller = run_modifier_controller
	wand_runtime.debug_enabled = cast_log_enabled
	player.bind_dependencies(
		enemy_locator,
		wand_runtime,
		screen_clear_service,
		settings,
		run_modifier_controller,
		experience_system
	)
	_connect_progression_signals()


func _configure_shop_state() -> void:
	shop_run_state = RunState.new()
	shop_run_state.spell_database = SPELL_CARD_DATABASE
	shop_run_state.gold = player.current_gold
	shop_run_state.inventory_capacity = 12
	shop_run_state.player_level = experience_system.current_level
	shop_run_state.spell_slot_count = shop_run_state.get_unlocked_spell_slot_count()
	shop_run_state.shop_state = ShopRuntimeState.new()
	shop_run_state.loadout_spell_entries = _build_spell_entries_from_wand(wand_runtime.wand_data)
	shop_run_state.inventory_spell_entries = []
	shop_page.configure(shop_run_state)


func _connect_player_signals() -> void:
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if not player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.connect(_on_player_hp_changed)
	if not player.xp_changed.is_connected(_on_player_xp_changed):
		player.xp_changed.connect(_on_player_xp_changed)
	if not player.gold_changed.is_connected(_on_player_gold_changed):
		player.gold_changed.connect(_on_player_gold_changed)


func _connect_progression_signals() -> void:
	if not experience_system.exp_changed.is_connected(_on_experience_changed):
		experience_system.exp_changed.connect(_on_experience_changed)
	if not experience_system.level_changed.is_connected(_on_level_changed):
		experience_system.level_changed.connect(_on_level_changed)
	if not run_modifier_controller.modifier_changed.is_connected(_on_modifier_changed):
		run_modifier_controller.modifier_changed.connect(_on_modifier_changed)
	if not upgrade_system.upgrade_applied.is_connected(_on_upgrade_applied):
		upgrade_system.upgrade_applied.connect(_on_upgrade_applied)


func _connect_shop_signals() -> void:
	if not shop_button.pressed.is_connected(_on_shop_button_pressed):
		shop_button.pressed.connect(_on_shop_button_pressed)
	if not shop_page.request_close_page.is_connected(_on_shop_closed):
		shop_page.request_close_page.connect(_on_shop_closed)
	if not shop_page.debug_experience_requested.is_connected(_on_shop_debug_experience_requested):
		shop_page.debug_experience_requested.connect(_on_shop_debug_experience_requested)


func _connect_debug_panel_signals() -> void:
	spawn_log_check_button.button_pressed = spawn_log_enabled
	cast_log_check_button.button_pressed = cast_log_enabled
	if not debug_add_gold_button.pressed.is_connected(_on_debug_add_gold_pressed):
		debug_add_gold_button.pressed.connect(_on_debug_add_gold_pressed)
	if not debug_add_exp_button.pressed.is_connected(_on_debug_add_exp_pressed):
		debug_add_exp_button.pressed.connect(_on_debug_add_exp_pressed)
	if not spawn_log_check_button.toggled.is_connected(_on_spawn_log_toggled):
		spawn_log_check_button.toggled.connect(_on_spawn_log_toggled)
	if not cast_log_check_button.toggled.is_connected(_on_cast_log_toggled):
		cast_log_check_button.toggled.connect(_on_cast_log_toggled)
	if not god_power_check_button.toggled.is_connected(_on_god_power_toggled):
		god_power_check_button.toggled.connect(_on_god_power_toggled)


func _start_encounter() -> void:
	status_text = "校准自动施法..."
	await get_tree().create_timer(start_delay, false).timeout

	for level_index in range(mini(LEVEL_COUNT, LEVEL_DEFS.size())):
		if encounter_finished:
			return
		current_wave_index = level_index
		await _run_level(LEVEL_DEFS[level_index])

	if not encounter_finished:
		_finish_encounter(true)


func _run_level(level_def: Dictionary) -> void:
	is_spawning = true
	current_level_elapsed = 0.0
	current_level_boss_enemy = null
	var level_number := current_wave_index + 1
	var is_final_level := level_number == LEVEL_COUNT
	var level_duration := float(level_def.get("duration", DEFAULT_LEVEL_DURATION))
	var is_boss_level := bool(level_def.get("boss", false))
	var triggered_bursts := {}
	var spawn_countdown := _get_spawn_interval_for_current_enemy_count(level_def)

	status_text = "第 %d 关开始" % level_number
	if is_boss_level:
		_spawn_level_boss(level_def, is_final_level)

	while not encounter_finished:
		if is_boss_level and current_level_boss_enemy == null:
			break
		if level_duration > 0.0 and current_level_elapsed >= level_duration:
			break

		await get_tree().create_timer(LEVEL_TICK_SECONDS, false).timeout
		if encounter_finished:
			break

		current_level_elapsed += LEVEL_TICK_SECONDS
		_process_level_bursts(level_def, triggered_bursts)
		spawn_countdown -= LEVEL_TICK_SECONDS
		if spawn_countdown <= 0.0:
			_spawn_level_pool_enemy(level_def)
			spawn_countdown = _get_spawn_interval_for_current_enemy_count(level_def)

	is_spawning = false
	if not encounter_finished:
		status_text = "第 %d 关结束" % level_number


func _spawn_level_boss(level_def: Dictionary, is_final_level: bool) -> void:
	var boss_hp_multiplier := maxf(0.0, float(level_def.get("boss_hp_multiplier", 1.0)))
	current_level_boss_enemy = enemy_spawner.spawn_boss(
		_get_scaled_enemy_config(BOSS_ENEMY_CONFIG, boss_hp_multiplier),
		boss_spawn
	)
	boss_enemy = current_level_boss_enemy
	if current_level_boss_enemy != null:
		boss_enemies.append(current_level_boss_enemy)
		if is_final_level:
			final_boss_enemy = current_level_boss_enemy
	_register_enemy(current_level_boss_enemy)
	_log_enemy_spawn(BOSS_ENEMY_CONFIG, "boss")
	if current_level_boss_enemy != null and not current_level_boss_enemy.damaged.is_connected(_on_boss_damaged):
		current_level_boss_enemy.damaged.connect(_on_boss_damaged)


func _spawn_level_pool_enemy(level_def: Dictionary) -> void:
	var enemy_config := _pick_enemy_config_from_pool(_get_spawn_pool(level_def))
	_spawn_enemy_config(enemy_config, "interval")


func _process_level_bursts(level_def: Dictionary, triggered_bursts: Dictionary) -> void:
	var bursts := _get_level_bursts(level_def)
	for burst_index in range(bursts.size()):
		if triggered_bursts.has(burst_index):
			continue
		var burst = bursts[burst_index]
		if not (burst is Dictionary):
			continue
		if current_level_elapsed >= float(burst.get("time", 0.0)):
			triggered_bursts[burst_index] = true
			_spawn_level_burst(burst, level_def)


func _spawn_level_burst(burst: Dictionary, level_def: Dictionary) -> void:
	var count := maxi(0, int(burst.get("count", 0)))
	var configured_enemy := burst.get("config", null) as EnemyConfig
	var burst_pool := _get_burst_spawn_pool(level_def)
	if configured_enemy == null and bool(burst.get("same_type", true)):
		configured_enemy = _pick_enemy_config_from_pool(burst_pool)
	for _index in range(count):
		var enemy_config := configured_enemy
		if enemy_config == null:
			enemy_config = _pick_enemy_config_from_pool(burst_pool)
		_spawn_enemy_config(enemy_config, "burst")


func _spawn_enemy_config(enemy_config: EnemyConfig, source: String) -> void:
	_register_enemy(enemy_spawner.spawn_normal_random_y(_get_scaled_enemy_config(enemy_config)))
	_log_enemy_spawn(enemy_config, source)


func _log_enemy_spawn(enemy_config: EnemyConfig, source: String) -> void:
	if not spawn_log_enabled:
		return
	print("[刷怪] 第%d关 %.1fs 来源=%s 类型=%s 场上=%d" % [
		current_wave_index + 1,
		current_level_elapsed,
		source,
		_get_enemy_config_log_name(enemy_config),
		_get_alive_enemy_count(),
	])


func _get_enemy_config_log_name(enemy_config: EnemyConfig) -> String:
	if enemy_config == null:
		return "unknown"
	if enemy_config.display_name != "":
		return enemy_config.display_name
	if enemy_config.enemy_id != &"":
		return String(enemy_config.enemy_id)
	return "enemy"


func _get_scaled_enemy_config(enemy_config: EnemyConfig, hp_multiplier: float = 1.0) -> EnemyConfig:
	if enemy_config == null:
		return null

	var scaled_config := enemy_config.duplicate(true) as EnemyConfig
	scaled_config.max_hp = float(_get_scaled_enemy_hp(enemy_config.max_hp * maxf(0.0, hp_multiplier)))
	return scaled_config


func _get_scaled_enemy_hp(base_hp: float) -> int:
	var scaled_hp := base_hp * _get_enemy_hp_multiplier()
	return maxi(1, floori(scaled_hp))


func _get_enemy_hp_multiplier() -> float:
	var passed_two_level_groups := maxi(0, floori(float(current_wave_index) / 2.0))
	return pow(ENEMY_HP_GROWTH_PER_TWO_LEVELS, passed_two_level_groups)


func _get_spawn_interval_for_current_enemy_count(level_def: Dictionary) -> float:
	var interval := maxf(0.05, float(level_def.get("spawn_interval", 1.0)))
	if _get_alive_enemy_count() < LOW_ENEMY_COUNT_THRESHOLD:
		interval *= LOW_ENEMY_COUNT_INTERVAL_MULTIPLIER
	return interval


func _get_spawn_pool(level_def: Dictionary) -> Array:
	var pool_value: Variant = level_def.get("spawn_pool", [])
	if pool_value is Array:
		return pool_value
	return []


func _get_burst_spawn_pool(level_def: Dictionary) -> Array:
	var pool := _get_spawn_pool(level_def)
	var burst_pool: Array = []
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var enemy_config := entry.get("config", null) as EnemyConfig
		if enemy_config == ELITE_ENEMY_CONFIG:
			continue
		burst_pool.append(entry)
	return burst_pool


func _get_level_bursts(level_def: Dictionary) -> Array:
	var bursts_value: Variant = level_def.get("bursts", [])
	if bursts_value is Array:
		return bursts_value
	return []


func _pick_enemy_config_from_pool(pool: Array) -> EnemyConfig:
	var total_weight := 0.0
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var enemy_config := entry.get("config", null) as EnemyConfig
		if enemy_config != null:
			total_weight += maxf(0.0, float(entry.get("weight", 1.0)))

	if total_weight <= 0.0:
		return _get_first_enemy_config_from_pool(pool)

	var roll := randf() * total_weight
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var enemy_config := entry.get("config", null) as EnemyConfig
		if enemy_config == null:
			continue
		roll -= maxf(0.0, float(entry.get("weight", 1.0)))
		if roll <= 0.0:
			return enemy_config

	return _get_first_enemy_config_from_pool(pool)


func _get_first_enemy_config_from_pool(pool: Array) -> EnemyConfig:
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var enemy_config := entry.get("config", null) as EnemyConfig
		if enemy_config != null:
			return enemy_config
	return null


func _register_enemy(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	active_enemies.append(enemy)
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)
	_update_hud()


func _on_enemy_died(enemy: EnemyBase) -> void:
	active_enemies.erase(enemy)
	boss_enemies.erase(enemy)
	if enemy == current_level_boss_enemy:
		current_level_boss_enemy = null
	if enemy == boss_enemy:
		boss_enemy = _get_latest_alive_boss()
	if enemy == final_boss_enemy and not encounter_finished:
		final_boss_enemy = null
		_finish_encounter(true)
		return
	_update_hud()


func _on_player_died() -> void:
	if encounter_finished:
		return
	_finish_encounter(false)


func _connect_result_buttons() -> void:
	if not result_restart_button.pressed.is_connected(_on_result_restart_pressed):
		result_restart_button.pressed.connect(_on_result_restart_pressed)
	if not result_main_menu_button.pressed.is_connected(_on_result_main_menu_pressed):
		result_main_menu_button.pressed.connect(_on_result_main_menu_pressed)


func _finish_encounter(victory: bool) -> void:
	if encounter_finished:
		return
	encounter_finished = true
	shop_button.disabled = true
	shop_layer.hide()
	upgrade_system.end_run()
	status_text = "Boss 信号核已摧毁" if victory else "信号中断"
	_stop_combat()
	_update_hud()
	if _has_external_result_handler(victory):
		if victory:
			level_won.emit("")
		else:
			level_lost.emit()
		return
	_show_result_page(victory)


func _stop_combat() -> void:
	is_spawning = false
	set_process(false)
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
	if wand_runtime != null:
		wand_runtime.set_process(false)
	for enemy in active_enemies:
		if enemy != null and is_instance_valid(enemy):
			enemy.set_process(false)
			enemy.set_physics_process(false)
	if projectile_root != null:
		for projectile in projectile_root.get_children():
			projectile.queue_free()


func _has_external_result_handler(victory: bool) -> bool:
	if victory:
		return not get_signal_connection_list(&"level_won").is_empty()
	return not get_signal_connection_list(&"level_lost").is_empty()


func _show_result_page(victory: bool) -> void:
	result_title_label.text = "作战结算：胜利" if victory else "作战结算：失败"
	result_summary_label.text = "Boss 信号核已摧毁，信号恢复稳定。" if victory else "玩家死亡，信号链路中断。"
	result_stats_label.text = _get_result_stats_text(victory)
	result_layer.show()


func _get_result_stats_text(victory: bool) -> String:
	var current_level := 1
	if experience_system != null:
		current_level = experience_system.current_level
	var wave_text := "Boss" if victory else _get_current_wave_text()
	return "进度：%s\n玩家：HP %d / %d    LV %d\n金币：%d" % [
		wave_text,
		player.current_hp,
		player.get_effective_max_hp(),
		current_level,
		player.current_gold,
	]


func _get_current_wave_text() -> String:
	if current_wave_index < 0:
		return "待命"
	if final_boss_enemy != null:
		return "最终 Boss"
	if current_level_boss_enemy != null:
		return "Boss 关"
	return "第 %d / %d 关" % [current_wave_index + 1, LEVEL_COUNT]


func _on_result_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_result_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_shop_button_pressed() -> void:
	if encounter_finished or shop_run_state == null:
		return
	_sync_shop_run_state_from_combat()
	shop_page.configure(shop_run_state)
	shop_layer.show()
	shop_button.disabled = true
	was_tree_paused_before_shop = get_tree().paused
	get_tree().paused = true


func _on_shop_closed() -> void:
	_apply_saved_shop_wand()
	if shop_run_state != null:
		player.current_gold = shop_run_state.gold
	shop_layer.hide()
	get_tree().paused = was_tree_paused_before_shop
	shop_button.disabled = false
	_update_hud()


func _on_shop_debug_experience_requested(amount: int) -> void:
	experience_system.add_debug_exp_without_upgrade_requests(float(amount))
	_sync_shop_run_state_from_combat()
	shop_page.refresh_current_state("调试：+%d经验" % amount)
	_update_hud()


func _on_debug_add_gold_pressed() -> void:
	player.add_gold(DEBUG_GOLD_AMOUNT)
	_sync_shop_run_state_from_combat()
	_update_hud()


func _on_debug_add_exp_pressed() -> void:
	experience_system.add_debug_exp_without_upgrade_requests(float(DEBUG_EXP_AMOUNT))
	player.current_xp = floori(experience_system.current_exp)
	player.xp_changed.emit(player.current_xp)
	_sync_shop_run_state_from_combat()
	_update_hud()


func _on_spawn_log_toggled(enabled: bool) -> void:
	spawn_log_enabled = enabled


func _on_cast_log_toggled(enabled: bool) -> void:
	cast_log_enabled = enabled
	if wand_runtime != null:
		wand_runtime.debug_enabled = enabled


func _on_god_power_toggled(enabled: bool) -> void:
	run_modifier_controller.set_god_power_damage_enabled(enabled)
	_update_hud()


func _sync_shop_run_state_from_combat() -> void:
	shop_run_state.gold = player.current_gold
	shop_run_state.current_wave = maxi(0, current_wave_index + 1)
	shop_run_state.player_level = experience_system.current_level
	shop_run_state.spell_slot_count = shop_run_state.get_unlocked_spell_slot_count()


func _apply_saved_shop_wand() -> void:
	var saved_wand := shop_page.get_saved_wand_data()
	if saved_wand == null:
		return
	wand_runtime.wand_data = saved_wand
	wand_runtime.reset_runtime()


func _build_spell_entries_from_wand(wand: WandData) -> Array[SpellEntry]:
	var entries: Array[SpellEntry] = []
	if wand == null:
		return entries
	for card in wand.deck:
		if card == null or card.id == &"":
			continue
		entries.append(SpellEntry.create(card.id, &"combat_start", 0))
	return entries


func _on_player_hp_changed(_current_hp: int, _max_hp: int) -> void:
	_update_hud()


func _on_player_xp_changed(_current_xp: int) -> void:
	_update_hud()


func _on_player_gold_changed(_current_gold: int) -> void:
	if shop_run_state != null:
		shop_run_state.gold = _current_gold
	_update_hud()


func _on_boss_damaged(_enemy: EnemyBase, _damage: float, _current_hp: float) -> void:
	_update_hud()


func _on_experience_changed(_current_exp: float, _threshold: float) -> void:
	player.current_xp = floori(_current_exp)
	_update_hud()


func _on_level_changed(_new_level: int) -> void:
	_update_hud()


func _on_modifier_changed(_target_key: StringName) -> void:
	player.sync_runtime_modifiers()
	_update_hud()


func _on_upgrade_applied(_option_id: StringName) -> void:
	_update_hud()


func _get_latest_alive_boss() -> EnemyBase:
	for index in range(boss_enemies.size() - 1, -1, -1):
		var enemy := boss_enemies[index]
		if _is_alive_enemy(enemy):
			return enemy
		boss_enemies.remove_at(index)
	return null


func _get_alive_enemy_count() -> int:
	_cleanup_active_enemies()
	var count := 0
	for enemy in active_enemies:
		if _is_alive_enemy(enemy):
			count += 1
	return count


func _cleanup_active_enemies() -> void:
	for index in range(active_enemies.size() - 1, -1, -1):
		var enemy := active_enemies[index]
		if not _is_alive_enemy(enemy):
			active_enemies.remove_at(index)


func _is_alive_enemy(enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not (enemy is EnemyBase):
		return false
	var enemy_base := enemy as EnemyBase
	return not enemy_base.is_queued_for_deletion() and not enemy_base.is_dead


func _get_current_level_duration() -> float:
	if current_wave_index < 0 or current_wave_index >= LEVEL_DEFS.size():
		return 0.0

	var level_def := LEVEL_DEFS[current_wave_index]
	return float(level_def.get("duration", DEFAULT_LEVEL_DURATION))


func _update_hud() -> void:
	if title_label == null:
		return

	title_label.text = status_text
	if current_wave_index >= 0 and final_boss_enemy != null:
		wave_label.text = "关卡：%d / %d  最终 Boss" % [current_wave_index + 1, LEVEL_COUNT]
	elif current_wave_index >= 0 and current_level_boss_enemy != null:
		wave_label.text = "关卡：%d / %d  Boss" % [current_wave_index + 1, LEVEL_COUNT]
	elif current_wave_index >= 0:
		wave_label.text = "关卡：%d / %d" % [current_wave_index + 1, LEVEL_COUNT]
	else:
		wave_label.text = "关卡：待命"

	var alive_enemy_count := _get_alive_enemy_count()
	enemy_label.text = "场上敌人：%d" % alive_enemy_count
	var current_level := 1
	var current_exp := float(player.current_xp)
	var current_threshold := 0.0
	if experience_system != null:
		current_level = experience_system.current_level
		current_exp = experience_system.current_exp
		current_threshold = experience_system.get_current_threshold()
	player_label.text = "玩家 HP：%d / %d    LV：%d    金币：%d" % [
		player.current_hp,
		player.get_effective_max_hp(),
		current_level,
		player.current_gold,
	]
	if experience_bar != null:
		experience_bar.max_value = maxf(1.0, current_threshold)
		experience_bar.value = clampf(current_exp, 0.0, experience_bar.max_value)
	_update_level_timer_bar()
	_update_boss_health_bar()
	_update_debug_panel(alive_enemy_count)


func _update_level_timer_bar() -> void:
	if level_timer_bar == null:
		return
	var duration := _get_current_level_duration()
	var should_show := current_wave_index >= 0 and duration > 0.0 and not encounter_finished
	level_timer_bar.visible = should_show
	if not should_show:
		level_timer_bar.value = 0.0
		return
	level_timer_bar.max_value = maxf(0.01, duration)
	level_timer_bar.value = clampf(duration - current_level_elapsed, 0.0, level_timer_bar.max_value)


func _update_boss_health_bar() -> void:
	if boss_health_bar == null:
		return
	if boss_enemy == null or not _is_alive_enemy(boss_enemy):
		boss_enemy = _get_latest_alive_boss()
	var should_show := boss_enemy != null and not encounter_finished
	boss_health_bar.visible = should_show
	if not should_show:
		boss_health_bar.value = 0.0
		return
	var max_hp := 1.0
	if boss_enemy.config != null:
		max_hp = maxf(1.0, boss_enemy.config.max_hp)
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = clampf(boss_enemy.current_hp, 0.0, max_hp)


func _update_debug_panel(alive_enemy_count: int) -> void:
	if debug_enemy_count_label == null:
		return

	debug_enemy_count_label.text = "场上敌人：%d" % alive_enemy_count
	debug_enemy_hp_scale_label.text = "敌人血量系数：x%.2f" % _get_enemy_hp_multiplier()
	var damage_multiplier := 1.0
	if run_modifier_controller != null:
		damage_multiplier = run_modifier_controller.get_damage_multiplier()
	debug_damage_scale_label.text = "伤害系数：x%.2f" % damage_multiplier
	if god_power_check_button != null and run_modifier_controller != null:
		god_power_check_button.set_pressed_no_signal(run_modifier_controller.god_power_damage_enabled)
