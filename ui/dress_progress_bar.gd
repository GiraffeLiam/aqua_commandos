# res://ui/dress_progress_bar.gd
# DressProgressBar — 監聽 dress_progress_changed，顯示禮裝剩餘比例。
# 滿（1.0）= 禮裝完整；歸零 = 禮裝全毀。掛在 ProgressBar 上。
class_name DressProgressBar
extends ProgressBar


func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	value = 1.0
	show_percentage = true
	event_bus.dress_progress_changed.connect(_on_dress_progress_changed)


func _on_dress_progress_changed(alive_pct: float) -> void:
	value = alive_pct
