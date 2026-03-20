## 目标选择器
## 管理拖拽卡牌时的目标选择
class_name TargetSelector extends Control

## 当前被拖拽的卡牌
var dragged_card: CardBase = null

## 拖拽起点（卡牌位置）
var drag_start_pos: Vector2 = Vector2.ZERO

## 当前悬停的目标
var hovered_target: Character = null

## 有效目标列表
var valid_targets: Array[Character] = []

## 是否允许屏幕上半区域作为有效目标（用于防御卡）
var allow_upper_half: bool = false

## 箭头绘制
var arrow_line: Line2D

## 信号：目标被选中
signal target_selected(card: CardBase, target: Character)

## 信号：拖拽取消
signal drag_cancelled(card: CardBase)


func _ready() -> void:
	_setup_arrow_line()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_arrow_line() -> void:
	arrow_line = Line2D.new()
	arrow_line.width = 3.0
	arrow_line.default_color = Color.YELLOW
	arrow_line.z_index = 1000
	add_child(arrow_line)
	arrow_line.visible = false


## 开始拖拽
func start_drag(card: CardBase, start_pos: Vector2) -> void:
	dragged_card = card
	drag_start_pos = start_pos
	arrow_line.visible = true
	arrow_line.clear_points()
	arrow_line.add_point(start_pos)


## 更新拖拽位置
func update_drag(current_pos: Vector2) -> void:
	if not dragged_card:
		return

	# 更新箭头
	arrow_line.clear_points()
	arrow_line.add_point(drag_start_pos)
	arrow_line.add_point(current_pos)

	# 检查是否悬停在有效目标上
	_check_hovered_target(current_pos)


## 结束拖拽
func end_drag() -> void:
	if not dragged_card:
		return

	arrow_line.visible = false

	# 如果有悬停的具体目标
	if hovered_target and hovered_target.is_alive():
		target_selected.emit(dragged_card, hovered_target)
	# 如果允许屏幕上半区域，检查是否在上半部分
	elif allow_upper_half:
		var mouse_pos := get_global_mouse_position()
		var screen_height: float = get_viewport_rect().size.y
		if mouse_pos.y < screen_height / 2:
			# 传入 null 表示使用默认目标（玩家自己）
			target_selected.emit(dragged_card, null)
		else:
			drag_cancelled.emit(dragged_card)
	else:
		drag_cancelled.emit(dragged_card)

	dragged_card = null
	hovered_target = null
	allow_upper_half = false


## 检查悬停的目标
func _check_hovered_target(mouse_pos: Vector2) -> void:
	hovered_target = null

	# 先检查是否悬停在具体目标上
	for target in valid_targets:
		if not target.is_alive():
			continue

		# 直接用 global_position + 固定尺寸计算碰撞区域
		var target_rect := Rect2(target.global_position, Vector2(100, 130))
		if target_rect.has_point(mouse_pos):
			hovered_target = target
			# 高亮箭头
			arrow_line.default_color = Color.GREEN
			return

	# 如果允许屏幕上半区域，检查鼠标是否在上半部分
	if allow_upper_half:
		var screen_height: float = get_viewport_rect().size.y
		if mouse_pos.y < screen_height / 2:
			arrow_line.default_color = Color.GREEN
			return

	# 没有悬停目标，恢复默认颜色
	arrow_line.default_color = Color.YELLOW


## 设置有效目标
func set_valid_targets(targets: Array[Character], allow_upper: bool = false) -> void:
	valid_targets = targets
	allow_upper_half = allow_upper


## 清除有效目标
func clear_valid_targets() -> void:
	valid_targets.clear()


## 取消拖拽
func cancel_drag() -> void:
	if dragged_card:
		arrow_line.visible = false
		drag_cancelled.emit(dragged_card)
		dragged_card = null
		hovered_target = null
