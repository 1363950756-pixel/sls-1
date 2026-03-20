## 卡牌UI基类
## 负责卡牌的视觉显示和用户交互
class_name CardBase extends Control

## 信号：开始拖拽
signal drag_started(card: CardBase)

## 信号：拖拽中
signal dragging(card: CardBase, position: Vector2)

## 信号：拖拽结束
signal drag_ended(card: CardBase, position: Vector2)

## 信号：卡牌被点击
signal card_clicked(card: CardBase)

## 信号：鼠标悬停在卡牌上
signal card_hovered(card: CardBase)

## 信号：鼠标离开卡牌
signal card_unhovered(card: CardBase)

## 卡牌数据
@export var card_data: CardData

## 卡牌是否可打出
var is_playable: bool = true

## 卡牌是否被选中
var is_selected: bool = false

## 卡牌尺寸常量
const CARD_WIDTH := 140
const CARD_HEIGHT := 200

## UI组件引用
var background: ColorRect
var cost_label: Label
var name_label: Label
var desc_label: Label
var type_label: Label

## 悬停时的缩放
var _target_scale: Vector2 = Vector2.ONE

## 是否正在拖拽
var _is_dragging: bool = false

## 拖拽起始位置
var _drag_offset: Vector2 = Vector2.ZERO

## 原始位置（用于返回）
var _original_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_setup_ui()
	if card_data:
		setup_card(card_data)


## 创建UI组件
func _setup_ui() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.3)
	background.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _create_rounded_stylebox())
	add_child(background)

	cost_label = Label.new()
	cost_label.position = Vector2(8, 8)
	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	cost_label.text = "1"
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(cost_label)

	name_label = Label.new()
	name_label.position = Vector2(35, 8)
	name_label.custom_minimum_size = Vector2(CARD_WIDTH - 45, 30)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.text = "卡牌名称"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(name_label)

	type_label = Label.new()
	type_label.position = Vector2(10, 40)
	type_label.custom_minimum_size = Vector2(CARD_WIDTH - 20, 20)
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	type_label.text = "攻击"
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(type_label)

	desc_label = Label.new()
	desc_label.position = Vector2(10, 100)
	desc_label.custom_minimum_size = Vector2(CARD_WIDTH - 20, 90)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.text = "描述文本"
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(desc_label)


func _create_rounded_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func setup_card(data: CardData) -> void:
	card_data = data
	name_label.text = data.card_name
	cost_label.text = str(data.cost)
	desc_label.text = data.get_formatted_description()
	type_label.text = _get_type_text(data.card_type)
	_update_card_color()


func _get_type_text(card_type: CardData.CardType) -> String:
	match card_type:
		CardData.CardType.ATTACK:
			return "攻击"
		CardData.CardType.SKILL:
			return "技能"
		CardData.CardType.CURSE:
			return "诅咒"
		_:
			return "未知"


func _update_card_color() -> void:
	if not card_data:
		return

	var bg_color: Color
	match card_data.card_type:
		CardData.CardType.ATTACK:
			bg_color = Color(0.6, 0.2, 0.2)
		CardData.CardType.SKILL:
			bg_color = Color(0.2, 0.4, 0.6)
		CardData.CardType.CURSE:
			bg_color = Color(0.3, 0.2, 0.4)
		_:
			bg_color = card_data.card_color

	var style := _create_rounded_stylebox()
	style.bg_color = bg_color
	background.add_theme_stylebox_override("panel", style)


func set_playable(playable: bool) -> void:
	is_playable = playable
	modulate.a = 1.0 if playable else 0.5


func _on_mouse_entered() -> void:
	if not _is_dragging:
		card_hovered.emit(self)
		_target_scale = Vector2(1.1, 1.1)


func _on_mouse_exited() -> void:
	if not _is_dragging:
		card_unhovered.emit(self)
		_target_scale = Vector2.ONE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				_start_drag(get_global_mouse_position())
				accept_event()
			else:
				# 结束拖拽
				if _is_dragging:
					_end_drag(get_global_mouse_position())
					accept_event()


func _input(event: InputEvent) -> void:
	if _is_dragging and event is InputEventMouseMotion:
		_update_drag(get_global_mouse_position())


## 开始拖拽
func _start_drag(mouse_pos: Vector2) -> void:
	if not is_playable:
		return

	_is_dragging = true
	_original_position = global_position
	_drag_offset = global_position - mouse_pos
	z_index = 100  # 提升层级
	drag_started.emit(self)

	# 视觉反馈
	_target_scale = Vector2(1.2, 1.2)
	modulate = Color(1, 1, 1, 0.8)


## 更新拖拽
func _update_drag(mouse_pos: Vector2) -> void:
	global_position = mouse_pos + _drag_offset
	# 传递鼠标位置，而不是卡牌位置
	dragging.emit(self, mouse_pos)


## 结束拖拽
func _end_drag(mouse_pos: Vector2) -> void:
	_is_dragging = false
	z_index = 0
	# 传递鼠标位置
	drag_ended.emit(self, mouse_pos)

	# 恢复视觉
	_target_scale = Vector2.ONE
	modulate = Color.WHITE


## 返回原始位置
func return_to_original() -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", _original_position, 0.2)
	_target_scale = Vector2.ONE


## 设置原始位置
func set_original_position(pos: Vector2) -> void:
	_original_position = pos
	global_position = pos


func _process(delta: float) -> void:
	scale = scale.lerp(_target_scale, 10.0 * delta)
