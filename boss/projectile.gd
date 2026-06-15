# res://boss/projectile.gd
# Projectile — Boss 的攻擊投射物。發射瞬間鎖定方向後直線飛行，不追蹤玩家。
# 與 Player 的 Bullet 分開：Bullet 打 Dress（layer 2 → 找 dress），
# Projectile 打 Player（layer 4 → 找 player）。
class_name Projectile
extends Area2D

@export var speed: float = 300.0

var _direction: Vector2 = Vector2.DOWN


func init(direction: Vector2) -> void:
	_direction = direction
	rotation = direction.angle()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)


func _physics_process(_delta: float) -> void:
	# 方向在 init() 鎖定，這裡永遠用同一個 _direction、不重算 → 不追蹤
	position += _direction * speed * _delta


func _on_area_entered(_area: Area2D) -> void:
	# mask 已限定 player 層，碰到＝命中玩家 HurtBox
	queue_free()
