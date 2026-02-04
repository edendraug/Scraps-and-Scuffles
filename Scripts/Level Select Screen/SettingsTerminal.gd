extends Area2D
class_name SettingsTerminal

@export var settings_ui: Control # Reference to the settings menu UI

var player_at_terminal: Node2D = null
var ui_open: bool = false

signal terminal_activated(player: Node2D)
signal terminal_deactivated

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collisions to detect players
	collision_layer = 0
	collision_mask = 0b1000 # Layer 4 (players)
	
	# Hide UI initially
	if settings_ui:
		settings_ui.hide()

func _process(delta: float) -> void:
	# Check for interaction input
	if player_at_terminal and not ui_open:
		var player_id = get_player_id(player_at_terminal)
		if player_id != -1:
			if InputManager.is_action_just_pressed(player_id, "confirm"):
				open_terminal()
	
	if ui_open and player_at_terminal:
		var player_id = get_player_id(player_at_terminal)
		if player_id != -1:
			if InputManager.is_action_just_pressed(player_id, "cancel"):
				close_terminal()

func open_terminal():
	if not settings_ui:
		return
	
	ui_open = true
	settings_ui.show()
	terminal_activated.emit(player_at_terminal)
	
	# TODO: Optionally pause player movement or show cursor
	print("Settings terminal opened")

func close_terminal():
	if not settings_ui:
		return
	
	ui_open = false
	settings_ui.hide()
	terminal_deactivated.emit()
	
	print("Settings terminal closed")

func _on_body_entered(body: Node2D):
	if body.is_in_group("Players") and not player_at_terminal:
		player_at_terminal = body
		# TODO: Show "Press [button] to intereact" prompt

func _on_body_exited(body: Node2D):
	if body == player_at_terminal:
		if ui_open:
			close_terminal()
		player_at_terminal = null

func get_player_id(player: Node2D):
	if player.has_method("get_player_id"):
		return player.get_player_id()
	if "player_id" in player:
		return player.player_id
	return -1
