extends Control

signal level_lost
signal level_won(level_path: String)

const NORMAL_ENEMY_CONFIG: EnemyConfig = preload("res://resources/enemies/enemy_normal_signal.tres")
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
const WAVE_DEFS: Array[Dictionary] = [
	{"count": 3, "interval": 0.8},
	{"count": 5, "interval": 0.65},
	{"count": 7, "interval": 0.5},
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
@onready var projectile_factory: ProjectileFactory = %ProjectileFactory
@onready var wand_runtime: WandRuntime = %WandRuntime
@onready var enemy_spawner: EnemySpawner = %EnemySpawner
@onready var title_label: Label = %TitleLabel
@onready var wave_label: Label = %WaveLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var player_label: Label = %PlayerLabel
@onready var boss_label: Label = %BossLabel
@onready var hint_label: Label = %HintLabel

var active_enemies: Array[EnemyBase] = []
var boss_enemy: EnemyBase
var current_wave_index: int = -1
var status_text: String = "准备接收信号..."
var encounter_finished: bool = false
var is_spawning: bool = false


func _ready() -> void:
	randomize()
	_layout_combat_points()
	_configure_runtime()
	_connect_player_signals()
	player.reset_player()
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
	run_modifier_controller.reset_modifiers()
	experience_system.run_modifier_controller = run_modifier_controller
	experience_system.reset_progression()
	upgrade_system.upgrade_options = UPGRADE_POOL.duplicate()
	upgrade_system.fallback_option = FALLBACK_DAMAGE_UP_5
	upgrade_system.reset_run()
	upgrade_system.bind_dependencies(experience_system, run_modifier_controller, upgrade_panel, player)
	wand_runtime.wand_data = _build_default_wand()
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


func _start_encounter() -> void:
	status_text = "校准自动施法..."
	await get_tree().create_timer(start_delay).timeout

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
		await get_tree().create_timer(wave_pause).timeout

	if encounter_finished:
		return
	status_text = "Boss 信号核出现"
	_spawn_boss()


func _spawn_wave(wave: Dictionary) -> void:
	is_spawning = true
	var enemy_count := int(wave.get("count", 0))
	var interval := float(wave.get("interval", 0.6))

	for index in range(enemy_count):
		if encounter_finished:
			is_spawning = false
			return
		var enemy := enemy_spawner.spawn_normal_random_y(NORMAL_ENEMY_CONFIG)
		_register_enemy(enemy)
		if index < enemy_count - 1:
			await get_tree().create_timer(interval).timeout

	is_spawning = false


func _spawn_boss() -> void:
	boss_enemy = enemy_spawner.spawn_boss(BOSS_ENEMY_CONFIG, boss_spawn)
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
		await get_tree().create_timer(0.2).timeout


func _on_enemy_died(enemy: EnemyBase) -> void:
	active_enemies.erase(enemy)
	if enemy == boss_enemy and not encounter_finished:
		encounter_finished = true
		status_text = "Boss 信号核已摧毁"
		boss_enemy = null
		_update_hud()
		level_won.emit("")
		return
	_update_hud()


func _on_player_died() -> void:
	if encounter_finished:
		return
	encounter_finished = true
	upgrade_system.reset_run()
	status_text = "信号中断"
	_update_hud()
	level_lost.emit()


func _on_player_hp_changed(_current_hp: int, _max_hp: int) -> void:
	_update_hud()


func _on_player_xp_changed(_current_xp: int) -> void:
	_update_hud()


func _on_player_gold_changed(_current_gold: int) -> void:
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


func _build_default_wand() -> WandData:
	var wand := WandData.new()
	wand.draws_per_cast = 1
	wand.cast_delay = 0.05
	wand.recharge_time = 0.08
	wand.deck = [
		_action(&"signal_bolt", "信号弹", 12.0, 720.0, 2.4, 6.0, Color(0.45, 0.82, 1.0, 1.0)),
	]
	return wand


func _action(
	id: StringName,
	display_name: String,
	damage: float,
	speed: float,
	lifetime: float,
	radius: float,
	projectile_color: Color
) -> ActionCardData:
	var card := ActionCardData.new()
	card.id = id
	card.display_name = display_name
	card.damage = damage
	card.speed = speed
	card.lifetime = lifetime
	card.radius = radius
	card.projectile_count = 1
	card.spread_degrees = 0.0
	card.knockback_force = 115.0
	card.projectile_color = projectile_color
	return card
