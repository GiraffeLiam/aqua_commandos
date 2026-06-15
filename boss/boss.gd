# res://boss/boss.gd
# Boss — Boss 實體根節點。身體 Sprite ＋ 外層 Dress 的容器。
# 多階段時這裡會掛多套 Dress（一層一個 phase），每階段只開放當前層可攻擊。
# 目前為驗證用的「笨發射」：定時朝玩家當下位置射一發 Projectile，發射瞬間鎖定角度。
# 階段 3 會把發射收進狀態機（移動、Projectile、衝撞）。
class_name Boss
extends Node2D

@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.5

var _fire_timer: float = 0.0


func _process(_delta: float) -> void:
	_fire_timer -= _delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_rate
		_fire_at_player()


func _fire_at_player() -> void:
	if not projectile_scene:
		push_error("Boss: projectile_scene 未設定，請在 Inspector 拖入 projectile.tscn")
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return

	# 發射瞬間瞄準玩家當下位置，算一次方向就鎖定（不追蹤）
	var direction: Vector2 = (player.global_position - global_position).normalized()

	var projectile := projectile_scene.instantiate() as Projectile
	projectile.global_position = global_position
	projectile.init(direction)
	get_tree().current_scene.add_child(projectile)
