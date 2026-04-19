extends Control

@onready var shop_page: ShopPage = %ShopPage
@onready var saved_label: Label = %SavedLabel


func _ready() -> void:
	if not shop_page.request_close_page.is_connected(_on_shop_closed):
		shop_page.request_close_page.connect(_on_shop_closed)


func _on_shop_closed() -> void:
	var saved_wand := shop_page.get_saved_wand_data()
	var count := 0
	if saved_wand != null:
		count = saved_wand.deck.size()
	saved_label.text = "已保存施法栏，可供战斗读取：%d 张" % count
