class_name ShopPage
extends Control

signal request_close_page
signal debug_experience_requested(amount: int)

const DEFAULT_DATABASE: SpellCardDatabase = preload("res://resources/spells/spell_card_database.tres")
const DEFAULT_WAND: WandData = preload("res://resources/spells/wands/combat_default_wand.tres")
const OFFER_CARD_SCENE: PackedScene = preload("res://scenes/shop/shop_offer_card_view.tscn")
const SLOT_SCENE: PackedScene = preload("res://scenes/shop/spell_slot_view.tscn")
const INVENTORY_SLOT_COUNT := 12

@export var spell_database: SpellCardDatabase = DEFAULT_DATABASE
@export var template_wand: WandData = DEFAULT_WAND
@export var run_state: RunState

@onready var gold_label: Label = %GoldLabel
@onready var refresh_cost_label: Label = %RefreshCostLabel
@onready var debug_exp_button: Button = %DebugExpButton
@onready var debug_gold_button: Button = %DebugGoldButton
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel
@onready var offer_grid: GridContainer = %OfferGrid
@onready var refresh_button: Button = %RefreshButton
@onready var shop_info_label: Label = %ShopInfoLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var slot_count_label: Label = %SlotCountLabel
@onready var loadout_slots: GridContainer = %LoadoutSlots

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


func refresh_current_state(message: String = "") -> void:
	if run_state == null:
		return
	_bind_services()
	shop_service.ensure_offers(run_state)
	_refresh_all(message)


func _bind_services() -> void:
	if run_state.shop_state == null:
		run_state.shop_state = ShopRuntimeState.new()
	run_state.spell_database = spell_database
	run_state.inventory_capacity = INVENTORY_SLOT_COUNT
	run_state.spell_slot_count = run_state.get_unlocked_spell_slot_count()
	shop_service = ShopService.new(spell_database)
	collection_service = SpellCollectionService.new(run_state)


func _connect_buttons() -> void:
	if not debug_exp_button.pressed.is_connected(_on_debug_exp_pressed):
		debug_exp_button.pressed.connect(_on_debug_exp_pressed)
	if not debug_gold_button.pressed.is_connected(_on_debug_gold_pressed):
		debug_gold_button.pressed.connect(_on_debug_gold_pressed)
	if not refresh_button.pressed.is_connected(_on_refresh_pressed):
		refresh_button.pressed.connect(_on_refresh_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)


func _refresh_all(message: String = "") -> void:
	gold_label.text = "金币：%d" % run_state.gold
	refresh_cost_label.text = "刷新费用：%dG" % shop_service.get_current_refresh_cost(run_state)
	shop_info_label.text = "商店等级：LV %d｜槽位：%d / %d｜%s" % [
		run_state.player_level,
		shop_service.get_unlocked_offer_count(run_state),
		ShopService.SHOP_MAX_OFFER_COUNT,
		shop_service.get_rarity_ratio_text(run_state),
	]
	capacity_label.text = "背包：%d / %d" % [
		_count_entries(run_state.inventory_spell_entries),
		run_state.inventory_capacity,
	]
	slot_count_label.text = "施法栏：%d / %d" % [
		_count_entries(run_state.loadout_spell_entries, run_state.spell_slot_count),
		run_state.spell_slot_count,
	]
	if not message.is_empty():
		status_label.text = message
	_render_shop()
	_render_inventory()
	_render_loadout()


func _render_shop() -> void:
	_clear_children(offer_grid)
	offer_grid.columns = ShopService.SHOP_MAX_OFFER_COUNT
	var unlocked_count := shop_service.get_unlocked_offer_count(run_state)
	for index in range(ShopService.SHOP_MAX_OFFER_COUNT):
		var view := OFFER_CARD_SCENE.instantiate() as ShopOfferCardView
		offer_grid.add_child(view)
		if index >= unlocked_count:
			view.configure_locked(index, shop_service.get_offer_unlock_level(index))
		elif index < run_state.shop_state.current_offers.size():
			var offer := run_state.shop_state.current_offers[index]
			var card := spell_database.get_spell_card(offer.spell_id)
			view.configure(offer, card)
		else:
			view.configure(null, null)
		view.buy_clicked.connect(_on_buy_clicked)


func _render_inventory() -> void:
	_clear_children(inventory_grid)
	inventory_grid.columns = INVENTORY_SLOT_COUNT
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
	loadout_slots.columns = mini(RunState.MAX_SPELL_SLOT_COUNT, run_state.spell_slot_count)
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


func _count_entries(entries: Array[SpellEntry], limit: int = -1) -> int:
	var count := 0
	var entry_count := entries.size()
	if limit >= 0:
		entry_count = mini(entry_count, limit)
	for index in range(entry_count):
		if entries[index] != null:
			count += 1
	return count


func _on_debug_exp_pressed() -> void:
	debug_experience_requested.emit(10)
	if debug_experience_requested.get_connections().is_empty():
		run_state.player_level += 1
		refresh_current_state("调试：+10经验")


func _on_debug_gold_pressed() -> void:
	run_state.add_gold(10)
	_refresh_all("调试：+10金币")


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
	state.inventory_capacity = INVENTORY_SLOT_COUNT
	state.player_level = 1
	state.spell_slot_count = state.get_unlocked_spell_slot_count()
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
