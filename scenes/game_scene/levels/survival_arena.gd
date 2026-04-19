extends Control

signal level_lost
signal level_won(level_path: String)

const FAST_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_fast_signal.tres")
const HEAVY_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_heavy_signal.tres")
const ELITE_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_elite_signal.tres")
const BOSS_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_boss_signal.tres")
const DAMAGE_UP_10: UpgradeOptionConfig = preload("res://resources/upgrades/damage_up_10.tres")
const CAST_RATE_UP_10: UpgradeOptionConfig = preload("res://resources/upgrades/cast_rate_up_10.tres")
const PROJECTILE_SPEED_UP_15: UpgradeOptionConfig = preload("res://resources/upgrades/projectile_speed_up_15.tres")
const KNOCKBACK_UP_20: UpgradeOptionConfig = preload("res://resources/upgrades/knockback_up_20.tres")
const AOE_UP_15: UpgradeOptionConfig = preload("res://resources/upgrades/aoe_up_15.tres")
const GOLD_DROP_CHANCE_UP_10: UpgradeOptionConfig = preload("res://resources/upgrades/gold_drop_chance_up_10.tres")
const EXP_GAIN_UP_10: UpgradeOptionConfig = preload("res://resources/upgrades/exp_gain_up_10.tres")
const MAX_HP_UP_1: UpgradeOptionConfig = preload("res://resources/upgrades/max_hp_up_1.tres")
const HEAL_1: UpgradeOptionConfig = preload("res://resources/upgrades/heal_1.tres")
const FALLBACK_DAMAGE_UP_5: UpgradeOptionConfig = preload("res://resources/upgrades/fallback_damage_up_5.tres")
const SPELL_CARD_DATABASE: SpellCardDatabase = preload("res://resources/spells/spell_card_database.tres")
const COMBAT_DEFAULT_WAND: WandData = preload("res://resources/spells/wands/combat_default_wand.tres")
const MAIN_MENU_SCENE_PATH := "res://scenes/menus/main_menu/main_menu.tscn"
const WAVE_DEFS: Array[Dictionary] = [
	{"count": 20, "interval": 0.8, "elite_count": 0},
	{"count": 20, "interval": 0.65, "elite_count": 1},
	{"count": 20, "interval": 0.5, "elite_count": 2},
]
const UPGRADE_POOL: Array[UpgradeOptionConfig] = [
	DAMAGE_UP_10,
	CAST_RATE_UP_10,
	PROJECTILE_SPEED_UP_15,
	KNOCKBACK_UP_20,
	AOE_UP_15,
	GOLD_DROP_CHANCE_UP_10,
	EXP_GAIN_UP_10,
	MAX_HP_UP_1,
	HEAL_1,
]

@export var start_delay: float = 0.8
@export var wave_pause: float = 1.2
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
@onready var boss_label: Label = %BossLabel
@onready var hint_label: Label = %HintLabel
@onready var shop_button: Button = %ShopButton
@onready var shop_layer: CanvasLayer = %ShopLayer
@onready var shop_page: ShopPage = %ShopPage
@onready var result_layer: CanvasLayer = %ResultLayer
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_summary_label: Label = %ResultSummaryLabel
@onready var result_stats_label: Label = %ResultStatsLabel
@onready var result_restart_button: Button = %ResultRestartButton
@onready var result_main_menu_button: Button = %ResultMainMenuButton

var active_enemies: Array[EnemyBase] = []
var boss_enemy: EnemyBase
var current_wave_index: int = -1
var status_text: String = "准备接收信号..."
var encounter_finished: bool = false
var is_spawning: bool = false
var shop_run_state: RunState
var was_tree_paused_before_shop: bool = false


func _ready() -> void:
	randomize()
	_layout_combat_points()
	_configure_runtime()
	_connect_player_signals()
	_connect_result_buttons()
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
	enemy_spawner.normal_configs = [FAST_ENEMY_CONFIG, HEAVY_ENEMY_CONFIG]
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
	shop_run_state.inventory_capacity = 6
	shop_run_state.spell_slot_count = 6
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


func _start_encounter() -> void:
	status_text = "校准自动施法..."
	await get_tree().create_timer(start_delay, false).timeout

	for wave_index in range(WAVE_DEFS.size()):
		if encounter_finished:
			return
		current_wave_index = wave_index
		status_text = "第 %d 波接近中" % (current_wave_index + 1)
		await _spawn_wave(WAVE_DEFS[wave_index])
		await _wait_until_wave_clear()
		if encounter_finished:
			return
		status_text = "第 %d 波清除" % (current_wave_index + 1)
		await get_tree().create_timer(wave_pause, false).timeout

	if encounter_finished:
		return
	status_text = "Boss 信号核出现"
	_spawn_boss()


