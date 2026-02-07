extends Control
class_name InfoPanel

@export var close_btn: Button
@export var title_label: Label
@export var content_label: RichTextLabel

# Reference to main menu
var main_menu: MainMenu

enum PanelType {
	HOW_TO_PLAY,
	CREDITS
}
@export var panel_type: PanelType = PanelType.HOW_TO_PLAY

func _ready() -> void:
	# Get reference to main menu
	main_menu = get_parent() as MainMenu
	
	# Connect close button
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# CLose with escape or back button
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_close_pressed():
	if main_menu:
		match panel_type:
			PanelType.HOW_TO_PLAY:
				main_menu.close_how_to_play()
			PanelType.CREDITS:
				main_menu.close_credits()
				
