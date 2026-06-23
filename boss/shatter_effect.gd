# res://boss/shatter_effect.gd
# ShatterEffect — DressBlock 被擊破時的一次性粒子爆裂。
# 粒子貼圖 = 被擊破那塊的 AtlasTexture(region)，碎屑即該塊禮裝的真實碎片，免美術資源。
# 生在世界座標、放完自刪；掛在 boss 場景的 Effects 容器下（不隨 boss 移動）。
class_name ShatterEffect
extends CPUParticles2D

@export var fragment_amount: int = 8
@export var lifetime_seconds: float = 0.5
@export var initial_speed_min: float = 80.0
@export var initial_speed_max: float = 160.0
@export var spread_degrees: float = 180.0
@export var gravity_strength: float = 400.0


# texture：dress 大圖；region：被擊破那塊的矩形。包成 AtlasTexture 當粒子素材。
func setup(texture: Texture2D, region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	self.texture = atlas

	one_shot = true
	explosiveness = 1.0  # 同一瞬間全部噴出，而非隨時間陸續發射
	amount = fragment_amount
	lifetime = lifetime_seconds

	direction = Vector2.UP
	spread = spread_degrees
	initial_velocity_min = initial_speed_min
	initial_velocity_max = initial_speed_max
	gravity = Vector2(0.0, gravity_strength)

	# 碎片邊飛邊縮小淡出
	scale_amount_min = 0.6
	scale_amount_max = 1.0
	var fade := Curve.new()
	fade.add_point(Vector2(0.0, 1.0))
	fade.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = fade

	emitting = true
	# 放完自刪（多給一點緩衝確保最後一顆粒子也消失）
	get_tree().create_timer(lifetime_seconds + 0.2).timeout.connect(queue_free)
