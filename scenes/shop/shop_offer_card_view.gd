class_name ShopOfferCardView
extends Button

signal buy_clicked(offer_id: String)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var meta_label: Label = %MetaLabel
@onready var price_label: Label = %PriceLabel

var offer_id: String = ""


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func configure(offer: ShopOffer, card: SpellCardData) -> void:
	if offer == null or card == null:
		offer_id = ""
		disabled = true
		name_label.text = "空"
		description_label.text = ""
		meta_label.text = ""
		price_label.text = ""
		return

	offer_id = offer.offer_id
	disabled = offer.is_purchased
	name_label.text = card.get_display_name()
	description_label.text = card.description
	meta_label.text = "%s  R%d" % [card.get_category_text().to_upper(), card.rarity + 1]
	price_label.text = "已售" if offer.is_purchased else "购买 %dG" % offer.price


func _on_pressed() -> void:
	if offer_id.is_empty():
		return
	buy_clicked.emit(offer_id)
