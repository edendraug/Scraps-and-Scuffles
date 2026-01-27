extends CharacterBody2D

@export var pickup_radius := 12.0
@export var data: CraftableResource
@export var amount := 1


var gravity := 2000.0 ##Base amount of gravity.
@export var friction := 0.9

@export var min_speed := 80.0
@export var max_speed := 380.0
@onready var spawn_timer: Timer = $SpawnTimer

var initial_impulse := Vector2.ZERO

var receiving_inventory : Node
var initialized := false

func setup(resource_data: CraftableResource) -> void:
	data = resource_data
	if data.icon:
		$Sprite2D.texture = data.icon
		
		# Set a random variation
		$Sprite2D.hframes = data.variations
		$Sprite2D.frame = randi_range(1, data.variations)
		# Flip X scale randomly
		var flip = bool(randi() % 2)
		if flip:
			$Sprite2D.scale.x = -2
		else: $Sprite2D.scale.x = 2

func _ready() -> void:
	add_to_group("Resources")
	var angle = randf() * TAU
	var speed = randf_range(min_speed, max_speed)
	initial_impulse = Vector2(cos(angle), sin(angle)) * speed
	velocity.x += initial_impulse.x
	velocity.y -= randf_range(min_speed, max_speed)
	
	spawn_timer.start()
	
func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	#After first frame, clear the impulse
	initial_impulse = Vector2.ZERO
	
	if is_on_floor():
		velocity.x *= friction
	
	move_and_slide()
	
	if receiving_inventory and initialized:
		collect(receiving_inventory)


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func collect(inventory) -> void:
	if !inventory:
		return
	
	inventory.add_resource(data, amount)
	queue_free()
	
	#var inventory := player.get_node("Inventory") as Inventory
	#inventory.add_resource(data, 1)
	
	queue_free()

func _on_spawn_timer_timeout() -> void:
	initialized = true

#func _on_area_2d_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	#if area.has_node("Inventory"):
		#collect(area.get_node("Inventory"))

func _on_body_entered(body: Node2D) -> void:
	if body.has_node("InventoryManager") and !receiving_inventory:
		receiving_inventory = body.get_node("InventoryManager")
	#if body.has_node("Inventory") and initialized:
		#collect(body.get_node("Inventory"))

func _on_body_exited(body: Node2D) -> void:
	if receiving_inventory:
		receiving_inventory = null
