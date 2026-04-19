class_name ShopPage
extends Control

signal request_close_page

const DEFAULT_DATABASE: SpellCardDatabase = preload("res://resources/spells/spell_card_database.tres")
const DEFAULT_WAND: WandData = preload("res://resources/spells/wands/combat_default_wand.tres")
const OFFER_CARD_SCENE: PackedScene = preload("res://scenes/shop/shop_offer_card_view.tscn")
const SLOT_SCENE: PackedScene = preload("res://scenes/shop/spell_slot_view.tscn")

@export var spell_database: SpellCardDatabase = DEFAULT_DATABASE
@export var template_wand: WandData = DEFAULT_WAND
@export var run_state: RunState

@onready var gold_label: Label = %GoldLabel
@onready var refresh_cost_label: Label = %RefreshCostLabel
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel
@onready var offer_grid: GridContainer = %OfferGrid
@onready var refresh_button: Button = %RefreshButton
@onready var capacity_label: Label = %CapacityLabel
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var slot_count_label: Label = %SlotCountLabel
@onready var loadout_slots: HBoxContainer = %LoadoutSlots

var shop_service: ShopService
var collection_service: SpellCollectionService
var saved_wand_data: WandData


func _ready() -> void:
	if run_state == null:
		run_state = _build_demo_run_state()
	_bind_services()
	_connect_buttons()
	shop_service.ensure_offers(run_state)
	_refresh_all("商店已打开")


func configure(state: RunState) -> void:
	run_state = state
	if is_node_ready():
		_bind_services()
		shop_service.ensure_offers(run_state)
		_refresh_all("商店已打开")


func get_saved_wand_data() -> WandData:
	return saved_wand_data


func _bind_services() -> void:
	if run_state.shop_state == null:
		run_state.shop_state = ShopRuntimeState.new()
	run_state.spell_database = spell_database
	shop_service = ShopService.new(spell_database)
	collection_service = SpellCollectionService.new(run_state)


func _connect_buttons() -> void:
	if not refresh_button.pressed.is_connected(_on_refresh_pressed):
		refresh_button.pressed.connect(_on_refresh_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)


func _refresh_all(message: String = "") -> void:
	gold_label.text = "金币：%d" % run_state.gold
	refresh_cost_label.text = "刷新费用：%dG" % shop_service.get_current_refresh_cost(run_state)
	capacity_label.text = "背包：%d / %d" % [
		_count_entries(run_state.inventory_spell_entries),
		run_state.inventory_capacity,
	]
	slot_count_label.text = "施法栏：%d / %d" % [
		_count_entries(run_state.loadout_spell_entries),
		run_state.spell_slot_count,
	]
	if not message.is_empty():
		status_label.text = message
	_render_shop()
	_render_inventory()
	_render_loadout()


func _render_shop() -> void:
	_clear_children(offer_grid)
	for offer in run_state.shop_state.current_offers:
		var card := spell_database.get_spell_card(offer.spell_id)
		var view := OFFER_CARD_SCENE.instantiate() as ShopOfferCardView
		offer_grid.add_child(view)
		view.configure(offer, card)
		view.buy_clicked.connect(_on_buy_clicked)


func _render_inventory() -> void:
	_clear_children(inventory_grid)
	for index in range(run_state.inventory_capacity):
		var entry: SpellEntry = null
		var card: SpellCardData = null
		if index < run_state.inventory_spell_entries.size():
			entry = run_state.inventory_spell_entries[index]
			if entry != null:
				card = spell_database.get_spell_card(entry.spell_id)
		var slot := SLOT_SCENE.instantiate() as SpellSlotView
		inventory_grid.add_child(slot)
		slot.configure(SpellCollectionService.CONTAINER_INVENTORY, index, entry, card)
		slot.drop_requested.connect(_on_drop_requested)


func _render_loadout() -> void:
	_clear_children(loadout_slots)
	for index in range(run_state.spell_slot_count):
		var entry: SpellEntry = null
		var card: SpellCardData = null
		if index < run_state.loadout_spell_entries.size():
			entry = run_state.loadout_spell_entries[index]
			if entry != null:
				card = spell_database.get_spell_card(entry.spell_id)
		var slot := SLOT_SCENE.instantiate() as SpellSlotView
		loadout_slots.add_child(slot)
		slot.configure(SpellCollectionService.CONTAINER_LOADOUT, index, entry, card)
		slot.drop_requested.connect(_on_drop_requested)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _count_entries(entries: Array[SpellEntry]) -> int:
	var count := 0
	for entry in entries:
		if entry != null:
			count += 1
	return count


func _on_buy_clicked(offer_id: String) -> void:
	var result := shop_service.try_buy_offer(run_state, offer_id)
	_refresh_all(String(result["message"]))


func _on_refresh_pressed() -> void:
	var result := shop_service.try_refresh_shop(run_state)
	_refresh_all(String(result["message"]))


func _on_drop_requested(
	source_container: StringName,
	source_index: int,
	target_container: StringName,
	target_index: int
) -> void:
	var result := collection_service.move_between_containers(
		source_container,
		source_index,
		target_container,
		target_index
	)
	_refresh_all(String(result["message"]))


func _on_close_pressed() -> void:
	saved_wand_data = run_state.build_wand_data_from_loadout(template_wand)
	status_label.text = "已保存施法栏：%d 张" % saved_wand_data.deck.size()
	request_close_page.emit()


func _build_demo_run_state() -> RunState:
	var state := RunState.new()
	state.spell_database = spell_database
	state.gold = 12
	state.inventory_capacity = 20
	state.spell_slot_count = 3
	state.shop_state = ShopRuntimeState.new()
	var loadout_entries: Array[SpellEntry] = []
	loadout_entries.append(SpellEntry.create(&"signal_bolt", &"start_loadout", 0))
	state.loadout_spell_entries = loadout_entries
	var inventory_entries: Array[SpellEntry] = []
	inventory_entries.append(SpellEntry.create(&"spark_bolt", &"debug", 0))
	inventory_entries.append(SpellEntry.create(&"damage_up", &"debug", 0))
	inventory_entries.append(SpellEntry.create(&"fireball", &"debug", 0))
	state.inventory_spell_entries = inventory_entries
	return state
