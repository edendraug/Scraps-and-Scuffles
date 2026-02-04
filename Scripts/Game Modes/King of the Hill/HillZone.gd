extends Area2D
class_name HillZone

var radius: float = 120.0 # Default, should be set via set_radius()
@export var default_color: Color = Color(0.5, 0.5, 0.5, 0.3) # Gray
@export var scoring_color: Color = Color(0.2, 0.8, 0.2, 0.1) # Green
@export var contested_color: Color = Color(0.8, 0.2, 0.2, 0.3) # Red
@export var warning_color: Color = Color(0.9, 0.9, 0.1, 0.3) # Yellow

var is_contested: bool = false
var is_scoring: bool = false
var is_warning: bool = false
var warning_flash_timer: float = 0.0
var scoring_flash_timer: float = 0.0

# Visual components
var collision_shape: CollisionShape2D
var visual_circle: Node2D

signal player_entered_hill(player: Node2D)
signal player_exited_hill(player: Node2D)

func _ready() -> void:
	# Setup collision
	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Collision setup - detect players
	collision_layer = 0 # Don't be a physical object
	collision_mask = 0b1000 # Detect layer 4 (players)
	
	# Setup visual
	visual_circle = Node2D.new()
	add_child(visual_circle)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_warning:
		warning_flash_timer += delta
	if is_scoring:
		scoring_flash_timer += delta
	queue_redraw()

func _draw():
	var color = default_color
	
	if is_warning:
		# Flash yellow
		var flash = sin(warning_flash_timer * 10.0) * 0.5 + 0.5
		color = warning_color
		color.a = 0.2 + flash * 0.3
	elif is_contested:
		color = contested_color
	elif is_scoring:
		# Slow green pulse when someone is scoring
		var pulse = sin(scoring_flash_timer * 3.5) * 0.5 + 0.5
		color = scoring_color
		color.a = 0.1 + pulse * 0.1
	
	# Draw filled circle
	draw_circle(Vector2.ZERO, radius, color)
	
	# Draw dotted outline
	draw_dotted_circle(Vector2.ZERO, radius, Color.WHITE if not is_warning else Color.RED, 10.0)

func draw_dotted_circle(center: Vector2, r: float, color: Color, width: float):
	var points = 64
	var dash_length = 10.0
	var gap_length = 8.0
	var circumference = TAU * r
	var total_dash_gap = dash_length + gap_length
	var num_dashes = int(circumference/ total_dash_gap) + 1
	
	for i in range(num_dashes):
		var start_angle = (i * total_dash_gap / circumference) * TAU
		var end_angle = start_angle + (dash_length / circumference) * TAU
		
		var start_pos = center + Vector2(cos(start_angle), sin(start_angle)) * r
		var end_pos = center + Vector2(cos(end_angle), sin(end_angle)) * r
		
		draw_line(start_pos, end_pos, color, width)

func set_contested(contested: bool):
	is_contested = contested
	
	# If contested, can't be scoring
	if contested: 
		is_scoring = false

func set_scoring(scoring: bool):
	if scoring and not is_scoring:
		scoring_flash_timer = 0.0
	
	is_scoring = scoring
	
	# If scoring, casn't be contested
	if scoring:
		is_contested = false

func start_warning():
	is_warning = true
	warning_flash_timer = 0.0

func stop_warning():
	is_warning = false

func set_radius(new_radius: float):
	radius = new_radius
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = radius
	queue_redraw()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Players"):
		player_entered_hill.emit(body)

func _on_body_exited(body: Node2D):
	if body.is_in_group("Players"):
		player_exited_hill.emit(body)
