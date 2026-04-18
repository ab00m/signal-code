class_name SpellResolver
extends RefCounted

const MAX_TRIGGER_DEPTH := 4

var debug_lines: Array[String] = []


func resolve_main_cast(wand_runtime: WandRuntime, origin: Vector2, direction: Vector2) -> Array[SpawnRequest]:
	debug_lines.clear()
	_log("[法术解析] 开始施法，牌组索引=%d" % wand_runtime.get_deck_index())

	var results: Array[SpawnRequest] = []
	var wand_data := wand_runtime.wand_data
	if wand_data == null:
		_log("[法术解析] 中止：缺少 WandData")
		return results
	if wand_data.deck.is_empty():
		_log("[法术解析] 中止：牌组为空")
		return results

	var remaining_main_actions: int = max(1, wand_data.draws_per_cast)
	while remaining_main_actions > 0:
		var group := resolve_next_group(wand_runtime)
		if group.is_empty():
			_log("[法术解析] 施法失败：没有找到动作卡")
			break

		var group_requests := build_requests_from_group(group, wand_runtime, origin, direction)
		results.append_array(group_requests)
		remaining_main_actions -= max(1, group.get_consumed_action_count())

	_log("[法术解析] 已生成发射请求：%d 个" % results.size())
	return results


func resolve_next_group(wand_runtime: WandRuntime) -> SpellGroup:
	var group := SpellGroup.new()
	var max_draws := wand_runtime.get_deck_size()
	var drawn := 0
	var target_action_count := 1
	var multicast_seen := false

	while drawn < max_draws and group.actions.size() < target_action_count:
		var card := wand_runtime.draw_next_card()
		drawn += 1
		if card == null:
			continue

		_log("[法术解析] 抽到卡牌：%s" % card.get_display_name())

		if card is ModifierCardData:
			var modifier := card as ModifierCardData
			if modifier.modifier_type == ModifierCardData.ModifierType.MULTICAST:
				if multicast_seen:
					_log("[法术解析] 警告：额外的多重施放已忽略")
					continue
				multicast_seen = true
				target_action_count = max(1, modifier.value_int)
				group.target_action_count = target_action_count
				group.modifiers.append(modifier)
				_log("[法术解析] 当前施法组目标动作数设为 %d" % target_action_count)
			else:
				group.modifiers.append(modifier)
		elif card is ActionCardData:
			group.actions.append(card as ActionCardData)
		else:
			_log("[法术解析] 警告：不支持的卡牌已忽略")

	if group.actions.is_empty():
		_log("[法术解析] 施法组失败：抽取 %d 张后仍无动作卡" % drawn)
	elif group.actions.size() < target_action_count:
		_log("[法术解析] 警告：扫完整个牌组后只解析到部分施法组")

	_log("[法术解析] 施法组解析完成：%s" % group.describe())
	return group


func build_requests_from_group(
	group: SpellGroup,
	wand_runtime: WandRuntime,
	origin: Vector2,
	direction: Vector2,
	trigger_depth: int = 0
) -> Array[SpawnRequest]:
	var results: Array[SpawnRequest] = []
	var bundle := ResolvedModifierBundle.from_modifiers(group.modifiers)
	var base_direction := direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	for action in group.actions:
		var count: int = max(1, action.projectile_count + bundle.projectile_count_add)
		var spread := action.spread_degrees + bundle.add_spread_degrees
		for index in range(count):
			var offset := 0.0
			if count > 1:
				offset = lerpf(-spread * 0.5, spread * 0.5, float(index) / float(count - 1))
			var request := _build_request(action, bundle, origin, base_direction.rotated(deg_to_rad(offset)))
			if action is TriggerActionCardData:
				_attach_trigger_payload(request, action as TriggerActionCardData, wand_runtime, origin, request.direction, trigger_depth)
			results.append(request)

	return results


func resolve_payload_requests(
	wand_runtime: WandRuntime,
	payload_action_count: int,
	origin: Vector2,
	direction: Vector2,
	trigger_depth: int
) -> Array[SpawnRequest]:
	var results: Array[SpawnRequest] = []
	if payload_action_count <= 0:
		return results
	if trigger_depth >= MAX_TRIGGER_DEPTH:
		_log("[法术解析] 警告：触发载荷递归深度已达上限")
		return results

	for _payload_index in range(payload_action_count):
		var group := resolve_next_group(wand_runtime)
		if group.is_empty():
			_log("[法术解析] 触发载荷结束：没有找到动作卡")
			break

		var group_requests := build_requests_from_group(group, wand_runtime, origin, direction, trigger_depth + 1)
		results.append_array(group_requests)

	return results


func _build_request(
	action: ActionCardData,
	bundle: ResolvedModifierBundle,
	origin: Vector2,
	direction: Vector2
) -> SpawnRequest:
	var request := SpawnRequest.new()
	request.source_card = action
	request.display_name = action.get_display_name()
	request.origin = origin
	request.direction = direction.normalized()
	request.damage = action.damage * bundle.damage_mul
	request.speed = action.speed * bundle.speed_mul
	request.lifetime = action.lifetime * bundle.lifetime_mul
	request.radius = action.radius * bundle.size_mul
	request.pierce = max(0, action.pierce + bundle.pierce_add)
	request.bounce = max(0, action.bounce + bundle.bounce_add)
	request.explosion_radius = action.explosion_radius
	request.projectile_color = action.projectile_color
	request.on_hit_effects = action.on_hit_effects.duplicate()
	request.echo_delay = bundle.echo_delay
	_log("[法术解析] 发射请求：%s 伤害=%.1f 速度=%.1f" % [
		request.display_name,
		request.damage,
		request.speed,
	])
	return request


func _attach_trigger_payload(
	request: SpawnRequest,
	trigger_action: TriggerActionCardData,
	wand_runtime: WandRuntime,
	origin: Vector2,
	direction: Vector2,
	trigger_depth: int
) -> void:
	request.trigger_mode = trigger_action.trigger_mode
	request.trigger_delay = trigger_action.timer_delay
	request.trigger_payload = resolve_payload_requests(
		wand_runtime,
		trigger_action.payload_action_count,
		origin,
		direction,
		trigger_depth
	)
	_log("[法术解析] 已为 %s 绑定触发载荷：%d 个请求" % [
		request.display_name,
		request.trigger_payload.size(),
	])


func _log(message: String) -> void:
	debug_lines.append(message)
	print(message)
