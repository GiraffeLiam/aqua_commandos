# res://ui/game_over_popup.gd
# GameOverPopup — 監聽 game_over，顯示勝/負訊息的覆蓋層。預設隱藏。
# 無場景切換（重新開始/回選單是階段 4）。
# 本節點 process_mode 設 Always，暫停時仍運作（為日後按鈕鋪路）。
class_name GameOverPopup
extends Control

@export var message_label: Label
@export var win_text: String = "勝利！"
@export var lose_text: String = "失敗..."


func _ready() -> void:
	visible = false
	event_bus.game_over.connect(_on_game_over)


func _on_game_over(won: bool) -> void:
	if message_label:
		message_label.text = win_text if won else lose_text
	visible = true
