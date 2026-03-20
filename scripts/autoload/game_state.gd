## 全局游戏状态（宏观/战役状态）
## 管理跨战斗的持久数据：玩家牌组、血量、层数、遗物等
## 需要在 项目设置 -> Autoload 中添加为单例
@warning_ignore("unused_signal")
extends Node

#region 信号
## 玩家血量变化信号
signal player_health_changed(current: int, maximum: int)

## 战斗失败信号
signal battle_defeat()
#endregion

#region 玩家基础属性
## 玩家名称
var player_name: String = "铁甲战士"

## 最大血量
var max_hp: int = 80

## 当前血量
var current_hp: int = 80

## 金币
var gold: int = 100
#endregion

#region 牌组
## 玩家牌组（所有拥有的卡牌）
var deck: Array[CardData] = []
#endregion

#region 进度
## 当前层数
var current_floor: int = 0

## 遗物列表
var relics: Array = []

## 当前地图（二维数组）
var current_map: Array[Array] = []

## 当前所在节点
var current_node: MapNode = null
#endregion


func _ready() -> void:
	# 初始化一个基础牌组（测试用）
	_init_starter_deck()


## 初始化初始牌组（5张打击，4张防御，1张痛击）
func _init_starter_deck() -> void:
	var strike = preload("res://resources/cards/strike.tres")
	var defend = preload("res://resources/cards/defend.tres")
	var bash = preload("res://resources/cards/bash.tres")

	deck.clear()
	# 5张打击
	for i in range(5):
		deck.append(strike.duplicate())
	# 4张防御
	for i in range(4):
		deck.append(defend.duplicate())
	# 1张痛击
	deck.append(bash.duplicate())


## 玩家受到伤害
func player_take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	player_health_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		battle_defeat.emit()


## 玩家治疗
func player_heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	player_health_changed.emit(current_hp, max_hp)


## 重置玩家状态（新游戏）
func reset_player() -> void:
	current_hp = max_hp
	current_floor = 0
	gold = 100
	relics.clear()
	current_map.clear()
	current_node = null
	_init_starter_deck()
