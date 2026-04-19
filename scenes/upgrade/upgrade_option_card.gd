class_name UpgradeOptionCard
extends Button

signal option_selected(option_id: StringName)

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var meta_label: Label = %MetaLabel

var option_id: StringName


func _ready() -> void:
	pressed.connect(_on_pressed)


func configure(option: UpgradeOptionConfig) -> void:
	if option == null:
		disabled = true
		option_id = &""
		name_label.text = ""
		description_label.text = ""
		meta_label.text = ""
		return

	disabled = false
	option_id = option.id
	name_label.text = option.display_name
	description_label.text = option.description
	meta_label.text = "%s  Lv.%d" % [String(option.category).to_upper(), option.rarity + 1]


func _on_pressed() -> void:
	if option_id == &"":
		return
	disabled = true
	option_selected.emit(option_id)
