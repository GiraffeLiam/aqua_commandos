# res://boss/projectile.gd
# Projectile — Boss 的攻擊投射物。發射瞬間鎖定方向後直線飛行，不追蹤玩家。
# 與 Player 的 Bullet 分開：Bullet 打 Dress（layer 2 → 找 dress），
# Projectile 打 Player（layer 4 → 找 player）。
#
# ── 未來投射物行為擴展點（目前只有直線；改這裡不波及釋放點 / 調度 state）──
#   移動鉤子：見 _physics_process 內標註。追蹤(2.3)、撞點轉向(3.2) 在此覆寫。
#   死亡鉤子：見 _on_area_entered / 出畫面。自毀環狀散射(3.1) 在此掛「死前生一圈」。
#   做法皆為「新增行為、不改既有直線」，故底層無需修改即可擴展。
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
	# ── 移動鉤子 ── 目前寫死直線；未來抽成 _apply_movement(delta) 由行為覆寫
	# 方向在 init() 鎖定，這裡永遠用同一個 _direction、不重算 → 不追蹤
	position += _direction * speed * _delta


func _on_area_entered(_area: Area2D) -> void:
	# ── 死亡鉤子 ── mask 已限定 player 層，碰到＝命中玩家 HurtBox
	# 未來自毀散射：在 queue_free 前先生一圈新 projectile
	queue_free()
