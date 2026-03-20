## 战斗场景脚本
## 整合战斗UI的场景
extends Control

## 战斗状态（单场战斗的临时状态）
var battle_state: BattleState

## 玩家
var player: Player

## 敌人列表
var enemies: Array[Enemy] = []

## 手牌区域
var card_hand: CardHand

## 目标选择器
var target_selector: TargetSelector

## 能量显示
var energy_display: EnergyDisplay

## 抽牌堆显示
var draw_pile_display: PileDisplay

## 弃牌堆显示
var discard_pile_display: PileDisplay

## 状态标签
var status_label: Label

## 结束回合按钮
var end_turn_button: Button


func _ready() -> void:
	_setup_battle_field()
	_setup_ui()
	_connect_signals()
	_start_battle()


## 设置战斗场地（玩家和敌人）
func _setup_battle_field() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	# 创建玩家（左侧）
	player = Player.new()
	player.position = Vector2(150, screen_size.y / 2 - 60)
	add_child(player)

	# 创建2个敌人（右侧）
	for i in range(2):
		var enemy := Enemy.new()
		add_child(enemy)  # 先添加到场景树，触发 _ready()
		enemy.setup("敌人%d" % (i + 1), 40 + i * 10)  # 再调用 setup
		enemy.position = Vector2(screen_size.x - 250 + i * 120, screen_size.y / 2 - 100)
		enemies.append(enemy)


## 设置UI
func _setup_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	# 创建战斗状态
	battle_state = BattleState.new()

	# 创建目标选择器
	target_selector = TargetSelector.new()
	target_selector.position = Vector2.ZERO
	add_child(target_selector)

	# 创建手牌区域
	card_hand = CardHand.new()
	card_hand.set_battle_state(battle_state)
	card_hand.set_target_selector(target_selector)
	card_hand.set_player(player)
	card_hand.set_enemies(_get_character_array())
	add_child(card_hand)

	# 创建能量显示
	energy_display = EnergyDisplay.new()
	energy_display.set_battle_state(battle_state)
	energy_display.position = Vector2(screen_size.x - 100, screen_size.y - 100)
	add_child(energy_display)

	# 创建抽牌堆显示
	draw_pile_display = PileDisplay.new()
	draw_pile_display.set_battle_state(battle_state)
	draw_pile_display.pile_type = PileDisplay.PileType.DRAW
	draw_pile_display.position = Vector2(50, screen_size.y - 130)
	add_child(draw_pile_display)

	# 创建弃牌堆显示
	discard_pile_display = PileDisplay.new()
	discard_pile_display.set_battle_state(battle_state)
	discard_pile_display.pile_type = PileDisplay.PileType.DISCARD
	discard_pile_display.position = Vector2(screen_size.x - 200, screen_size.y - 130)
	add_child(discard_pile_display)

	# 创建状态标签
	status_label = Label.new()
	status_label.position = Vector2(screen_size.x / 2 - 150, 10)
	status_label.custom_minimum_size = Vector2(300, 30)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "准备开始战斗..."
	add_child(status_label)

	# 创建结束回合按钮
	end_turn_button = Button.new()
	end_turn_button.position = Vector2(screen_size.x - 120, screen_size.y - 180)
	end_turn_button.custom_minimum_size = Vector2(100, 40)
	end_turn_button.text = "结束回合"
	add_child(end_turn_button)


## 连接信号
func _connect_signals() -> void:
	# 卡牌打出到目标
	card_hand.card_played_on_target.connect(_on_card_played_on_target)

	# 结束回合按钮
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# 敌人死亡
	for enemy in enemies:
		enemy.character_died.connect(_on_enemy_died)

	# 玩家死亡
	player.character_died.connect(_on_player_died)


## 获取敌人数组（作为Character类型）
func _get_character_array() -> Array[Character]:
	var result: Array[Character] = []
	for enemy in enemies:
		result.append(enemy)
	return result


## 开始战斗
func _start_battle() -> void:
	status_label.text = "战斗开始！回合 1"

	# 从 GameState 初始化战斗状态
	battle_state.setup_from_deck(GameState.deck)

	# 发送初始信号
	battle_state.energy_changed.emit(battle_state.current_energy, battle_state.max_energy)
	battle_state.piles_changed.emit()

	# 第一回合抽5张牌
	battle_state.draw_cards(5)

	# 让敌人决定意图
	for enemy in enemies:
		enemy.decide_intent()


## 卡牌被打出到目标
func _on_card_played_on_target(card: CardData, target: Character) -> void:
	# 执行卡牌效果
	_execute_card_effect(card, target)
	status_label.text = "打出了 %s" % card.card_name


## 执行卡牌效果
func _execute_card_effect(card: CardData, target: Character) -> void:
	if card.attack_damage > 0 and target:
		target.take_damage(card.attack_damage)
		print("%s 受到 %d 点伤害" % [target.char_name, card.attack_damage])

	if card.block_amount > 0 and player:
		player.gain_block(card.block_amount)
		print("玩家获得 %d 点护甲" % card.block_amount)


## 结束回合
func _on_end_turn_pressed() -> void:
	# 弃掉所有手牌
	battle_state.discard_hand()

	# 玩家护甲重置
	player.reset_block()

	status_label.text = "敌人回合..."

	# 禁用按钮
	end_turn_button.disabled = true

	# 敌人行动
	await _execute_enemy_turn()

	# 开始新回合
	_start_new_turn()


## 执行敌人回合
func _execute_enemy_turn() -> void:
	for enemy in enemies:
		if enemy.is_alive():
			enemy.decide_intent()  # 决定下一个意图
			await enemy.execute_turn(player)
			await get_tree().create_timer(0.3).timeout


## 开始新回合
func _start_new_turn() -> void:
	battle_state.start_turn()
	end_turn_button.disabled = false
	status_label.text = "回合 %d" % battle_state.turn_count


## 敌人死亡
func _on_enemy_died(character: Character) -> void:
	var enemy := character as Enemy
	if enemy:
		enemies.erase(enemy)
		status_label.text = "%s 被击败！" % enemy.char_name

		# 检查是否所有敌人都被击败
		var alive_count := 0
		for e in enemies:
			if e.is_alive():
				alive_count += 1

		if alive_count == 0:
			_on_battle_victory()


## 战斗胜利
func _on_battle_victory() -> void:
	status_label.text = "战斗胜利！"
	end_turn_button.disabled = true

	# 延迟后返回地图
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/map.tscn")


## 玩家死亡
func _on_player_died(_character: Character) -> void:
	status_label.text = "战斗失败..."
	end_turn_button.disabled = true

	# 延迟后返回主菜单
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