func _spawn_wave(wave: Dictionary) -> void:
	is_spawning = true
	var enemy_count := int(wave.get("count", 0))
	var interval := float(wave.get("interval", 0.6))
	var elite_count := clampi(int(wave.get("elite_count", 0)), 0, enemy_count)
	var elite_start_index := enemy_count - elite_count

	for index in range(enemy_count):
		if encounter_finished:
			is_spawning = false
			return
		var enemy: EnemyBase
		if index >= elite_start_index:
			enemy = enemy_spawner.spawn_elite()
		else:
			enemy = enemy_spawner.spawn_normal_random_y()
		_register_enemy(enemy)
		if index < enemy_count - 1:
			await get_tree().create_timer(interval, false).timeout

	is_spawning = false


func _spawn_boss() -> void:
	boss_enemy = enemy_spawner.spawn_boss(null, boss_spawn)
	_register_enemy(boss_enemy)
	if boss_enemy != null and not boss_enemy.damaged.is_connected(_on_boss_damaged):
		boss_enemy.damaged.connect(_on_boss_damaged)


func _register_enemy(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	active_enemies.append(enemy)
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)
	_update_hud()


func _wait_until_wave_clear() -> void:
	while not encounter_finished and (_get_alive_enemy_count() > 0 or is_spawning):
		await get_tree().create_timer(0.2, false).timeout


func _on_enemy_died(enemy: EnemyBase) -> void:
	active_enemies.erase(enemy)
	if enemy == boss_enemy and not encounter_finished:
		boss_enemy = null
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
	var current_exp := 0.0
	var current_threshold := 0.0
	if experience_system != null:
		current_level = experience_system.current_level
		current_exp = experience_system.current_exp
		current_threshold = experience_system.get_current_threshold()
	var wave_text := "Boss" if victory else _get_current_wave_text()
	return "进度：%s\n玩家：HP %d / %d    LV %d    XP %d / %d\n金币：%d" % [
		wave_text,
		player.current_hp,
		player.get_effective_max_hp(),
		current_level,
		floori(current_exp),
		ceili(current_threshold),
		player.current_gold,
	]


func _get_current_wave_text() -> String:
	if current_wave_index < 0:
		return "待命"
	if boss_enemy != null:
		return "Boss"
	return "第 %d / %d 波" % [current_wave_index + 1, WAVE_DEFS.size()]


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


func _sync_shop_run_state_from_combat() -> void:
	shop_run_state.gold = player.current_gold
	shop_run_state.current_wave = maxi(0, current_wave_index + 1)


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


func _is_alive_enemy(enemy: EnemyBase) -> bool:
	return enemy != null and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_dead


func _update_hud() -> void:
	if title_label == null:
		return

	title_label.text = status_text
	if current_wave_index >= 0 and boss_enemy == null:
		wave_label.text = "波次：%d / %d" % [current_wave_index + 1, WAVE_DEFS.size()]
	elif boss_enemy != null:
		wave_label.text = "波次：Boss"
	else:
		wave_label.text = "波次：待命"

	enemy_label.text = "场上敌人：%d" % _get_alive_enemy_count()
	var current_level := 1
	var current_exp := float(player.current_xp)
	var current_threshold := 0.0
	if experience_system != null:
		current_level = experience_system.current_level
		current_exp = experience_system.current_exp
		current_threshold = experience_system.get_current_threshold()
	player_label.text = "玩家 HP：%d / %d    LV：%d    XP：%d / %d    金币：%d" % [
		player.current_hp,
		player.get_effective_max_hp(),
		current_level,
		floori(current_exp),
		ceili(current_threshold),
		player.current_gold,
	]
	boss_label.text = _get_boss_text()
	hint_label.text = "玩家固定在左侧，自动锁定最近敌人。"


func _get_boss_text() -> String:
	if boss_enemy == null or not _is_alive_enemy(boss_enemy):
		return "Boss：未出现"
	var max_hp := 1.0
	if boss_enemy.config != null:
		max_hp = boss_enemy.config.max_hp
	return "Boss HP：%d / %d" % [ceili(boss_enemy.current_hp), ceili(max_hp)]
