extends Camera2D

var targets : Array = []

@export var margin: Vector2 = Vector2(100,100)
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1

func _ready() -> void:
	targets = get_tree().get_nodes_in_group("Players")
	print(targets.size())
	
	var center = Vector2.ZERO
	for target in targets:
		center += target.global_position
	center /= targets.size()
	position = center

func _physics_process(delta: float) -> void:
	if targets.size() == 0:
		return
	
	# Calculate center position
	var center = Vector2.ZERO
	for target in targets:
		center += target.global_position
	center /= targets.size()
	position = lerp(position, center, .07)
	
	# Calculate zoom
	var rect = Rect2(position, Vector2.ONE)
	for target in targets:
		rect = rect.expand(target.global_position)
	# Add margin
	rect = rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	# Calculate requred zoom
	var viewport_size = get_viewport_rect().size
	var zoom_x = viewport_size.x / rect.size.x
	var zoom_y = viewport_size.y / rect.size.y
	var target_zoom = min(zoom_x, zoom_y)
	# Clamp zoom to prevent too close/too far
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	# Apply smooth zoom
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), zoom_speed)
