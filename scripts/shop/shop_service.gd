class_name ShopService
extends RefCounted

const SHOP_OFFER_COUNT := 4
const SHOP_BASE_REFRESH_COST := 2

var spell_database: SpellCardDatabase


func _init(database: SpellCardDatabase = null) -> void:
	spell_database = database


func get_current_refresh_cost(_run_state: RunState) -> int:
	return SHOP_BASE_REFRESH_COST


func ensure_offers(run_state: RunState) -> void:
	if run_state == null:
		return
	if run_state.shop_state == null:
		run_state.shop_state = ShopRuntimeState.new()
	if run_state.shop_state.current_offers.is_empty():
		refresh_shop_free(run_state)


func refresh_shop_free(run_state: RunState) -> void:
	var seed := randi()
	run_state.shop_state.last_seed = seed
	run_state.shop_state.current_offers = generate_offers(SHOP_OFFER_COUNT, seed)


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


func generate_offers(count: int, seed: int = 0) -> Array[ShopOffer]:
	var offers: Array[ShopOffer] = []
	if spell_database == null:
		return offers
	var candidates := spell_database.get_shop_candidate_cards()
	if candidates.is_empty():
		return offers
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else randi()
	while offers.size() < count and not candidates.is_empty():
		var card := _weighted_pick(candidates, rng)
		if card == null:
			break
		offers.append(ShopOffer.create(card.id, maxi(0, card.buy_cost)))
		candidates.erase(card)
	return offers


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
