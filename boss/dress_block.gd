# res://boss/dress/dress_block.gd
class_name DressBlock
extends Area2D

const MAX_HP: int = 3
var _hp: int = MAX_HP
var _on_destroyed: Callable
var _sprite: Sprite2D


func init(
	texture: Texture2D,
	region: Rect2,
	block_size: Vector2,
	on_destroyed: Callable
) -> void:
	_on_destroyed = on_destroyed

	# Sprite2D 程序生成
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = region
	_sprite.offset = Vector2.ZERO
	_sprite.centered = true
	add_child(_sprite)

	# CollisionShape2D 程序生成
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = block_size
	shape_node.shape = rect
	add_child(shape_node)

	# 信號在子節點加入後連接
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area is Bullet:
		return
	var bullet := area as Bullet
	if bullet.try_consume():
		take_damage()


func take_damage() -> void:
	_hp -= 1
	_update_visual()
	if _hp <= 0:
		_on_destroyed.call(self)
		queue_free()


func _update_visual() -> void:
	var alpha: float = float(_hp) / float(MAX_HP)
	modulate.a = alpha
