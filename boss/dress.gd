# res://boss/dress/dress.gd
class_name Dress
extends Node2D

@export var dress_texture: Texture2D
@export var columns: int = 5
@export var rows: int = 6

const ALPHA_THRESHOLD: int = 10

var _alive_count: int = 0
var _total_count: int = 0


func _ready() -> void:
	if not dress_texture:
		push_error("Dress: dress_texture 未設定")
		return
	_build_blocks()


func _build_blocks() -> void:
	var image: Image = dress_texture.get_image()
	image.convert(Image.FORMAT_RGBA8)

	var tex_width: float = dress_texture.get_width()
	var tex_height: float = dress_texture.get_height()
	var block_w: float = tex_width / float(columns)
	var block_h: float = tex_height / float(rows)
	var block_size := Vector2(block_w, block_h)

	var origin := Vector2(
		-tex_width / 2.0 + block_w / 2.0,
		-tex_height / 2.0 + block_h / 2.0
	)

	for row in range(rows):
		for col in range(columns):
			var region := Rect2(
				col * block_w,
				row * block_h,
				block_w,
				block_h
			)

			if _is_region_transparent(image, region):
				continue

			var block := DressBlock.new()
			add_child(block)

			block.position = origin + Vector2(col * block_w, row * block_h)

			block.collision_layer = 16
			block.collision_mask = 2
			block.monitoring = true
			block.monitorable = true

			block.init(dress_texture, region, block_size, _on_block_destroyed)

			_alive_count += 1

	_total_count = _alive_count
	print("DressBlock 生成數量：", _total_count)

func _is_region_transparent(image: Image, region: Rect2) -> bool:
	var sample_step: int = 4
	var total: int = 0
	var count: int = 0

	var x_start: int = int(region.position.x)
	var y_start: int = int(region.position.y)
	var x_end: int = int(region.position.x + region.size.x)
	var y_end: int = int(region.position.y + region.size.y)

	for y in range(y_start, y_end, sample_step):
		for x in range(x_start, x_end, sample_step):
			var pixel: Color = image.get_pixel(x, y)
			total += int(pixel.a * 255)
			count += 1

	if count == 0:
		return true

	return (total / count) < ALPHA_THRESHOLD

func _on_block_destroyed(_block: DressBlock) -> void:
	_alive_count -= 1
	event_bus.dress_progress_changed.emit(get_alive_pct())

	if _alive_count <= 0:
		print("dress_phase_cleared emitted")
		event_bus.dress_phase_cleared.emit()

func get_alive_pct() -> float:
	if _total_count <= 0:
		return 0.0
	return float(_alive_count) / float(_total_count)
