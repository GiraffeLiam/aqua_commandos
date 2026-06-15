# res://ui/health_hud.gd
# HealthHUD — 監聽 player_health_changed，程序生成愛心顯示玩家血量。
# 掛在 HBoxContainer 上；愛心為其子節點，數量隨 max 動態增刪、尺寸固定不壓縮。
class_name HealthHUD
extends HBoxContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D
@export var heart_size: Vector2 = Vector2(32, 32)


func _ready() -> void:
	event_bus.player_health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(current: int, maximum: int) -> void:
	_ensure_heart_count(maximum)
	_update_hearts(current)


# 讓愛心節點數量剛好等於 maximum（天賦升級改變上限時自動增刪）
func _ensure_heart_count(maximum: int) -> void:
	while get_child_count() < maximum:
		var heart := TextureRect.new()
		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(heart)
	while get_child_count() > maximum:
		var last := get_child(get_child_count() - 1)
		remove_child(last)
		last.queue_free()


# 前 current 顆滿心，其餘空心
func _update_hearts(current: int) -> void:
	for i in range(get_child_count()):
		var heart := get_child(i) as TextureRect
		heart.texture = full_heart if i < current else empty_heart
