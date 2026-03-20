## 战斗状态管理器
## 管理单场战斗的临时状态（牌堆、能量、回合）
class_name BattleState extends RefCounted

#region 信号
## 能量变化信号
signal energy_changed(current: int, maximum: int)

## 手牌变化信号
signal hand_changed()

## 牌堆变化信号（抽牌堆/弃牌堆）
signal piles_changed()
#endregion

#region 牌堆
## 抽牌堆
var draw_pile: Array[CardData] = []

## 当前手牌
var hand: Array[CardData] = []

## 弃牌堆
var discard_pile: Array[CardData] = []

## 消耗牌堆（被移除的牌，本战斗不再出现）
var exhaust_pile: Array[CardData] = []
#endregion

#region 能量
## 当前能量
var current_energy: int = 3

## 最大能量
var max_energy: int = 3
#endregion

#region 回合
## 回合数
var turn_count: int = 0
#endregion


## 从玩家牌组初始化战斗
func setup_from_deck(player_deck: Array[CardData]) -> void:
	# 重置状态
	turn_count = 0
	current_energy = max_energy

	# 清空牌堆
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	# 复制牌组到抽牌堆
	for card in player_deck:
		draw_pile.append(card.duplicate())

	# 洗牌
	shuffle_draw_pile()


## 洗抽牌堆
func shuffle_draw_pile() -> void:
	draw_pile.shuffle()


## 从弃牌堆洗回抽牌堆
func reshuffle_discard_pile() -> void:
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	shuffle_draw_pile()
	piles_changed.emit()


## 抽牌
func draw_cards(count: int) -> void:
	for i in range(count):
		# 抽牌堆空了，从弃牌堆洗回
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break  # 没牌可抽了
			reshuffle_discard_pile()

		if not draw_pile.is_empty():
			var card: CardData = draw_pile.pop_back()
			hand.append(card)

	hand_changed.emit()
	piles_changed.emit()


## 打出卡牌
func play_card(card: CardData) -> bool:
	# 检查能量是否足够
	if current_energy < card.cost:
		print("能量不足！需要 %d，当前 %d" % [card.cost, current_energy])
		return false

	# 消耗能量
	current_energy -= card.cost
	energy_changed.emit(current_energy, max_energy)

	# 从手牌移到弃牌堆
	hand.erase(card)
	discard_pile.append(card)

	hand_changed.emit()
	piles_changed.emit()

	return true


## 弃掉所有手牌
func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()

	hand_changed.emit()
	piles_changed.emit()


## 开始新回合
func start_turn() -> void:
	turn_count += 1

	# 重置能量
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)

	# 抽5张牌
	draw_cards(5)


## 检查是否有足够能量打出卡牌
func can_play_card(card: CardData) -> bool:
	return current_energy >= card.cost


## 获取抽牌堆数量
func get_draw_pile_count() -> int:
	return draw_pile.size()


## 获取弃牌堆数量
func get_discard_pile_count() -> int:
	return discard_pile.size()


## 获取手牌数量
func get_hand_count() -> int:
	return hand.size()
