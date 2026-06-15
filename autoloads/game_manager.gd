# res://autoloads/game_manager.gd
# GameManager — 監聽 EventBus 信號後執行對應邏輯的全局大管家。
# 負責：GameState 管理、場景切換、結算流程、Dialogic 2 對話控制。
extends Node

var _is_over: bool = false


func _ready() -> void:
	event_bus.dress_phase_cleared.connect(_on_dress_phase_cleared)
	event_bus.player_died.connect(_on_player_died)


# 單階段原型：禮裝清空＝Boss 擊敗＝勝利。
func _on_dress_phase_cleared() -> void:
	_end_game(true)


func _on_player_died() -> void:
	_end_game(false)


# 結算：第一個觸發的終局事件勝出（勝或敗），之後忽略。
# 暫停整個遊戲樹並廣播結果給彈窗。
func _end_game(won: bool) -> void:
	if _is_over:
		return
	_is_over = true
	if won:
		print("【勝利】Boss 的禮裝已被完全摧毀！")
		event_bus.boss_defeated.emit()
	else:
		print("【失敗】玩家被擊倒...")
	get_tree().paused = true
	event_bus.game_over.emit(won)
