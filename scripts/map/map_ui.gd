## 地图场景UI
## 显示地图节点，处理节点选择
extends Control

## 节点按钮场景（用于显示单个节点）
const NODE_SIZE := 60
const NODE_SPACING_X := 100
const NODE_SPACING_Y := 80

## 当前地图数据
var map_data: Array[Array] = []

## 当前所在节点
var current_node: MapNode = null

## 节点UI引用（用于更新显示）
var node_buttons: Array[Button] = []

## 玩家信息显示
var player_info_label: Label

## 楼层信息显示
var floor_label: Label


func _ready() -> void:
	_setup_ui()
	_init_map()


func _setup_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	# 背景
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.08)
	background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background)

	# 楼层信息
	floor_label = Label.new()
	floor_label.position = Vector2(10, 10)
	floor_label.custom_minimum_size = Vector2(200, 30)
	floor_label.add_theme_font_size_override("font_size", 18)
	floor_label.add_theme_color_override("font_color", Color.YELLOW)
	floor_label.text = "第 %d 层" % GameState.current_floor
	add_child(floor_label)

	# 玩家信息
	player_info_label = Label.new()
	player_info_label.position = Vector2(10, 45)
	player_info_label.custom_minimum_size = Vector2(200, 60)
	player_info_label.add_theme_font_size_override("font_size", 14)
	player_info_label.add_theme_color_override("font_color", Color.WHITE)
	player_info_label.text = "HP: %d/%d\n金币: %d" % [GameState.current_hp, GameState.max_hp, GameState.gold]
	add_child(player_info_label)


func _init_map() -> void:
	# 如果没有地图数据，生成新地图
	if map_data.is_empty():
		map_data = MapGenerator.generate_map()
		GameState.current_map = map_data
	else:
		map_data = GameState.current_map

	# 如果没有当前位置，设置在起始位置
	if current_node == null and not map_data.is_empty():
		# 找到第一个可访问的节点（通常是第一行的中间节点）
		for node in map_data[0]:
			if node.is_accessible:
				current_node = node
				break
		# 如果没有可访问的节点，选择第一个节点
		if current_node == null and not map_data[0].is_empty():
			current_node = map_data[0][0]
			current_node.is_accessible = true

	_draw_map()


## 绘制地图
func _draw_map() -> void:
	# 清除旧节点
	for btn in node_buttons:
		btn.queue_free()
	node_buttons.clear()

	var screen_size: Vector2 = get_viewport_rect().size

	# 计算地图显示区域
	var start_x: float = screen_size.x / 2 - (3 * NODE_SPACING_X) / 2
	var start_y: float = screen_size.y - 150  # 从底部开始

	# 从下往上绘制（row 0 在底部）
	for row_idx in range(map_data.size()):
		var row: Array = map_data[row_idx]
		var row_size: int = row.size()

		for col_idx in range(row_size):
			var node: MapNode = row[col_idx]
			var btn := _create_node_button(node, row_size, col_idx, row_idx, start_x, start_y)
			add_child(btn)
			node_buttons.append(btn)

	# 绘制连接线
	_draw_connections(start_x, start_y)


## 创建节点按钮
func _create_node_button(node: MapNode, row_size: int, col: int, row: int, start_x: float, start_y: float) -> Button:
	var btn := Button.new()

	# 计算位置
	var row_width: float = (row_size - 1) * NODE_SPACING_X
	var x: float = start_x + (col * NODE_SPACING_X) - row_width / 2 + NODE_SIZE / 2
	var y: float = start_y - (row * NODE_SPACING_Y)

	btn.position = Vector2(x - NODE_SIZE / 2, y - NODE_SIZE / 2)
	btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)

	# 设置文字
	btn.text = node.get_type_name()
	btn.add_theme_font_size_override("font_size", 10)

	# 根据状态设置样式
	var style := StyleBoxFlat.new()
	style.bg_color = node.get_type_color()
	style.set_corner_radius_all(8)

	if node.is_completed:
		style.bg_color = Color(0.3, 0.3, 0.3)
		style.border_color = Color(0.5, 0.5, 0.5)
		btn.disabled = true
	elif node.is_accessible:
		style.border_color = Color.YELLOW
		style.set_border_width_all(3)
	else:
		style.bg_color = Color(0.2, 0.2, 0.2)
		btn.disabled = true

	# 当前位置标记
	if node == current_node:
		style.border_color = Color.GREEN
		style.set_border_width_all(4)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("disabled", style)

	# 连接点击事件
	if node.is_accessible and not node.is_completed:
		btn.pressed.connect(_on_node_pressed.bind(node))

	return btn


## 绘制节点连接线
func _draw_connections(start_x: float, start_y: float) -> void:
	# 使用 Line2D 绘制连接线
	for row_idx in range(map_data.size()):
		var row: Array = map_data[row_idx]
		for node in row:
			for next_node in node.connections_next:
				var line := Line2D.new()
				line.width = 2.0

				# 计算位置
				var row_width: float = (row.size() - 1) * NODE_SPACING_X
				var x1: float = start_x + (node.column * NODE_SPACING_X) - row_width / 2
				var y1: float = start_y - (node.row * NODE_SPACING_Y)

				var next_row_width: float = (map_data[next_node.row].size() - 1) * NODE_SPACING_X
				var x2: float = start_x + (next_node.column * NODE_SPACING_X) - next_row_width / 2
				var y2: float = start_y - (next_node.row * NODE_SPACING_Y)

				line.add_point(Vector2(x1, y1))
				line.add_point(Vector2(x2, y2))

				# 已完成的路径显示为灰色，可访问的显示为黄色
				if node.is_completed:
					line.default_color = Color(0.4, 0.4, 0.4)
				elif next_node.is_accessible:
					line.default_color = Color(0.6, 0.5, 0.2)
				else:
					line.default_color = Color(0.3, 0.3, 0.3)

				add_child(line)


## 节点被点击
func _on_node_pressed(node: MapNode) -> void:
	current_node = node
	GameState.current_node = node

	# 进入对应场景
	_enter_node(node)


## 进入节点
func _enter_node(node: MapNode) -> void:
	match node.node_type:
		MapNode.NodeType.BATTLE, MapNode.NodeType.ELITE, MapNode.NodeType.BOSS:
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
		MapNode.NodeType.SHOP:
			# TODO: 商店场景
			print("进入商店（未实现）")
		MapNode.NodeType.REST:
			# 休息点：恢复30%血量
			var heal_amount := int(GameState.max_hp * 0.3)
			GameState.player_heal(heal_amount)
			print("在休息点恢复了 %d 点血量" % heal_amount)
			# 标记完成并更新地图
			node.is_completed = true
			MapGenerator.update_accessible_nodes(map_data, node)
			# 重新绘制
			_draw_map()
		_:
			# 未知类型，当作普通战斗
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
