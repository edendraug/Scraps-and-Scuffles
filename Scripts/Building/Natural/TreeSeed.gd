extends Node2D

@export var fall_speed: float = 500
@export var germination_time: float = 4.5
@export var growth_time: float = 1.5

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
	grow_tree()

func grow_tree():
	if not building_data or not building_data.building_scene:
		queue_free()
		return
	
	# Get random variant
	var tree_scene = building_data.get_random_building_scene()
	if not tree_scene:
		queue_free()
		return
	
	# Spawn the actual tree
	var tree = tree_scene.instantiate()
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
