class_name UpgradeSelectionPanel
extends CanvasLayer

signal option_selected(option_id: StringName)

const CARD_SCENE: PackedScene = preload("res://scenes/upgrade/upgrade_option_card.tscn")

@onready var level_label: Label = %LevelLabel
@onready var cards_row: HBoxContainer = %CardsRow


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide_panel()


func show_choices(level: int, options: Array[UpgradeOptionConfig]) -> void:
	_clear_cards()
	level_label.text = "LEVEL %d UPGRADE" % level
	for option in options:
		var card := CARD_SCENE.instantiate() as UpgradeOptionCard
		cards_row.add_child(card)
		card.configure(option)
		card.option_selected.connect(_on_card_selected)
	show()


func hide_panel() -> void:
	hide()
	_clear_cards()


func _clear_cards() -> void:
	if cards_row == null:
		return
	for child in cards_row.get_children():
		child.queue_free()


func _on_card_selected(option_id: StringName) -> void:
	option_selected.emit(option_id)
