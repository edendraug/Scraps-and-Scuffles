extends Resource
class_name MatchSettings

enum GameModeType {
	KING_OF_THE_HILL,
	KEEP_AWAY,
	TAG
}

# Game mode
@export var game_mode: GameModeType = GameModeType.KING_OF_THE_HILL

# Win conditions
@export var score_target: int = 100
@export var time_limit_minutes: float = 3.0
@export var use_score_target: bool = true # If false, only time limit matters
@export var use_time_limit: bool = true # If false, only score target matters

# King of the Hill specific
@export var hill_radius: float = 120.0
@export var hill_relocate_interval: float = 45.0
var hill_warning_time: float = 5.0 # Flash before relocating
var points_per_tick: int = 1
@export var tick_interval: float = 0.75

func reset_to_defaults():
	game_mode = GameModeType.KING_OF_THE_HILL
	score_target = 100
	time_limit_minutes = 3.0
	use_score_target = true
	use_time_limit = true
	hill_radius = 80.0
	hill_relocate_interval = 45.0

func get_time_limit_seconds() -> float:
	return time_limit_minutes * 60.0
