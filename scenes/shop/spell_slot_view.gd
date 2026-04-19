class_name SpellSlotView
extends PanelContainer

signal drop_requested(source_container: StringName, source_index: int, target_container: StringName, target_index: int)

@onready var title_label: Label = %TitleLabel
@onready var name_label: Label = %NameLabel
@onready var meta_label: Label = %MetaLabel

var container_name_id: StringName = &""
var slot_index: int = -1
var spell_entry: SpellEntry
var spell_card: SpellCardData


func configure(container: StringName, index: int, entry: SpellEntry, card: SpellCardData) -> void:
	container_name_id = container
	slot_index = index
	spell_entry = entry
	spell_card = card
	title_label.hide()
	meta_label.hide()
	if spell_entry == null or spell_card == null:
		name_label.text = "空"
		_apply_text_color(Color(0.7, 0.7, 0.7, 1.0))
		modulate = Color(1, 1, 1, 0.7)
	else:
		name_label.text = spell_card.get_display_name()
		_apply_text_color(spell_card.get_rarity_color())
		modulate = Color(1, 1, 1, 1)


func _apply_text_color(color: Color) -> void:
	name_label.add_theme_color_override("font_color", color)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if spell_entry == null or spell_card == null:
		return null
	var preview := Label.new()
	preview.text = spell_card.get_display_name()
	preview.add_theme_font_size_override("font_size", 14)
	set_drag_preview(preview)
	return {
		"source_container": container_name_id,
		"source_index": slot_index,
		"instance_id": spell_entry.instance_id,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("source_container") and data.has("source_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	drop_requested.emit(
		StringName(data["source_container"]),
		int(data["source_index"]),
		container_name_id,
		slot_index
	)
