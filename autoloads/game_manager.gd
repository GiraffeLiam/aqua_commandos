# res://autoloads/game_manager.gd
# GameManager — 監聽 EventBus 信號後執行對應邏輯的全局大管家。
# 負責：GameState 管理、場景切換、結算流程、Dialogic 2 對話控制。
extends Node


func _ready() -> void:
	event_bus.dress_phase_cleared.connect(_on_dress_phase_cleared)
	event_bus.player_died.connect(_on_player_died)


# 單階段原型：禮裝清空＝Boss 擊敗。
# 多階段時改為追蹤所有 phase，最後一層清空才發 boss_defeated。
func _on_dress_phase_cleared() -> void:
	print("【勝利】Boss 的禮裝已被完全摧毀！")
	event_bus.boss_defeated.emit()


# 階段 1–2 玩家不受傷，此路徑暫時休眠，階段 3 才會真正觸發。
func _on_player_died() -> void:
	print("【失敗】玩家被擊倒...")
