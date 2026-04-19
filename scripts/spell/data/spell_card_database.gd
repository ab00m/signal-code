class_name SpellCardDatabase
extends Resource

@export var cards: Array[SpellCardData] = []


func get_spell_card(spell_id: StringName) -> SpellCardData:
	for card in cards:
		if card != null and card.id == spell_id:
			return card
	return null


func get_shop_candidate_cards() -> Array[SpellCardData]:
	var result: Array[SpellCardData] = []
	for card in cards:
		if card == null:
			continue
		if card.id == &"" or not card.can_appear_in_shop:
			continue
		if card.shop_weight <= 0.0:
			continue
		result.append(card)
	return result


func duplicate_card_for_runtime(spell_id: StringName) -> SpellCardData:
	var card := get_spell_card(spell_id)
	if card == null:
		return null
	return card.duplicate(true) as SpellCardData


func get_duplicate_ids() -> Array[StringName]:
	var seen := {}
	var duplicates: Array[StringName] = []
	for card in cards:
		if card == null or card.id == &"":
			continue
		if seen.has(card.id):
			duplicates.append(card.id)
		else:
			seen[card.id] = true
	return duplicates
