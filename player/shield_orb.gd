# res://player/shield_orb.gd
# ShieldOrb — 無敵期間的半透明圓球遮罩。用內建 _draw 畫圓，預設隱藏。
# 由 Invincibility 元件控制顯示/隱藏；置於 HurtBox 中心、半徑略大於 HurtBox。
class_name ShieldOrb
extends Node2D

@export var orb_radius: float = 24.0
@export var orb_color: Color = Color(0.4, 0.7, 1.0, 0.35)


func _ready() -> void:
	visible = false


func _draw() -> void:
	draw_circle(Vector2.ZERO, orb_radius, orb_color)
