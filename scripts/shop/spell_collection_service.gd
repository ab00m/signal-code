class_name SpellCollectionService
extends RefCounted

const CONTAINER_INVENTORY := &"inventory"
const CONTAINER_LOADOUT := &"loadout"

var run_state: RunState


func _init(state: RunState = null) -> void:
	run_state = state


func bind(state: RunState) -> void:
	run_state = state


func move_between_containers(
	source_container: StringName,
	source_index: int,
	target_container: StringName,
	target_index: int
) -> Dictionary:
	if run_state == null:
		return _fail("Missing run state")
	var source_list := _get_list(source_container)
	var target_list := _get_list(target_container)
	if source_list == null or target_list == null:
		return _fail("Invalid container")
	if source_index < 0 or source_index >= source_list.size():
		return _fail("Invalid source")
	if target_container == CONTAINER_LOADOUT and (target_index < 0 or target_index >= run_state.spell_slot_count):
		return _fail("Invalid loadout slot")
	if target_container == CONTAINER_INVENTORY and target_index < 0:
		return _fail("Invalid inventory slot")

	if source_container == target_container:
		if source_container == CONTAINER_LOADOUT:
			return _move_within_loadout(source_list, source_index, target_index)
		return _reorder_same_list(source_list, source_index, target_index)

	var source_entry: SpellEntry = source_list[source_index]
	if source_entry == null:
		return _fail("Invalid source")
	var has_target_entry := target_index >= 0 and target_index < target_list.size() and target_list[target_index] != null
	if not has_target_entry and not _can_insert_into(target_container):
		return _fail("Target full")

	if has_target_entry:
		var target_entry: SpellEntry = target_list[target_index]
		source_list[source_index] = target_entry
		target_list[target_index] = source_entry
	else:
		if source_container == CONTAINER_LOADOUT:
			source_list[source_index] = null
		else:
			source_list.remove_at(source_index)
		if target_container == CONTAINER_LOADOUT:
			_ensure_loadout_slot_exists(target_list, target_index)
			target_list[target_index] = source_entry
		else:
			target_list.insert(mini(target_index, target_list.size()), source_entry)

	if _has_duplicate_instances():
		return _fail("Duplicate spell instance")
	return _ok("Moved")


func _reorder_same_list(list: Array[SpellEntry], source_index: int, target_index: int) -> Dictionary:
	if list.is_empty():
		return _fail("Empty list")
	var clamped_target := clampi(target_index, 0, max(0, list.size() - 1))
	if source_index == clamped_target:
		return _ok("No change")
	var entry := list[source_index]
	list.remove_at(source_index)
	list.insert(clamped_target, entry)
	return _ok("Reordered")


func _move_within_loadout(list: Array[SpellEntry], source_index: int, target_index: int) -> Dictionary:
	if source_index < 0 or source_index >= list.size() or list[source_index] == null:
		return _fail("Invalid source")
	var clamped_target := clampi(target_index, 0, max(0, run_state.spell_slot_count - 1))
	if source_index == clamped_target:
		return _ok("No change")
	_ensure_loadout_slot_exists(list, clamped_target)
	var source_entry: SpellEntry = list[source_index]
	list[source_index] = list[clamped_target]
	list[clamped_target] = source_entry
	return _ok("Moved")


func _ensure_loadout_slot_exists(list: Array[SpellEntry], target_index: int) -> void:
	while list.size() <= target_index:
		list.append(null)


func _can_insert_into(container: StringName) -> bool:
	if container == CONTAINER_INVENTORY:
		return run_state.inventory_spell_entries.size() < run_state.inventory_capacity
	if container == CONTAINER_LOADOUT:
		return _count_entries(run_state.loadout_spell_entries) < run_state.spell_slot_count
	return false


func _count_entries(list: Array[SpellEntry]) -> int:
	var count := 0
	for entry in list:
		if entry != null:
			count += 1
	return count


func _get_list(container: StringName) -> Array[SpellEntry]:
	if container == CONTAINER_INVENTORY:
		return run_state.inventory_spell_entries
	if container == CONTAINER_LOADOUT:
		return run_state.loadout_spell_entries
	return []


func _has_duplicate_instances() -> bool:
	var seen := {}
	for entry in run_state.inventory_spell_entries:
		if entry == null or entry.instance_id.is_empty():
			continue
		if seen.has(entry.instance_id):
			return true
		seen[entry.instance_id] = true
	for entry in run_state.loadout_spell_entries:
		if entry == null or entry.instance_id.is_empty():
			continue
		if seen.has(entry.instance_id):
			return true
		seen[entry.instance_id] = true
	return false


func _ok(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _fail(message: String) -> Dictionary:
	return {"success": false, "message": message}
