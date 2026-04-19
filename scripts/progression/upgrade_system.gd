class_name UpgradeSystem
extends Node

signal upgrade_choices_generated(options: Array)
signal upgrade_selected(option_id: StringName)
signal upgrade_applied(option_id: StringName)

enum State {
	IDLE,
	WAITING_SELECTION,
	APPLYING_SELECTION,
}

@export var upgrade_options: Array[UpgradeOptionConfig] = []
@export var fallback_option: UpgradeOptionConfig

var experience_system: ExperienceSystem
var run_modifier_controller: RunModifierController
var upgrade_panel: UpgradeSelectionPanel
var player: Player

var state: State = State.IDLE
var pick_counts: Dictionary = {}
var acquired_tags: Dictionary = {}
var selected_exclusive_groups: Dictionary = {}

var _pending_levels: Array[int] = []
var _current_options: Array[UpgradeOptionConfig] = []
var _was_tree_paused: bool = false
var _pause_snapshot_active: bool = false
var _run_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func bind_dependencies(
	experience_ref: ExperienceSystem,
	modifier_ref: RunModifierController,
	panel_ref: UpgradeSelectionPanel,
	player_ref: Player
) -> void:
	experience_system = experience_ref
	run_modifier_controller = modifier_ref
	upgrade_panel = panel_ref
	player = player_ref

	if experience_system != null and not experience_system.level_up_requested.is_connected(request_upgrade):
		experience_system.level_up_requested.connect(request_upgrade)
	if upgrade_panel != null and not upgrade_panel.option_selected.is_connected(_on_option_selected):
		upgrade_panel.option_selected.connect(_on_option_selected)


func reset_run() -> void:
	if state != State.IDLE:
		_restore_tree_pause()
	state = State.IDLE
	pick_counts.clear()
	acquired_tags.clear()
	selected_exclusive_groups.clear()
	_pending_levels.clear()
	_current_options.clear()
	if upgrade_panel != null:
		upgrade_panel.hide_panel()


func start_run() -> void:
	_run_active = true


func end_run() -> void:
	_run_active = false
	reset_run()


func request_upgrade(new_level: int) -> void:
	if not _run_active or _is_player_dead():
		return
	_pending_levels.append(new_level)
	if state == State.IDLE:
		_open_next_upgrade()


func is_waiting_selection() -> bool:
	return state == State.WAITING_SELECTION


func generate_upgrade_choices() -> Array[UpgradeOptionConfig]:
	var candidates := _get_eligible_options()
	var result: Array[UpgradeOptionConfig] = []

	while result.size() < 3 and not candidates.is_empty():
		var picked := _weighted_pick(candidates)
		if picked == null:
			break
		result.append(picked)
		candidates.erase(picked)

	if result.size() < 3 and fallback_option != null and not result.has(fallback_option):
		result.append(fallback_option)

	return result


func _open_next_upgrade() -> void:
	if not _run_active or _is_player_dead():
		_pending_levels.clear()
		_restore_tree_pause()
		state = State.IDLE
		return
	if _pending_levels.is_empty():
		_restore_tree_pause()
		state = State.IDLE
		return

	var level: int = int(_pending_levels.pop_front())
	_current_options = generate_upgrade_choices()
	if _current_options.is_empty():
		push_warning("No eligible upgrades available.")
		if experience_system != null:
			experience_system.consume_pending_level_up()
		_open_next_upgrade()
		return

	state = State.WAITING_SELECTION
	if not _pause_snapshot_active:
		_was_tree_paused = get_tree().paused
		_pause_snapshot_active = true
	get_tree().paused = true
	if upgrade_panel != null:
		upgrade_panel.show_choices(level, _current_options)
	upgrade_choices_generated.emit(_current_options)


func _on_option_selected(option_id: StringName) -> void:
	if state != State.WAITING_SELECTION:
		return

	var option := _find_current_option(option_id)
	if option == null:
		return

	state = State.APPLYING_SELECTION
	upgrade_selected.emit(option_id)
	_apply_upgrade(option)
	if experience_system != null:
		experience_system.consume_pending_level_up()
	if upgrade_panel != null:
		upgrade_panel.hide_panel()
	_current_options.clear()
	_open_next_upgrade()


func _apply_upgrade(option: UpgradeOptionConfig) -> void:
	pick_counts[option.id] = int(pick_counts.get(option.id, 0)) + 1

	match option.modifier_type:
		&"stat_modifier":
			if run_modifier_controller != null:
				run_modifier_controller.apply_stat_modifier(option)
			if player != null:
				player.sync_runtime_modifiers()
		&"instant_effect":
			_apply_instant_effect(option)
		_:
			push_warning("Unknown modifier type: %s" % option.modifier_type)

	if option.exclusive_group != &"":
		selected_exclusive_groups[option.exclusive_group] = option.id
	for tag in option.granted_tags:
		acquired_tags[tag] = true
	upgrade_applied.emit(option.id)


func _apply_instant_effect(option: UpgradeOptionConfig) -> void:
	if player == null:
		return
	match option.target_key:
		&"restore_hit":
			player.restore_hit(maxi(1, roundi(option.value)))
		_:
			push_warning("Unknown instant upgrade target: %s" % option.target_key)


func _get_eligible_options() -> Array[UpgradeOptionConfig]:
	var result: Array[UpgradeOptionConfig] = []
	for option in upgrade_options:
		if _is_option_eligible(option):
			result.append(option)
	return result


func _is_option_eligible(option: UpgradeOptionConfig) -> bool:
	if option == null or option.id == &"":
		return false
	if int(pick_counts.get(option.id, 0)) >= option.max_pick_count:
		return false
	if option.exclusive_group != &"" and selected_exclusive_groups.has(option.exclusive_group):
		return false
	for tag in option.required_tags:
		if not acquired_tags.has(tag):
			return false
	for tag in option.blocked_tags:
		if acquired_tags.has(tag):
			return false
	if option.modifier_type == &"instant_effect" and option.target_key == &"restore_hit":
		return player != null and player.current_hp < player.get_effective_max_hp()
	return true


func _weighted_pick(candidates: Array[UpgradeOptionConfig]) -> UpgradeOptionConfig:
	var total_weight := 0.0
	for option in candidates:
		total_weight += maxf(0.0, option.weight)
	if total_weight <= 0.0:
		return candidates[0] if not candidates.is_empty() else null

	var roll := randf() * total_weight
	for option in candidates:
		roll -= maxf(0.0, option.weight)
		if roll <= 0.0:
			return option
	return candidates[candidates.size() - 1]


func _find_current_option(option_id: StringName) -> UpgradeOptionConfig:
	for option in _current_options:
		if option != null and option.id == option_id:
			return option
	return null


func _restore_tree_pause() -> void:
	if not _pause_snapshot_active:
		return
	get_tree().paused = _was_tree_paused
	_pause_snapshot_active = false


func _is_player_dead() -> bool:
	return player != null and player.is_dead
