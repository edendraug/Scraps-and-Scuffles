extends Node2D

@export var fall_speed: float = 500
@export var germination_time: float = 4.5
@export var growth_time: float = 1.5

#@export var wait_duration: float = 3.0
var wait_timer: float = 0.0

var target_position: Vector2
var building_data: BuildingData
var has_landed: bool = false

# Visual
@export var sprite: AnimatedSprite2D

#func _ready():
	## Create simple sprite for seed
	#sprite = AnimatedSprite2D.new()
	#add_child(sprite)
	## TODO: Set an actual seed texture here
	#sprite.texture = preload("res://icon.svg")
	#sprite.scale = Vector2(0.25, 0.25)

func initialize(target: Vector2, data: BuildingData):
	target_position = target
	building_data = data

func _process(delta):
	if has_landed:
		return
	
	wait_timer += delta
	
	if wait_timer > NaturalResourceSpawner.bounds_wait_time:
		# Fall downward
		global_position.y += fall_speed * delta
	
	# Check if reached target
	if global_position.y >= target_position.y:
		land()

func land():
	has_landed = true
	global_position = target_position
	
	sprite.play("germinate", 0.0)
	await get_tree().create_timer(germination_time / 3).timeout
	sprite.play("germinate")

	
	# Wait a moment, then grow tree
	await get_tree().create_timer(germination_time / 2).timeout
	
	if find_child("OffscreenMarker"):
		var offscreen_marker = find_child("OffscreenMarker")
		offscreen_marker.enabled = false
		offscreen_marker.queue_free()
	grow_tree()

func grow_tree():
	if not building_data or not building_data.building_scene:
		queue_free()
		return
	
	# Spawn the actual tree
	var tree = building_data.building_scene.instantiate()
	get_tree().current_scene.add_child(tree)
	tree.global_position = global_position
	
	# Initialize it
	if tree.has_method("initialize"):
		tree.initialize(building_data)

	
	# Animate growth
	if tree.has_method("tween_building"):
		tree.tween_building(Vector2.ZERO, growth_time, Tween.TRANS_ELASTIC, Tween.EASE_OUT)


	
	# Connect destruction tracking
	tree.tree_exited.connect(_on_tree_destroyed)
	
	# Remove seed
	queue_free()

func _on_tree_destroyed():
	# This is connected to the tree, not the seed
	# NaturalResourceSpawner already handles this via its own connection
	pass
