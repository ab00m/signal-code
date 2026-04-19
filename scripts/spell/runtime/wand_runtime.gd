class_name WandRuntime
extends Node

@export var wand_data: WandData
@export var projectile_factory_path: NodePath
@export var debug_enabled: bool = true

var projectile_factory: ProjectileFactory
var run_modifier_controller: RunModifierController
var last_debug_lines: Array[String] = []

var _deck_index: int = 0
var _cooldown_remaining: float = 0.0


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


func can_cast() -> bool:
	return _cooldown_remaining <= 0.0 and wand_data != null and not wand_data.deck.is_empty()


func cast_once(caster: Node, origin: Vector2, direction: Vector2) -> Array[SpawnRequest]:
	var empty_results: Array[SpawnRequest] = []
	if not can_cast():
		last_debug_lines = ["[法杖运行时] 无法施法：冷却中、缺少法杖数据或牌组为空"]
		return empty_results

	var resolver := SpellResolver.new()
	resolver.run_modifier_controller = run_modifier_controller
	var requests := resolver.resolve_main_cast(self, origin, direction)
	last_debug_lines = resolver.debug_lines.duplicate()

	var factory := get_projectile_factory()
	if factory != null:
		factory.spawn_requests(requests)

	_cooldown_remaining = wand_data.cast_delay + wand_data.recharge_time
	return requests


func draw_next_card() -> SpellCardData:
	if wand_data == null or wand_data.deck.is_empty():
		return null

	_normalize_deck_index()
	var card := wand_data.deck[_deck_index]
	_deck_index = (_deck_index + 1) % wand_data.deck.size()
	return card


func get_deck_index() -> int:
	_normalize_deck_index()
	return _deck_index


func get_deck_size() -> int:
	if wand_data == null:
		return 0
	return wand_data.deck.size()


func reset_runtime() -> void:
	_deck_index = 0
	_cooldown_remaining = 0.0
	last_debug_lines.clear()


func get_projectile_factory() -> ProjectileFactory:
	if projectile_factory != null:
		return projectile_factory
	if not projectile_factory_path.is_empty():
		projectile_factory = get_node_or_null(projectile_factory_path) as ProjectileFactory
	return projectile_factory


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func _normalize_deck_index() -> void:
	if wand_data == null or wand_data.deck.is_empty():
		_deck_index = 0
		return
	_deck_index = posmod(_deck_index, wand_data.deck.size())
