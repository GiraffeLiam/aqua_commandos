# res://player/weapon.gd
class_name Weapon
extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2
@export var bullet_pierce: int = 1

@onready var bullet_root: Node2D = $BulletRoot

# 父節點 Player 的引用，_ready 時取得
var _player: Player
var _fire_timer: float = 0.0

func _ready() -> void:
	_player = get_parent() as Player
	if not _player:
		push_error("Weapon: 父節點不是 Player，請確認場景結構")


func _process(_delta: float) -> void:
	rotation = _player.aim_direction.angle()
	_fire_timer -= _delta
	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0:
		_fire_timer = fire_rate
		_spawn_bullet()

func _spawn_bullet() -> void:
	if not bullet_scene:
		push_error("Weapon: bullet_scene 未設定，請在 Inspector 拖入 bullet.tscn")
		return
	var bullet := bullet_scene.instantiate() as Bullet
	bullet.global_position = get_bullet_spawn_point()
	bullet.init(_player.aim_direction, bullet_pierce)
	# 掛到場景根節點，不跟著 Player 旋轉
	get_tree().current_scene.add_child(bullet)

# 供 Bullet 生成時取得槍口世界座標
func get_bullet_spawn_point() -> Vector2:
	return bullet_root.global_position
