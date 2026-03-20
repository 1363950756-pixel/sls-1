## 能量显示UI
class_name EnergyDisplay extends Control

## 战斗状态
var battle_state: BattleState

var background: ColorRect
var energy_label: Label


func _ready() -> void:
	_setup_ui()
	# 如果 battle_state 已设置，更新显示
	if battle_state:
		_update_display(battle_state.current_energy, battle_state.max_energy)


## 设置战斗状态
func set_battle_state(state: BattleState) -> void:
	battle_state = state
	if battle_state:
		battle_state.energy_changed.connect(_on_energy_changed)
		_update_display(battle_state.current_energy, battle_state.max_energy)


func _setup_ui() -> void:
	custom_minimum_size = Vector2(60, 60)

	background = ColorRect.new()
	background.custom_minimum_size = Vector2(60, 60)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.8)
	style.border_color = Color(0.4, 0.6, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(30)
	background.add_theme_stylebox_override("panel", style)
	add_child(background)

	energy_label = Label.new()
	energy_label.position = Vector2(0, 15)
	energy_label.custom_minimum_size = Vector2(60, 30)
	energy_label.add_theme_font_size_override("font_size", 24)
	energy_label.add_theme_color_override("font_color", Color.WHITE)
	energy_label.add_theme_color_override("font_outline_color", Color.BLACK)
	energy_label.add_theme_constant_override("outline_size", 3)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.text = "3/3"
	background.add_child(energy_label)


func _on_energy_changed(current: int, maximum: int) -> void:
	_update_display(current, maximum)


func _update_display(current: int, maximum: int) -> void:
	if not energy_label:
		return

	energy_label.text = "%d/%d" % [current, maximum]

	var style: StyleBoxFlat = background.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if current == 0:
			style.bg_color = Color(0.5, 0.2, 0.2)
		elif current < maximum:
			style.bg_color = Color(0.3, 0.4, 0.6)
		else:
			style.bg_color = Color(0.2, 0.4, 0.8)
