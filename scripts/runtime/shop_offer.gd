class_name ShopOffer
extends Resource

@export var offer_id: String = ""
@export var spell_id: StringName = &""
@export var price: int = 0
@export var is_purchased: bool = false


static func create(spell_id_value: StringName, price_value: int) -> ShopOffer:
	var offer := ShopOffer.new()
	offer.offer_id = "%s_offer_%d_%d" % [String(spell_id_value), Time.get_ticks_usec(), randi()]
	offer.spell_id = spell_id_value
	offer.price = price_value
	offer.is_purchased = false
	return offer
