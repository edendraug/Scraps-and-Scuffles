extends Node

# Match and spawn settings
var match_settings: MatchSettings
var spawn_settings: SpawnSettings

# Level selection
var available_levels: Array[LevelData] = []
var selected_level: LevelData = null
var level_votes: Dictionary = {} # player_id -> LevelData

# Player management
var joined_players: Dictionary = {} # player_id -> PlayerData
var max_players: int = 4

# Character selection
var available_characters: Array[CharacterData] = []

signal player_joined(player_id: int)
signal player_left(player_id: int)
signal character_selected(player_id: int, character: CharacterData)
signal level_voted(player_id: int, level: LevelData)
signal settings_changed

func _ready() -> void:
	# Initialize default settings
	if not match_settings:
		match_settings = MatchSettings.new()
	if not spawn_settings:
		spawn_settings = SpawnSettings.new()
	
	# Load available content
	load_levels()
	load_characters()

# === LEVEL MANAGEMENT ===
func load_levels():
	# Load all level data resources from directory
	available_levels.clear()
	
	var dir = DirAccess.open("res://Resources/Levels")
	if not dir:
		push_warning("GameSettings: Could not open levels directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var level_data = load("res://Resources/Levels/" + file_name) as LevelData
			if level_data:
				available_levels.append(level_data)
				print("Loaded level: ", level_data.level_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Total levels loaded: ", available_levels.size())

func get_available_levels() -> Array[LevelData]:
	return available_levels

func vote_for_level(player_id: int, level: LevelData):
	if not is_player_joined(player_id):
		return
	
	level_votes[player_id] = level
	print("Player ", player_id, " voted for: ", level.level_name if level else "none")
	level_voted.emit(player_id, level)

func get_player_vote(player_id: int) -> LevelData:
	return level_votes.get(player_id, null)

func calculate_winning_level() -> LevelData:
	if level_votes.is_empty():
		return null
	
	# Count votes for each level
	var vote_counts: Dictionary = {}
	
	for player_id in level_votes.keys():
		var level = level_votes[player_id]
		if level: vote_counts[level] = vote_counts.get(level, 0) + 1
	
	# Find level(s) with most votes
	var max_votes = 0
	var winning_levels: Array[LevelData] = []
	
	for level in vote_counts.keys():
		var votes = vote_counts[level]
		if votes > max_votes:
			max_votes = votes
			winning_levels.clear()
			winning_levels.append(level)
		elif votes == max_votes:
			winning_levels.append(level)
	
	# If tie, pick random
	if winning_levels.size() > 0:
		return winning_levels[randi() % winning_levels.size()]
	
	return null

func have_all_players_voted() -> bool:
	for player_id in joined_players.keys():
		if not level_votes.has(player_id):
			return false
	return true

func get_voted_levels() -> Array[LevelData]:
	# Returns unique list of levels that have votes
	var voted: Array[LevelData] = []
	for level in level_votes.values():
		if level and level not in voted:
			voted.append(level)
	return voted

# === CHARACTER MANAGEMENT ===
func load_characters():
	# Load all character data resources
	available_characters.clear()
	
	var dir = DirAccess.open("res://Resources/Characters")
	if not dir:
		push_warning("GameSettings: Could not open characters directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var char_data = load("res://Resources/Characters/" + file_name) as CharacterData
			if char_data:
				available_characters.append(char_data)
				print("Loaded character: ", char_data.character_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Total characters loaded: ", available_characters.size())

func get_available_characters() -> Array[CharacterData]:
	return available_characters

func set_player_character(player_id: int, character: CharacterData):
	if not is_player_joined(player_id):
		return
	
	joined_players[player_id].character = character
	print("Player ", player_id, " selected: ", character.character_name if character else "none")
	character_selected.emit(player_id, character)

func get_player_character(player_id: int) -> CharacterData:
	if joined_players.has(player_id):
		return joined_players[player_id].character
	return null

# === PLAYER MANAGEMENT ===
func join_player(player_id: int, device_id: int) -> bool:
	if player_id < 0 or player_id >= max_players:
		return false
	
	if joined_players.has(player_id):
		return false # Already joined
	
	var player_data = PlayerData.new()
	player_data.player_id = player_id
	player_data.device_id = device_id
	player_data.character = null # No character selected yet
	
	joined_players[player_id] = player_data
	
	print("Player ", player_id, " joined (device: ", device_id, ")")
	player_joined.emit(player_id)
	
	return true

func leave_player(player_id: int):
	if not joined_players.has(player_id):
		return
	
	joined_players.erase(player_id)
	level_votes.erase(player_id)
	
	print("Player ", player_id, " left")
	player_left.emit(player_id)

func is_player_joined(player_id: int) -> bool:
	return joined_players.has(player_id)

func get_joined_player_count() -> int:
	return joined_players.size()

func get_joined_player_ids() -> Array:
	return joined_players.keys()

func clear_all_players():
	joined_players.clear()
	level_votes.clear()

# === SETTIINGS ===

func reset_all_settings():
	match_settings.reset_to_defaults()
	spawn_settings.reset_to_defaults()
	settings_changed.emit()

func apply_settings_to_managers():
	# Apply settings to the actual game managers
	if GameModeManager:
		GameModeManager.match_settings = match_settings
	
	if NaturalResourceSpawner:
		NaturalResourceSpawner.spawn_settings = spawn_settings

# === UTILITY ===
class PlayerData:
	var player_id: int
	var device_id: int
	var character: CharacterData
