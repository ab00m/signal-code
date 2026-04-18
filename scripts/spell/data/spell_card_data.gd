class_name SpellCardData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: float = 0.0


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return String(id)
