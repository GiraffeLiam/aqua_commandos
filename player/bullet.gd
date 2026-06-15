# res://player/bullet.gd
class_name Bullet
extends Area2D

@export var speed: float = 600.0

var _direction: Vector2 = Vector2.RIGHT
var _pierce: int = 1


# pierce = 這顆子彈總共能擊中幾個 piece（預設 1）。武器升級後可傳更大值。
func init(direction: Vector2, pierce: int = 1) -> void:
	_direction = direction
	rotation = direction.angle()
	_pierce = pierce


func _ready() -> void:
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)


func _physics_process(_delta: float) -> void:
	position += _direction * speed * _delta


# DressBlock 命中時呼叫：扣一次穿透數，成功回傳 true（該 block 才扣血）。
# 穿透數歸零時自我銷毀。同一幀重疊多個 block 時，靠這方法限制實際觸發數。
func try_consume() -> bool:
	if _pierce <= 0:
		return false
	_pierce -= 1
	if _pierce <= 0:
		queue_free()
	return true
