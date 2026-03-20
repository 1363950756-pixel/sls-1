## 敌人类
## 继承自Character，添加敌人特有的AI和意图系统
class_name Enemy extends Character

#region 信号
## 敌人行动完成信号
signal action_completed()
#endregion

## 敌人意图类型
enum IntentType { ATTACK, DEFEND, BUFF, UNKNOWN }

## 当前意图
var current_intent: IntentType = IntentType.ATTACK

## 意图数值（攻击伤害或护甲值）
var intent_value: int = 0

## UI组件
var intent_label: Label


func _ready() -> void:
	super._ready()
	_setup_intent_display()


## 设置意图显示
func _setup_intent_display() -> void:
	intent_label = Label.new()
	intent_label.position = Vector2(5, 105)
	intent_label.custom_minimum_size = Vector2(90, 20)
	intent_label.add_theme_font_size_override("font_size", 12)
	intent_label.add_theme_color_override("font_outline_color", Color.BLACK)
	intent_label.add_theme_constant_override("outline_size", 2)
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_rect.add_child(intent_label)


## 决定下一个意图
func decide_intent() -> void:
	# 简单AI：随机选择攻击或防御
	var roll := randf()
	if roll < 0.7:
		current_intent = IntentType.ATTACK
		intent_value = randi_range(5, 12)
	else:
		current_intent = IntentType.DEFEND
		intent_value = randi_range(4, 8)

	_update_intent_display()


## 更新意图显示
func _update_intent_display() -> void:
	if not intent_label:
		return

	match current_intent:
		IntentType.ATTACK:
			intent_label.text = "意图: 攻击 %d" % intent_value
			intent_label.add_theme_color_override("font_color", Color.RED)
		IntentType.DEFEND:
			intent_label.text = "意图: 防御 %d" % intent_value
			intent_label.add_theme_color_override("font_color", Color.CYAN)
		_:
			intent_label.text = "意图: ???"
			intent_label.add_theme_color_override("font_color", Color.GRAY)


## 执行回合行动
func execute_turn(player: Player) -> void:
	match current_intent:
		IntentType.ATTACK:
			await _do_attack(player)
		IntentType.DEFEND:
			await _do_defend()

	action_completed.emit()


## 执行攻击
func _do_attack(player: Player) -> void:
	print("%s 攻击玩家，造成 %d 伤害" % [char_name, intent_value])
	player.take_damage(intent_value)
	await get_tree().create_timer(0.3).timeout


## 执行防御
func _do_defend() -> void:
	print("%s 获得护甲 %d" % [char_name, intent_value])
	gain_block(intent_value)
	await get_tree().create_timer(0.3).timeout


## 设置敌人数据
func setup(enemy_name: String, hp: int) -> void:
	char_name = enemy_name
	max_hp = hp
	current_hp = hp
	# 敌人颜色
	if character_rect:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.5, 0.2, 0.2)
		style.border_color = Color(0.8, 0.4, 0.4)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		character_rect.add_theme_stylebox_override("panel", style)
	_update_display()
