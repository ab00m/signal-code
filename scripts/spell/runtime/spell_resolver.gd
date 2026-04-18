class_name SpellResolver
extends RefCounted

var debug_lines: Array[String] = []


func resolve_main_cast(wand_runtime: WandRuntime, origin: Vector2, direction: Vector2) -> Array[SpawnRequest]:
	debug_lines.clear()
	_log("[SpellResolver] Begin cast index=%d" % wand_runtime.get_deck_index())

	var results: Array[SpawnRequest] = []
	var wand_data := wand_runtime.wand_data
	if wand_data == null:
		_log("[SpellResolver] Abort: missing WandData")
		return results
	if wand_data.deck.is_empty():
		_log("[SpellResolver] Abort: empty deck")
		return results

	var remaining_main_actions: int = max(1, wand_data.draws_per_cast)
	while remaining_main_actions > 0:
		var group := resolve_next_group(wand_runtime)
		if group.is_empty():
			_log("[SpellResolver] Cast failed: no Action found")
			break

		var group_requests := build_requests_from_group(group, origin, direction)
		results.append_array(group_requests)
		remaining_main_actions -= max(1, group.get_consumed_action_count())

	_log("[SpellResolver] Spawn requests built: %d" % results.size())
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

		_log("[SpellResolver] Draw card: %s" % card.get_display_name())

		if card is ModifierCardData:
			var modifier := card as ModifierCardData
			if modifier.modifier_type == ModifierCardData.ModifierType.MULTICAST:
				if multicast_seen:
					_log("[SpellResolver] Warning: extra multicast ignored")
					continue
				multicast_seen = true
				target_action_count = max(1, modifier.value_int)
				group.target_action_count = target_action_count
				group.modifiers.append(modifier)
				_log("[SpellResolver] Group target actions set to %d" % target_action_count)
			else:
				group.modifiers.append(modifier)
		elif card is ActionCardData:
			group.actions.append(card as ActionCardData)
		else:
			_log("[SpellResolver] Warning: unsupported card ignored")

	if group.actions.is_empty():
		_log("[SpellResolver] Group failed after %d draws" % drawn)
	elif group.actions.size() < target_action_count:
		_log("[SpellResolver] Warning: group resolved partially after full deck scan")

	_log("[SpellResolver] Group resolved: %s" % group.describe())
	return group


func build_requests_from_group(
	group: SpellGroup,
	origin: Vector2,
	direction: Vector2
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
			results.append(_build_request(action, bundle, origin, base_direction.rotated(deg_to_rad(offset))))

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
	request.lifetime = action.lifetime
	request.radius = action.radius
	request.explosion_radius = action.explosion_radius
	request.projectile_color = action.projectile_color
	_log("[SpellResolver] Request: %s damage=%.1f speed=%.1f" % [
		request.display_name,
		request.damage,
		request.speed,
	])
	return request


func _log(message: String) -> void:
	debug_lines.append(message)
	print(message)
