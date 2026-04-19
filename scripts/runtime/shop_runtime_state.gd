class_name ShopRuntimeState
extends Resource

@export var current_offers: Array[ShopOffer] = []
@export var refresh_count_in_current_visit: int = 0
@export var last_seed: int = 0


func find_offer(offer_id: String) -> ShopOffer:
	for offer in current_offers:
		if offer != null and offer.offer_id == offer_id:
			return offer
	return null


func reset_visit() -> void:
	refresh_count_in_current_visit = 0
