class_name WandRuntime
extends Node

@export var wand_data: WandData
@export var projectile_factory_path: NodePath
@export var debug_enabled: bool = true

enum ReloadMode {
	NONE,
	CAST_DELAY,
	RECHARGE,
}

const MIN_RELOAD_SECONDS := 1.0 / 60.0
const MIN_RECHARGE_SECONDS := 0.1

var projectile_factory: ProjectileFactory
var run_modifier_controller: RunModifierController
var last_debug_lines: Array[String] = []

var _deck_index: int = 0
var _cards_drawn_this_cycle: int = 0
var _reload_remaining: float = 0.0
var _reload_total: float = 0.0
var _reload_mode: ReloadMode = ReloadMode.NONE
var _cards_drawn_for_cast: Array[SpellCardData] = []
var _is_tracking_cast_cards: bool = false


func _process(delta: float) -> void:
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if _reload_remaining <= 0.0:
			_reload_total = 0.0
			_reload_mode = ReloadMode.NONE


func can_cast() -> bool:
	return _reload_remaining <= 0.0 and wand_data != null and not wand_data.deck.is_empty()


func cast_once(caster: Node, origin: Vector2, direction: Vector2) -> Array[SpawnRequest]:
	var empty_results: Array[SpawnRequest] = []
	if not can_cast():
		last_debug_lines = ["[法杖运行时] 无法施法：装填中、缺少法杖数据或牌组为空"]
		return empty_results

	var resolver := SpellResolver.new()
	resolver.run_modifier_controller = run_modifier_controller
	resolver.debug_enabled = debug_enabled
	_begin_cast_card_tracking()
	var group := resolver.resolve_next_group(self)
	if group.is_empty():
		last_debug_lines = resolver.debug_lines.duplicate()
		_end_cast_card_tracking()
		_start_recharge_delay()
		return empty_results

	var requests := resolver.build_requests_from_group(group, self, origin, direction)
	last_debug_lines = resolver.debug_lines.duplicate()

	var factory := get_projectile_factory()
	if factory != null:
		factory.spawn_requests(requests)

	var cast_cards := _end_cast_card_tracking()
	_log_group_delay_totals(cast_cards)
	if _is_sequence_finished():
		_start_recharge_delay()
	else:
		_start_cast_delay(cast_cards)
	return requests


func draw_next_card() -> SpellCardData:
	if wand_data == null or wand_data.deck.is_empty():
		return null
	if _cards_drawn_this_cycle >= wand_data.deck.size():
		return null

	_normalize_deck_index()
	var card := wand_data.deck[_deck_index]
	_deck_index += 1
	_cards_drawn_this_cycle += 1
	if _deck_index >= wand_data.deck.size():
		_deck_index = 0
	if _is_tracking_cast_cards and card != null:
		_cards_drawn_for_cast.append(card)
	return card


func get_deck_index() -> int:
	_normalize_deck_index()
	return _deck_index


func get_deck_size() -> int:
	if wand_data == null:
		return 0
	return wand_data.deck.size()


func get_remaining_cards_in_cycle() -> int:
	if wand_data == null:
		return 0
	return maxi(0, wand_data.deck.size() - _cards_drawn_this_cycle)


func reset_runtime() -> void:
	_deck_index = 0
	_cards_drawn_this_cycle = 0
	_reload_remaining = 0.0
	_reload_total = 0.0
	_reload_mode = ReloadMode.NONE
	_cards_drawn_for_cast.clear()
	_is_tracking_cast_cards = false
	last_debug_lines.clear()


func get_projectile_factory() -> ProjectileFactory:
	if projectile_factory != null:
		return projectile_factory
	if not projectile_factory_path.is_empty():
		projectile_factory = get_node_or_null(projectile_factory_path) as ProjectileFactory
	return projectile_factory


func get_cooldown_remaining() -> float:
	return _reload_remaining


func is_reloading() -> bool:
	return _reload_remaining > 0.0


func get_reload_progress() -> float:
	if _reload_total <= 0.0:
		return 0.0
	return clampf(1.0 - (_reload_remaining / _reload_total), 0.0, 1.0)


func get_reload_mode_text() -> String:
	match _reload_mode:
		ReloadMode.CAST_DELAY:
			return "施法"
		ReloadMode.RECHARGE:
			return "充能"
		_:
			return ""


func _normalize_deck_index() -> void:
	if wand_data == null or wand_data.deck.is_empty():
		_deck_index = 0
		return
	_deck_index = posmod(_deck_index, wand_data.deck.size())


func _begin_cast_card_tracking() -> void:
	_cards_drawn_for_cast.clear()
	_is_tracking_cast_cards = true


func _end_cast_card_tracking() -> Array[SpellCardData]:
	_is_tracking_cast_cards = false
	var cast_cards: Array[SpellCardData] = []
	for card in _cards_drawn_for_cast:
		cast_cards.append(card)
	_cards_drawn_for_cast.clear()
	return cast_cards


