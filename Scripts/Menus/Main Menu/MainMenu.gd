extends Control
class_name MainMenu

# Main menu buttons
@export var play_btn: Button
@export var settings_btn: Button
@export var quit_btn: Button

# Secondary buttons
@export var how_to_play_btn: Button
@export var credits_btn: Button

# Settings overlay
@export var settings_overlay: Control

# Info panels
@export var how_to_play_panel: Control
@export var credits_panel: Control

# Scene paths
@export var level_select_lobby_scene_path: String

func _ready():
	# Connect main buttons
	if play_btn:
		play_btn.pressed.connect(_on_play_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	
	# Connect secondary buttons
	if how_to_play_btn:
		how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	if credits_btn:
		credits_btn.pressed.connect(_on_credits_pressed)
	
	# Hide overlays initially
	if settings_overlay:
		settings_overlay.hide()
	if how_to_play_panel:
		how_to_play_panel.hide()
	if credits_panel:
		credits_panel.hide()
	
	# Focus the play button by default
	if play_btn:
		play_btn.grab_focus()

func _on_play_pressed():
	print("MainMenu: Starting game - going to Level Select Lobby")
	
	if level_select_lobby_scene_path:
		get_tree().change_scene_to_file(level_select_lobby_scene_path)
	else:
		print("  Error: Missing path to Level Select Lobby")

func _on_settings_pressed():
	print("MainMenu: Opening settings")
	if settings_overlay:
		settings_overlay.show()

func _on_quit_pressed():
	print("MainMenu: Quitting game")
	get_tree().quit()

func _on_how_to_play_pressed():
	print("MainMenu: Opening How to Play")
	if how_to_play_panel:
		how_to_play_panel.show()

func _on_credits_pressed():
	print("MainMenu: Opening Credits")
	if credits_panel:
		credits_panel.show()

# Called by settings overlay when closed
func close_settings():
	if settings_overlay:
		settings_overlay.hide()
	if settings_btn:
		settings_btn.grab_focus()

# Called by info panels when closed
func close_how_to_play():
	if how_to_play_panel:
		how_to_play_panel.hide()
	if how_to_play_btn:
		how_to_play_btn.grab_focus()

func close_credits():
	if credits_panel:
		credits_panel.hide()
	if credits_btn:
		credits_btn.grab_focus()
