extends Node

@export var match_settings: MatchSettings

# Current game mode instance
var current_mode: GameMode = null

# Player tracking
var active_players: Array[Node] = []

# Match state
var match_active: bool = false
var match_time_elapsed: float = 0.0
var match_time_remaining: float = 0.0

# Signals
signal match_started
signal match_ended(winner_id: int)
signal score_updated(player_id: int, new_score: int)

func _ready() -> void:
	# Load default settings if none provided
	if not match_settings:
		match_settings = MatchSettings.new()
	add_to_group("game_mode_manager")

func _process(delta: float) -> void:
	if not match_active or not current_mode:
		return
	
	# Update timers
	match_time_elapsed += delta
	if match_settings.use_time_limit:
		match_time_remaining = match_settings.get_time_limit_seconds() - match_time_elapsed
		
		# Checktime limit
		if match_time_remaining <= 0:
			end_match_with_time_limit()
			return
	
	current_mode.update_mode(delta)

func start_match():
	print("=== MATCH STARTING ===")
	
	# Reset state
	match_active = true
	match_time_elapsed = 0.0
	match_time_remaining = match_settings.get_time_limit_seconds()
	
	# Find all players
	active_players = get_tree().get_nodes_in_group("Players")
	print("Players in match: ", active_players.size())
	
	# Load and start appropriate game mode
	load_game_mode(match_settings.game_mode)
	
	if current_mode:
		current_mode.start_mode(match_settings, active_players)
		
		# Connect mode signals
		current_mode.score_updated.connect(_on_mode_score_updated)
		current_mode.mode_ended.connect(_on_mode_ended)
	
	match_started.emit()

func end_match(winner_id: int = -1):
	if not match_active:
		return
	
	match_active = false
	
	print("=== MATCH ENDED ===")
	print("Winner: Player ", winner_id)
	
	if current_mode:
		current_mode.print_scores()
		current_mode.end_mode()
		
	match_ended.emit(winner_id)
	
	# Transition to Match End Scene
	await get_tree().create_timer(1.0).timeout # Brief pause before transition
	
	get_tree().change_scene_to_file("res://Scenes/Menus/Match_End.tscn")

func end_match_with_time_limit():
	# Time ran out- find player with highest score
	var winner_id = -1
	
	if current_mode:
		winner_id = current_mode.get_highest_score_player()
	
	end_match(winner_id)

# === GAME MODE MANAGEMENT ===
func load_game_mode(mode_type: MatchSettings.GameModeType):
	# Cleanup exisiting mode
	if current_mode:
		current_mode.cleanup()
		current_mode.queue_free()
		current_mode = null
	
	# Create new mode instance
	match mode_type:
		MatchSettings.GameModeType.KING_OF_THE_HILL:
			current_mode = KingOfTheHillMode.new()
			current_mode.name = "KingOfTheHillMode"
		MatchSettings.GameModeType.KEEP_AWAY:
			#TODO: Implement KeepAwayMode
			push_warning("Keep Away mode not implemented yet!")
			return
		MatchSettings.GameModeType.TAG:
			current_mode = TagMode.new()
			current_mode.name = "TagMode"
			return
	
	if current_mode:
		add_child(current_mode)
		print("Loaded game mode: ", current_mode.name)

# === SIGNAL HANDLERS ===
func _on_mode_score_updated(player_id: int, new_score: int):
	# Forawrd signal to match manager listeners
	score_updated.emit(player_id, new_score)

func _on_mode_ended(winner_id: int):
	# Mode declared a winner
	end_match(winner_id)

# === PUBLIC API ===
func get_player_score(player_id: int) -> int:
	if current_mode:
		return current_mode.get_player_score(player_id)
	return 0

func get_match_time_remaining() -> float:
	return match_time_remaining

func is_match_active() -> bool:
	return match_active