func _is_sequence_finished() -> bool:
	return wand_data == null or wand_data.deck.is_empty() or _cards_drawn_this_cycle >= wand_data.deck.size()


func _start_cast_delay(cards: Array[SpellCardData]) -> void:
	var base_delay := _get_wand_cast_delay()
	var spell_delay := _get_group_cast_delay(cards)
	var delay := maxf(0.0, base_delay + spell_delay)
	var adjusted_delay := _apply_cast_rate(delay)
	_log_runtime_delay("[法杖运行时] 进入组间施法延迟：法杖基础 %.2fs + 本组法术总计 %.2fs = %.2fs，实际 %.2fs" % [
		base_delay,
		spell_delay,
		delay,
		adjusted_delay,
	])
	_start_reload(ReloadMode.CAST_DELAY, adjusted_delay)


func _start_recharge_delay() -> void:
	var base_delay := _get_wand_recharge_delay()
	var spell_delay := _get_total_recharge_delay()
	var raw_delay := maxf(0.0, base_delay + spell_delay)
	var reduction := _get_recharge_time_reduction()
	var reduced_delay := maxf(0.0, raw_delay - reduction)
	_deck_index = 0
	_cards_drawn_this_cycle = 0
	var adjusted_delay := _apply_recharge_delay_modifiers(reduced_delay)
	_log_card_delay_modifiers(_get_all_spell_cards(), "充能队列")
	_log_runtime_delay("[法杖运行时] 总计充能延迟：法杖基础 %.2fs + 全部法术总计 %.2fs = %.2fs，升级减免 %.2fs，实际 %.2fs" % [
		base_delay,
		spell_delay,
		raw_delay,
		reduction,
		adjusted_delay,
	])
	_start_reload(ReloadMode.RECHARGE, adjusted_delay)


func _get_wand_cast_delay() -> float:
	if wand_data == null:
		return 0.0
	return wand_data.cast_delay


func _get_wand_recharge_delay() -> float:
	if wand_data == null:
		return 0.0
	return wand_data.recharge_time


func _get_group_cast_delay(cards: Array[SpellCardData]) -> float:
	var delay := 0.0
	for card in cards:
		if card != null:
			delay += card.cast_delay
	return delay


func _get_group_recharge_delay(cards: Array[SpellCardData]) -> float:
	var delay := 0.0
	for card in cards:
		if card != null:
			delay += card.recharge_time
	return delay


func _get_total_recharge_delay() -> float:
	var delay := 0.0
	if wand_data != null:
		for card in wand_data.deck:
			if card != null:
				delay += card.recharge_time
	return delay


func _log_group_delay_totals(cards: Array[SpellCardData]) -> void:
	_log_card_delay_modifiers(cards, "本组")
	_log_runtime_delay("[法杖运行时] 本组延迟累计：施法修正 %.2fs，充能贡献 %.2fs" % [
		_get_group_cast_delay(cards),
		_get_group_recharge_delay(cards),
	])


func _get_all_spell_cards() -> Array[SpellCardData]:
	var cards: Array[SpellCardData] = []
	if wand_data == null:
		return cards
	for card in wand_data.deck:
		if card != null:
			cards.append(card)
	return cards


func _log_card_delay_modifiers(cards: Array[SpellCardData], scope: String) -> void:
	if cards.is_empty():
		_log_runtime_delay("[法杖运行时] %s法术延迟修正：无" % scope)
		return

	for card in cards:
		if card == null:
			continue
		_log_runtime_delay("[法杖运行时] %s法术延迟修正：%s，施法 %.2fs，充能 %.2fs" % [
			scope,
			card.get_display_name(),
			card.cast_delay,
			card.recharge_time,
		])


func _start_reload(mode: ReloadMode, raw_duration: float) -> void:
	_reload_total = maxf(MIN_RELOAD_SECONDS, raw_duration)
	_reload_remaining = _reload_total
	_reload_mode = mode


func _apply_cast_rate(duration: float) -> float:
	var multiplier := 1.0
	if run_modifier_controller != null:
		multiplier = run_modifier_controller.get_cast_rate_multiplier()
	if multiplier <= 0.0:
		return maxf(0.0, duration)
	return maxf(0.0, duration / multiplier)


func _apply_recharge_delay_modifiers(duration: float) -> float:
	return maxf(MIN_RECHARGE_SECONDS, _apply_cast_rate(duration))


func _get_recharge_time_reduction() -> float:
	if run_modifier_controller == null:
		return 0.0
	return run_modifier_controller.get_recharge_time_reduction()


func _log_runtime_delay(message: String) -> void:
	last_debug_lines.append(message)
	if debug_enabled:
		print(message)
