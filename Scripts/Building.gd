extends StaticBody2D
class_name Building

@export var data: BuildingData
var current_health : int
var is_destroyed := false

signal destroyed(building_data, global_position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if data:
		current_health = data.health
	else: current_health = 1
	add_to_group("Buildings")
	
	ResourceDropManager.register_building(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hit(hit_pos: Vector2) -> void:
	if is_destroyed:
		return
	
	current_health -= 1
	print(self.name, ": I got hit! My new health is: ", current_health)
	
	if current_health <= 0:
		#pass
		destroy()

func destroy() -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	#Disables collisions immidiately
	for child in get_children():
		if child is CollisionObject2D:
			child.set_deferred("disabled", true)
	
	#Notify systems that care (drops, score, etc.)
	destroyed.emit(data, global_position)
	
	#Defer actual removal
	call_deferred("queue_free")
