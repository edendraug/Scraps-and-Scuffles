extends Node2D

#@export var resource_pickup_scene: PackedScene

func register_building(building: Node) -> void:
	if building.has_signal("destroyed"):
		building.destroyed.connect(_on_building_destroyed)

func _on_building_destroyed(data: BuildingData, pos: Vector2) -> void:
	if data.drop_resource == null:
		return
	for i in data.drop_amount:
		spawn_resource(data.drop_resource, pos)

func spawn_resource(resource_data: CraftableResource, pos: Vector2) -> void:
	if resource_data.pickup_scene == null:
		return
	
	var pickup := resource_data.pickup_scene.instantiate()
	add_child(pickup)
	
	pickup.global_position = pos
	pickup.setup(resource_data)
