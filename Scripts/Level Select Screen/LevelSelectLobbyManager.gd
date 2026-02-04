extends Node
class_name LevelSelectLobbyManager

@export var camera: LobbyCameraController
@export var character_selection_manager: CharacterSelectionManager
@export var grace_period_duration: float = 3.0
@export var winner_reveal_delay: float = 4.0

var votes_finalized: bool = false

var all_voted: bool = false
var grace_period_active: bool = false
var grace_timer: float = 0.0
var loading_level: bool = false

signal voting_complete
signal grace_period_started
signal level_loading(level: LevelData)

func _ready():
	# Connect to GameSettings
	GameSettings.level_voted.connect(_on_level_voted)
	GameSettings.player_joined.connect(_on_player_joined)
	GameSettings.player_left.connect(_on_player_left)
	
	# Player 0 should already be joined from main menu
	# Other players can join here

func _process(delta):
	if grace_period_active:
		grace_timer -= delta
		
		if grace_timer <= 0:
			finalize_voting()

func _input(event):
	# Handle addition players joining (press A to join)
	if loading_level or all_voted:
		return
	
	# Check for controller button press to join
	if event is InputEventJoypadButton and event.pressed:
		var device_id = event.device
		attempt_join_player(device_id)

func attempt_join_player(device_id: int):
	# Find next available player slot
	for player_id in range(GameSettings.max_players):
		if not GameSettings.is_player_joined(player_id):
			# Try to join
			if GameSettings.join_player(player_id, device_id):
				# CharacterSelectionManager will create cursor automatically
				print("Player ", player_id, "joined!")
				return

func _on_level_voted(player_id: int, level: LevelData):
	print("Vote changed - Player ", player_id, " voted for: ", level)
	
	# Don't process votes if already finalized
	if votes_finalized:
		print("  Votes already finalized, ignoring")
		return
	
	# Check if all players have voted (and actually have a vote - not null)
	var all_have_votes = true
	for pid in GameSettings.get_joined_player_ids():
		var vote = GameSettings.get_player_vote(pid)
		print("  Player ", pid, " vote: ", vote)
		if vote == null:
			all_have_votes = false
			break
	
	print("  All have votes: ", all_have_votes, " | all_voted: ", all_voted)
	
	# Check if all players have voted
	if all_have_votes and not all_voted:
		print("  Starting grace period!")
		start_grace_period()
	elif not all_have_votes and all_voted:
		# Someone changed their vote during grace period - cancel it!
		print("  Vote changed during grace period - canceling!")
		cancel_grace_period()
	
	

func start_grace_period():
	all_voted = true
	grace_period_active = true
	grace_timer = grace_period_duration
	
	print("All players voted! Grace period: ", grace_period_duration, " seconds")
	grace_period_started.emit()

func cancel_grace_period():
	all_voted = false
	grace_period_active = false
	grace_timer = 0.0
	
	print("Grace period canceled - vote changed")
	
	# Return camera to follow mode
	if camera:
		camera.set_camera_state((LobbyCameraController.CameraState.FOLLOW_PLAYERS))

func finalize_voting():
	grace_period_active = false
	votes_finalized = true
	
	print("Votes are locked in!")
	voting_complete.emit()
	
	# Disable all player movement
	disable_all_players()
	
	#Camera focuses on voted portals
	if camera:
		camera.set_camera_state(LobbyCameraController.CameraState.FOCUS_VOTED)
		
	# Wait for suspense
	await get_tree().create_timer(winner_reveal_delay).timeout
	# Calculate winner
	reveal_winner()

func reveal_winner():
	var winning_level = GameSettings.calculate_winning_level()
	
	if not winning_level:
		push_error("No winning level found")
		return
	
	print("Winning level: ", winning_level.level_name)
	
	#Camera zooms on winner
	if camera:
		camera.set_camera_state(LobbyCameraController.CameraState.FOCUS_WINNER)
	
	await get_tree().create_timer(2.0).timeout
	load_game_level(winning_level)

func disable_all_players():
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)
		if player.has_method("set_process"):
			player.set_process(false)

func load_game_level(level: LevelData):
	if loading_level:
		return
	
	loading_level = true
	
	print("Loading level: ", level.level_name)
	level_loading.emit(level)
	
	# Store selected level
	GameSettings.selected_level = level
	
	# Apply level bounds to settings
	level.apply_bounds_to_settings()
	
	# Apply all settings to game managers
	GameSettings.apply_settings_to_managers()
	
	# Load the level scene
	if level.level_scene_path.is_empty():
		push_error("Level has no scene path")
		return
	
	get_tree().change_scene_to_file(level.level_scene_path)

func _on_player_joined(player_id: int):
	# If voting was complete, reset it
	if all_voted:
		all_voted = false
		grace_period_active = false
		votes_finalized = false

func _on_player_left(player_id: int):
	# Check if we still have all votes
	if votes_finalized:
		return # Don't recalculate if already locked
	
	var all_have_votes = true
	for pid in GameSettings.get_joined_player_ids():
		if GameSettings.get_player_vote(pid) == null:
			all_have_votes = false
			break

	if all_have_votes and not all_voted:
		start_grace_period()
