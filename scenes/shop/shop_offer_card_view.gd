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
		description_label.text = "暂无商品"
		meta_label.text = ""
		price_label.text = ""
		_apply_text_color(Color(0.7, 0.7, 0.7, 1.0))
		return

	offer_id = offer.offer_id
	disabled = offer.is_purchased
	name_label.text = card.get_display_name()
	description_label.text = _build_card_description(card)
	meta_label.text = "%s  %s" % [card.get_category_text().to_upper(), card.get_rarity_text()]
	price_label.text = "已售" if offer.is_purchased else "购买 %dG" % offer.price
	_apply_text_color(card.get_rarity_color())


func configure_locked(slot_index: int, unlock_level: int) -> void:
	offer_id = ""
	disabled = true
	name_label.text = "未解锁"
	description_label.text = "达到 LV %d 解锁" % unlock_level
	meta_label.text = "商店槽 %02d" % (slot_index + 1)
	price_label.text = "锁定"
	_apply_text_color(Color(0.45, 0.45, 0.45, 1.0))


func _build_card_description(card: SpellCardData) -> String:
	var lines: Array[String] = []
	if not card.description.is_empty():
		lines.append(card.description)
	lines.append("伤害：%s" % _format_damage(card))
	lines.append("施法延迟：%s" % _format_delay(card.cast_delay))
	lines.append("充能延迟：%s" % _format_delay(card.recharge_time))
	return "\n".join(lines)


func _format_damage(card: SpellCardData) -> String:
	if card is ActionCardData:
		var action := card as ActionCardData
		return "%.0f" % action.damage
	return "-"


func _format_delay(value: float) -> String:
	if absf(value) <= 0.0001:
		return "0.00s"
	var sign := "+" if value > 0.0 else ""
	return "%s%.2fs" % [sign, value]


func _apply_text_color(color: Color) -> void:
	name_label.add_theme_color_override("font_color", color)
	meta_label.add_theme_color_override("font_color", color)
	price_label.add_theme_color_override("font_color", color)


func _on_pressed() -> void:
	if offer_id.is_empty():
		return
	buy_clicked.emit(offer_id)
