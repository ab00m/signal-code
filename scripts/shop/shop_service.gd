class_name ShopService
extends RefCounted

const SHOP_MIN_OFFER_COUNT := 3
const SHOP_MAX_OFFER_COUNT := 6
const SHOP_SLOT_UNLOCK_LEVELS := [1, 1, 1, 3, 5, 8]
const SHOP_BASE_REFRESH_COST := 2

var spell_database: SpellCardDatabase


func _init(database: SpellCardDatabase = null) -> void:
	spell_database = database


func get_current_refresh_cost(_run_state: RunState) -> int:
	return SHOP_BASE_REFRESH_COST


func get_unlocked_offer_count(run_state: RunState) -> int:
	var level := 1
	if run_state != null:
		level = maxi(1, run_state.player_level)
	var unlocked_count := 0
	for unlock_level in SHOP_SLOT_UNLOCK_LEVELS:
		if level >= int(unlock_level):
			unlocked_count += 1
	return clampi(unlocked_count, SHOP_MIN_OFFER_COUNT, SHOP_MAX_OFFER_COUNT)


func get_offer_unlock_level(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SHOP_SLOT_UNLOCK_LEVELS.size():
		return 1
	return int(SHOP_SLOT_UNLOCK_LEVELS[slot_index])


func get_rarity_ratio_text(run_state: RunState) -> String:
	var offer_count := get_unlocked_offer_count(run_state)
	if offer_count >= 6:
		return "普通:稀有:传说 = 1:1:1"
	if offer_count >= 5:
		return "普通:稀有:传说 = 3:1:1"
	if offer_count >= 4:
		return "普通:稀有 = 3:1"
	return "仅普通"


func ensure_offers(run_state: RunState) -> void:
	if run_state == null:
		return
	if run_state.shop_state == null:
		run_state.shop_state = ShopRuntimeState.new()
	var expected_count := get_unlocked_offer_count(run_state)
	if run_state.shop_state.current_offers.size() != expected_count:
		refresh_shop_free(run_state)


func refresh_shop_free(run_state: RunState) -> void:
	var seed := randi()
	run_state.shop_state.last_seed = seed
	run_state.shop_state.current_offers = generate_offers(get_unlocked_offer_count(run_state), seed, run_state)


func try_refresh_shop(run_state: RunState) -> Dictionary:
	if run_state == null:
		return _fail("Missing run state")
	var cost := get_current_refresh_cost(run_state)
	if not run_state.spend_gold(cost):
		return _fail("Not enough gold")
	run_state.shop_state.refresh_count_in_current_visit += 1
	refresh_shop_free(run_state)
	return _ok("Shop refreshed")


func try_buy_offer(run_state: RunState, offer_id: String) -> Dictionary:
	if run_state == null:
		return _fail("Missing run state")
	if run_state.shop_state == null:
		return _fail("Missing shop state")
	var offer := run_state.shop_state.find_offer(offer_id)
	if offer == null:
		return _fail("Offer not found")
	if offer.is_purchased:
		return _fail("Already purchased")
	var card := _get_spell_card(offer.spell_id)
	if card == null:
		return _fail("Spell config missing")
	if run_state.gold < offer.price:
		return _fail("Not enough gold")
	if run_state.inventory_spell_entries.size() >= run_state.inventory_capacity:
		return _fail("Inventory full")
	if _reached_spell_ownership_limit(run_state, card):
		return _fail("Cannot own more copies")

	run_state.gold -= offer.price
	run_state.inventory_spell_entries.append(SpellEntry.create(offer.spell_id, &"shop", run_state.current_wave))
	offer.is_purchased = true
	return _ok("Purchased")


func generate_offers(count: int, seed: int = 0, _run_state: RunState = null) -> Array[ShopOffer]:
	var offers: Array[ShopOffer] = []
	if spell_database == null:
		return offers
	var offer_count := clampi(count, SHOP_MIN_OFFER_COUNT, SHOP_MAX_OFFER_COUNT)
	var candidates := _filter_candidates_by_unlocked_rarity(
		spell_database.get_shop_candidate_cards(),
		_get_unlocked_rarities(offer_count)
	)
	if candidates.is_empty():
		return offers
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else randi()
	while offers.size() < offer_count and not candidates.is_empty():
		var selected_rarity := _pick_rarity_for_offer(candidates, offer_count, rng)
		var rarity_candidates := _filter_candidates_by_rarity(candidates, selected_rarity)
		var card := _weighted_pick(rarity_candidates if not rarity_candidates.is_empty() else candidates, rng)
		if card == null:
			break
		offers.append(ShopOffer.create(card.id, maxi(0, card.buy_cost)))
		candidates.erase(card)
	return offers


func _get_unlocked_rarities(offer_count: int) -> Array[int]:
	var rarities: Array[int] = [SpellCardData.RARITY_COMMON]
	if offer_count >= 4:
		rarities.append(SpellCardData.RARITY_RARE)
	if offer_count >= 5:
		rarities.append(SpellCardData.RARITY_LEGENDARY)
	return rarities


func _filter_candidates_by_unlocked_rarity(
	candidates: Array[SpellCardData],
	unlocked_rarities: Array[int]
) -> Array[SpellCardData]:
	var result: Array[SpellCardData] = []
	for card in candidates:
		if card != null and unlocked_rarities.has(_normalize_rarity(card.rarity)):
			result.append(card)
	return result


func _filter_candidates_by_rarity(candidates: Array[SpellCardData], rarity: int) -> Array[SpellCardData]:
	var result: Array[SpellCardData] = []
	for card in candidates:
		if card != null and _normalize_rarity(card.rarity) == rarity:
			result.append(card)
	return result


func _pick_rarity_for_offer(
	candidates: Array[SpellCardData],
	offer_count: int,
	rng: RandomNumberGenerator
) -> int:
	var total_weight := 0.0
	for rarity in _get_unlocked_rarities(offer_count):
		if _filter_candidates_by_rarity(candidates, rarity).is_empty():
			continue
		total_weight += _get_rarity_roll_weight(offer_count, rarity)
	if total_weight <= 0.0:
		return -1

	var roll := rng.randf() * total_weight
	for rarity in _get_unlocked_rarities(offer_count):
		if _filter_candidates_by_rarity(candidates, rarity).is_empty():
			continue
		roll -= _get_rarity_roll_weight(offer_count, rarity)
		if roll <= 0.0:
			return rarity
	return SpellCardData.RARITY_COMMON


func _get_rarity_roll_weight(offer_count: int, rarity: int) -> float:
	if offer_count >= 6:
		return 1.0
	if offer_count >= 5:
		return 3.0 if rarity == SpellCardData.RARITY_COMMON else 1.0
	if offer_count >= 4:
		return 3.0 if rarity == SpellCardData.RARITY_COMMON else 1.0
	return 1.0 if rarity == SpellCardData.RARITY_COMMON else 0.0


func _normalize_rarity(rarity: int) -> int:
	return clampi(rarity, SpellCardData.RARITY_COMMON, SpellCardData.RARITY_LEGENDARY)


func _weighted_pick(candidates: Array[SpellCardData], rng: RandomNumberGenerator) -> SpellCardData:
	var total_weight := 0.0
	for card in candidates:
		total_weight += maxf(0.0, card.shop_weight)
	if total_weight <= 0.0:
		return candidates[0] if not candidates.is_empty() else null

	var roll := rng.randf() * total_weight
	for card in candidates:
		roll -= maxf(0.0, card.shop_weight)
		if roll <= 0.0:
			return card
	return candidates[candidates.size() - 1]


func _reached_spell_ownership_limit(run_state: RunState, card: SpellCardData) -> bool:
	if card.max_owned_count < 0:
		return false
	var count := 0
	for entry in run_state.inventory_spell_entries:
		if entry != null and entry.spell_id == card.id:
			count += 1
	for entry in run_state.loadout_spell_entries:
		if entry != null and entry.spell_id == card.id:
			count += 1
	return count >= card.max_owned_count


func _get_spell_card(spell_id: StringName) -> SpellCardData:
	if spell_database == null:
		return null
	return spell_database.get_spell_card(spell_id)


func _ok(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _fail(message: String) -> Dictionary:
	return {"success": false, "message": message}
