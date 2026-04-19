class_name SpellCardData
extends Resource

const RARITY_COMMON := 0
const RARITY_RARE := 1
const RARITY_LEGENDARY := 2

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: float = 0.0
@export_range(0, 2, 1) var rarity: int = RARITY_COMMON
@export var icon: Texture2D
@export var category: StringName = &"projectile"
@export var buy_cost: int = 3
@export var shop_weight: float = 1.0
@export var can_appear_in_shop: bool = true
@export var max_owned_count: int = -1


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return String(id)


func get_category_text() -> String:
	if category == &"":
		return "unknown"
	return String(category)


func get_rarity_text() -> String:
	match clampi(rarity, RARITY_COMMON, RARITY_LEGENDARY):
		RARITY_RARE:
			return "稀有"
		RARITY_LEGENDARY:
			return "传说"
		_:
			return "普通"


func get_rarity_color() -> Color:
	match clampi(rarity, RARITY_COMMON, RARITY_LEGENDARY):
		RARITY_RARE:
			return Color(0.25, 0.55, 1.0, 1.0)
		RARITY_LEGENDARY:
			return Color(1.0, 0.58, 0.08, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)
