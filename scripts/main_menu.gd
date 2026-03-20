## 主菜单场景
extends Control

var title_label: Label
var start_button: Button
var quit_button: Button


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	# 背景
	var background := ColorRect.new()
	background.color = Color(0.08, 0.08, 0.12)
	background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background)

	# 标题
	title_label = Label.new()
	title_label.text = "杀戮尖塔"
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	title_label.position = Vector2(screen_size.x / 2 - 150, screen_size.y / 3 - 50)
	title_label.custom_minimum_size = Vector2(300, 80)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title_label)

	# 副标题
	var subtitle := Label.new()
	subtitle.text = "Godot 复刻版"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	subtitle.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 3 + 40)
	subtitle.custom_minimum_size = Vector2(200, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	# 开始按钮
	start_button = Button.new()
	start_button.text = "开始游戏"
	start_button.position = Vector2(screen_size.x / 2 - 80, screen_size.y / 2)
	start_button.custom_minimum_size = Vector2(160, 50)
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)

	# 退出按钮
	quit_button = Button.new()
	quit_button.text = "退出游戏"
	quit_button.position = Vector2(screen_size.x / 2 - 80, screen_size.y / 2 + 70)
	quit_button.custom_minimum_size = Vector2(160, 50)
	quit_button.add_theme_font_size_override("font_size", 20)
	quit_button.pressed.connect(_on_quit_pressed)
	add_child(quit_button)


func _on_start_pressed() -> void:
	# 重置玩家状态
	GameState.reset_player()
	# 切换到地图场景
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
