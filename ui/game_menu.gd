# res://ui/game_menu.gd
# GameMenu — 全局選單彈窗。按 ui_cancel（Esc）開關，開啟時暫停遊戲（暫停選單）。
# process_mode 設 Always，暫停中仍能收 Esc 把它關掉。結算後（game_over）不再能開。
# 按鈕：繼續遊戲＝關閉解除暫停；離開遊戲＝結束程式；其餘留待後續階段接。
class_name GameMenu
extends Control

var _game_ended: bool = false


func _ready() -> void:
	visible = false
	event_bus.game_over.connect(_on_game_over)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	# 結算後不開選單，避免關閉時把結算的暫停一起解除
	if _game_ended:
		return
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	visible = true
	get_tree().paused = true


func _close() -> void:
	visible = false
	get_tree().paused = false


func _on_game_over(_won: bool) -> void:
	_game_ended = true


# ── 按鈕回呼（在編輯器把各按鈕的 pressed 連到對應函式）─────────
# 繼續遊戲


func _on_continue_pressed() -> void:
	_close()


# 退出任務（放棄本場 → 之後接 SceneManager 回標題/重開；片 1 暫留空）
func _on_quit_run_pressed() -> void:
	pass


# 設定（之後接設定面板）
func _on_settings_pressed() -> void:
	pass


# 返回標題（4-2 SceneManager 串接後實作）
func _on_back_to_title_pressed() -> void:
	pass


# 離開遊戲
func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	_close()
