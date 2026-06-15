# res://boss/dress/tile_hit_box.gd
class_name TileHitBox
extends Area2D

var tile_coord: Vector2i = Vector2i.ZERO


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	print("TileHitBox 自身收到 area_entered，來自：", area.name)
