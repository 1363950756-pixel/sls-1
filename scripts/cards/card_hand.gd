## 手牌管理器
## 负责显示和管理玩家当前手中的卡牌
class_name CardHand extends Control

## 卡牌场景
const CARD_SCENE := preload("res://scenes/cards/card.tscn")

## 卡牌之间的间距
@export var card_spacing: float = 20.0

## 卡牌尺寸
const CARD_WIDTH := 140
const CARD_HEIGHT := 200

## 当前显示的卡牌实例
var card_instances: Array[CardBase] = []

## 目标选择器
var target_selector: TargetSelector

## 信号：卡牌被打出到目标
signal card_played_on_target(card: CardData, target: Character)

## 玩家引用（用于需要SELF目标的卡牌）
var player_ref: Character = null

## 敌人列表引用
var enemies_ref: Array[Character] = []


func _ready() -> void:
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.energy_changed.connect(_on_energy_changed)


## 设置目标选择器
func set_target_selector(selector: TargetSelector) -> void:
	target_selector = selector
	if target_selector:
		target_selector.target_selected.connect(_on_target_selected)
		target_selector.drag_cancelled.connect(_on_drag_cancelled)


## 设置敌人列表
func set_enemies(enemies: Array[Character]) -> void:
	enemies_ref = enemies


## 设置玩家引用
func set_player(player: Character) -> void:
	player_ref = player


func _on_hand_changed() -> void:
	_refresh_hand()


func _on_energy_changed(_current: int, _maximum: int) -> void:
	_update_card_playability()


## 刷新手牌显示
func _refresh_hand() -> void:
	# 清除现有卡牌
	for card in card_instances:
		card.queue_free()
	card_instances.clear()

	# 创建新的卡牌实例
	for card_data in GameState.hand:
		var card_instance: CardBase = CARD_SCENE.instantiate()
		add_child(card_instance)
		card_instance.setup_card(card_data)

		# 连接拖拽信号
		card_instance.drag_started.connect(_on_card_drag_started)
		card_instance.dragging.connect(_on_card_dragging)
		card_instance.drag_ended.connect(_on_card_drag_ended)

		card_instances.append(card_instance)

	_update_card_playability()
	_arrange_cards()


## 更新卡牌是否可打出
func _update_card_playability() -> void:
	for card_instance in card_instances:
		if card_instance.card_data:
			card_instance.set_playable(GameState.can_play_card(card_instance.card_data))


## 排列卡牌位置（底部居中）
func _arrange_cards() -> void:
	var count: int = card_instances.size()
	if count == 0:
		return

	# 获取屏幕尺寸
	var screen_size: Vector2 = get_viewport_rect().size
	var card_width: float = 140.0

	# 计算总宽度
	var total_width: float = count * card_width + (count - 1) * card_spacing

	# 起始X位置（居中）
	var start_x: float = (screen_size.x - total_width) / 2.0

	# Y位置（底部，留出卡牌高度的空间）
	var card_y: float = screen_size.y - CARD_HEIGHT - 20.0

	for i in range(count):
		var card: CardBase = card_instances[i]
		var target_x: float = start_x + i * (card_width + card_spacing)

		# 设置位置
		card.global_position = Vector2(target_x, card_y)
		card.set_original_position(Vector2(target_x, card_y))

		# 层级：中间的牌在上
		var center_index: float = (count - 1) / 2.0
		card.z_index = count - int(absf(i - center_index))


## 卡牌开始拖拽
func _on_card_drag_started(card: CardBase) -> void:
	if not target_selector or not card.card_data:
		return

	# 根据卡牌目标类型设置有效目标
	var valid_targets: Array[Character] = []

	match card.card_data.target_type:
		CardData.CardTarget.SINGLE_ENEMY:
			# 需要选择一个敌人
			for enemy in enemies_ref:
				if enemy.is_alive():
					valid_targets.append(enemy)
		CardData.CardTarget.ALL_ENEMIES:
			# 所有敌人（点击任意敌人即可）
			for enemy in enemies_ref:
				if enemy.is_alive():
					valid_targets.append(enemy)
		CardData.CardTarget.SELF:
			# 自身目标，向上拖拽到屏幕上半部分就打出
			# 设置 allow_upper_half = true
			target_selector.set_valid_targets([], true)
			target_selector.start_drag(card, card.global_position + Vector2(70, 100))
			return
		CardData.CardTarget.NONE:
			# 无目标，直接打出
			_try_play_card_on_target(card, player_ref)
			card.return_to_original()
			return

	target_selector.set_valid_targets(valid_targets)
	target_selector.start_drag(card, card.global_position + Vector2(70, 100))


## 卡牌拖拽中
func _on_card_dragging(card: CardBase, position: Vector2) -> void:
	if target_selector:
		target_selector.update_drag(position)


## 卡牌拖拽结束
func _on_card_drag_ended(card: CardBase, position: Vector2) -> void:
	if target_selector:
		target_selector.end_drag()


## 目标被选中
func _on_target_selected(card: CardBase, target: Character) -> void:
	# 如果 target 是 null，使用玩家作为目标（用于 SELF 类型卡牌）
	var actual_target: Character = target if target else player_ref
	_try_play_card_on_target(card, actual_target)


## 拖拽取消
func _on_drag_cancelled(card: CardBase) -> void:
	card.return_to_original()


## 尝试对目标打出卡牌
func _try_play_card_on_target(card: CardBase, target: Character) -> void:
	if not card.card_data:
		return

	if not GameState.can_play_card(card.card_data):
		print("能量不足！")
		card.return_to_original()
		return

	# 打出卡牌
	if GameState.play_card(card.card_data):
		print("打出了 %s 指向 %s" % [card.card_data.card_name, target.char_name if target else "自身"])
		card_played_on_target.emit(card.card_data, target)
