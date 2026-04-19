class_name RunState
extends Resource

@export var gold: int = 0
@export var inventory_spell_entries: Array[SpellEntry] = []
@export var loadout_spell_entries: Array[SpellEntry] = []
@export var shop_state: ShopRuntimeState = ShopRuntimeState.new()
@export var inventory_capacity: int = 20
@export var spell_slot_count: int = 3
@export var current_wave: int = 0
@export var spell_database: SpellCardDatabase


func get_gold() -> int:
	return gold


func can_afford(cost: int) -> bool:
	return gold >= cost


func spend_gold(cost: int) -> bool:
	if cost < 0 or not can_afford(cost):
		return false
	gold -= cost
	return true


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount


func set_player_spell_loadout(entries: Array[SpellEntry]) -> void:
	loadout_spell_entries = entries.duplicate()


func get_player_spell_loadout() -> Array[SpellEntry]:
	return loadout_spell_entries.duplicate()


func build_wand_data_from_loadout(template_wand: WandData = null) -> WandData:
	var wand := WandData.new()
	if template_wand != null:
		wand = template_wand.duplicate(true) as WandData
	var deck: Array[SpellCardData] = []
	if spell_database == null:
		wand.deck = deck
		return wand
	for entry in loadout_spell_entries:
		if entry == null:
			continue
		var card := spell_database.duplicate_card_for_runtime(entry.spell_id)
		if card != null:
			deck.append(card)
	wand.deck = deck
	return wand
