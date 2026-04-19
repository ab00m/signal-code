class_name SpellCardData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: float = 0.0
@export_range(0, 3, 1) var rarity: int = 0
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
