# res://player/invincibility.gd
# Invincibility — 掛在角色上的無敵元件（外掛式）。
# 自管 i-frame 計時與閃爍，不碰角色的移動/輸入；FSM 換 sprite 也不受影響。
# blink_target 指向要閃爍的視覺節點（現為 Sprite2D；FSM 接手後重指到視覺容器即可）。
class_name Invincibility
extends Node2D

@export var blink_target: CanvasItem
@export var invincible_time: float = 0.8
@export var blink_interval: float = 0.08

@onready var _orb: ShieldOrb = $ShieldOrb

var _active: bool = false
var _timer: float = 0.0
var _blink_timer: float = 0.0


func is_active() -> bool:
	return _active


func start() -> void:
	_active = true
	_timer = invincible_time
	_blink_timer = 0.0
	if _orb:
		_orb.visible = true


func _process(_delta: float) -> void:
	if not _active:
		return
	_timer -= _delta
	if _timer <= 0.0:
		_end()
		return
	_blink_timer -= _delta
	if _blink_timer <= 0.0:
		_blink_timer = blink_interval
		if blink_target:
			blink_target.modulate.a = 0.3 if blink_target.modulate.a > 0.5 else 1.0


func _end() -> void:
	_active = false
	if blink_target:
		blink_target.modulate.a = 1.0
	if _orb:
		_orb.visible = false
