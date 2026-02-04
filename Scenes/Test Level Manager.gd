extends Node

@export var override_spawn_settings : SpawnSettings
@export var override_match_settings : MatchSettings

func _ready():
	if override_spawn_settings:
		NaturalResourceSpawner.spawn_settings = override_spawn_settings
	if override_match_settings:
		GameModeManager.match_settings = override_match_settings
	#NaturalResourceSpawner.spawn_settings.min_x = -800
	#NaturalResourceSpawner.spawn_settings.max_x = 2000
	#NaturalResourceSpawner.spawn_settings.min_y = -200
	#NaturalResourceSpawner.spawn_settings.max_y = 1000
	
	#Connect signals (optional)
	GameModeManager.match_started.connect(_on_match_started)
	GameModeManager.match_ended.connect(_on_match_ended)
	GameModeManager.score_updated.connect(_on_score_updated)
	#GameModeManager.hill_relocated.connect(_on_hill_relocated)
	
	# Setup resource spawning
	NaturalResourceSpawner.spawn_initial_resources()
	NaturalResourceSpawner.start_spawning()
	
	# Start match after countdown
	await start_countdown()
	GameModeManager.start_match()

func start_countdown():
	#TODO: Implement 3-2-1 countdown with zoomed out camera
	print("3...")
	await get_tree().create_timer(1.0).timeout
	print("2...")
	await get_tree().create_timer(1.0).timeout
	print("1...")
	await get_tree().create_timer(1.0).timeout
	print("GO!")

func _on_match_started():
	print("Match has started!")

func _on_match_ended(winner_id: int):
	print("Match ended! Winner: Player ", winner_id)

func _on_score_updated(player_id: int, new_score: int):
	print("Player ", player_id, " score: ", new_score)
	# TODO: Update HUD

func _on_hill_relocated(new_positition: Vector2):
	print("Hill moved to: ", new_positition)
	# TODO: Pan camera or show indicator

func _exit_tree():
	NaturalResourceSpawner.stop_spawning()
