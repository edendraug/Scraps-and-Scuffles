extends Control
class_name SettingsOverlay

@export var close_btn: Button
@export var back_btn: Button

var main_menu: MainMenu

func _ready():
	main_menu = get_parent() as MainMenu
	
	# Connect close buttons
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	#if back_btn:
		#back_btn.pressed.connect(_on_close_pressed)

func _input(event: InputEvent):
	if not visible:
		return
	
	# Close with Escape of Back button
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_close_pressed():
	if main_menu:
		main_menu.close_settings()

func _on_back_pressed():
	pass
