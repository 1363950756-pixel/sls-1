## 牌堆显示UI
## 显示抽牌堆和弃牌堆的数量，点击可查看详情
class_name PileDisplay extends Control

## 牌堆类型
enum PileType { DRAW, DISCARD }

@export var pile_type: PileType = PileType.DRAW

## 战斗状态
var battle_state: BattleState

## 背景和标签
var background: ColorRect
var count_label: Label
var name_label: Label

## 弹窗相关
var popup_panel: Panel
var popup_vbox: VBoxContainer
var is_popup_visible: bool = false


func _ready() -> void:
	_setup_ui()
	_setup_popup()
	# 如果 battle_state 已设置，更新显示
	if battle_state:
		_update_display()


## 设置战斗状态
func set_battle_state(state: BattleState) -> void:
	battle_state = state
	if battle_state:
		battle_state.piles_changed.connect(_on_piles_changed)
		# 初始化显示
		_update_display()


func _setup_ui() -> void:
	custom_minimum_size = Vector2(80, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 背景
	background = ColorRect.new()
	background.custom_minimum_size = Vector2(80, 100)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	if pile_type == PileType.DRAW:
		style.bg_color = Color(0.2, 0.3, 0.2)
		style.border_color = Color(0.3, 0.5, 0.3)
	else:
		style.bg_color = Color(0.3, 0.2, 0.2)
		style.border_color = Color(0.5, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	background.add_theme_stylebox_override("panel", style)

	add_child(background)

	# 牌堆名称
	name_label = Label.new()
	name_label.position = Vector2(0, 5)
	name_label.custom_minimum_size = Vector2(80, 20)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = "抽牌堆" if pile_type == PileType.DRAW else "弃牌堆"
	background.add_child(name_label)

	# 数量标签
	count_label = Label.new()
	count_label.position = Vector2(0, 40)
	count_label.custom_minimum_size = Vector2(80, 40)
	count_label.add_theme_font_size_override("font_size", 28)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "0"
	background.add_child(count_label)

	# 提示标签
	var hint_label := Label.new()
	hint_label.position = Vector2(0, 82)
	hint_label.custom_minimum_size = Vector2(80, 15)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "点击查看"
	background.add_child(hint_label)


func _setup_popup() -> void:
	# 创建弹窗面板
	popup_panel = Panel.new()
	popup_panel.visible = false
	popup_panel.z_index = 100

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	panel_style.border_color = Color(0.5, 0.5, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	popup_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(popup_panel)

	# 创建垂直容器
	popup_vbox = VBoxContainer.new()
	popup_vbox.position = Vector2(10, 10)
	popup_panel.add_child(popup_vbox)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle_popup()
			accept_event()


func _input(event: InputEvent) -> void:
	# 点击其他地方关闭弹窗
	if is_popup_visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var popup_rect := Rect2(popup_panel.global_position, popup_panel.size)
			if not popup_rect.has_point(get_global_mouse_position()):
				_hide_popup()


func _toggle_popup() -> void:
	if is_popup_visible:
		_hide_popup()
	else:
		_show_popup()


func _show_popup() -> void:
	is_popup_visible = true
	_refresh_popup_content()
	popup_panel.visible = true

	# 定位弹窗
	if pile_type == PileType.DRAW:
		popup_panel.position = Vector2(90, 0)
	else:
		popup_panel.position = Vector2(-220, 0)


func _hide_popup() -> void:
	is_popup_visible = false
	popup_panel.visible = false


func _refresh_popup_content() -> void:
	if not battle_state:
		return

	# 清除现有内容
	for child in popup_vbox.get_children():
		child.queue_free()

	# 获取牌列表
	var cards: Array
	if pile_type == PileType.DRAW:
		cards = battle_state.draw_pile
	else:
		cards = battle_state.discard_pile

	# 标题
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.text = "抽牌堆 (%d)" % cards.size() if pile_type == PileType.DRAW else "弃牌堆 (%d)" % cards.size()
	popup_vbox.add_child(title)

	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(空)"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		popup_vbox.add_child(empty_label)
	else:
		# 统计卡牌
		var card_counts: Dictionary = {}
		for card in cards:
			var card_data: CardData = card as CardData
			if card_data:
				var key := card_data.card_name
				if card_counts.has(key):
					card_counts[key] += 1
				else:
					card_counts[key] = 1

		# 显示卡牌列表
		for card_name: String in card_counts:
			var card_label := Label.new()
			card_label.add_theme_font_size_override("font_size", 12)
			card_label.add_theme_color_override("font_color", Color.WHITE)
			var count: int = card_counts[card_name]
			if count > 1:
				card_label.text = "%s x%d" % [card_name, count]
			else:
				card_label.text = card_name
			popup_vbox.add_child(card_label)

	# 调整弹窗大小
	popup_panel.custom_minimum_size = Vector2(200, 0)
	popup_panel.size = Vector2.ZERO  # 重置大小让其自动调整


func _on_piles_changed() -> void:
	_update_display()
	if is_popup_visible:
		_refresh_popup_content()


func _update_display() -> void:
	if not battle_state or not count_label:
		return

	var count: int
	if pile_type == PileType.DRAW:
		count = battle_state.get_draw_pile_count()
	else:
		count = battle_state.get_discard_pile_count()

	count_label.text = str(count)
