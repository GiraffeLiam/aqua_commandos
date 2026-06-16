# res://player/player.gd
class_name Player
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var max_hp: int = 3
@export var hit_shake_time: float = 0.3
@export var hit_shake_strength: float = 8.0
@export var boss_push_strength: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var _invincibility: Invincibility = $Invincibility

# 瞄準方向快取，供 Weapon 讀取
var aim_direction: Vector2 = Vector2.RIGHT

var _hp: int = 0

const _BOSS_LAYER: int = 7  # 物理層 7 = boss


func _ready() -> void:
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	_hp = max_hp
	# 延後一幀廣播初始血量，確保 HUD 已連上信號
	_broadcast_health.call_deferred()


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * move_speed
	move_and_slide()
	_resolve_boss_contact()
	_update_aim_direction()


func _update_aim_direction() -> void:
	# 滑鼠方向（相對於 Player 世界座標）
	var mouse_dir := get_global_mouse_position() - global_position
	if mouse_dir.length() > 1.0:
		aim_direction = mouse_dir.normalized()


# 撞到 Boss 時沿碰撞法線輕推離開（撞不進去由 collision_mask 擋；這裡只給「推開感」）
func _resolve_boss_contact() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CollisionObject2D and (collider as CollisionObject2D).get_collision_layer_value(_BOSS_LAYER):
			global_position += collision.get_normal() * boss_push_strength * get_physics_process_delta_time()
			return


func take_damage(amount: int) -> void:
	# 無敵中或已死就不處理
	if _invincibility.is_active() or _hp <= 0:
		return
	_hp = max(_hp - amount, 0)
	event_bus.player_health_changed.emit(_hp, max_hp)
	if _hp <= 0:
		event_bus.player_died.emit()
		return
	# 還活著：開無敵（閃爍 + 圓球）＋ 螢幕晃動
	_invincibility.start()
	event_bus.screen_shake_requested.emit(hit_shake_time, hit_shake_strength)


func _broadcast_health() -> void:
	event_bus.player_health_changed.emit(_hp, max_hp)


# ── HurtBox 碰撞：被 Projectile 命中就扣血 ────────────────────
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area is Projectile:
		take_damage(1)
