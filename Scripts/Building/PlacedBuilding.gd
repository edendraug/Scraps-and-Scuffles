extends StaticBody2D
class_name PlacedBuilding

@export var building_data: BuildingData
var current_health: int
var grid_position: Vector2i

func _ready() -> void:
	# Initialize health if building_data is already set in editor/inspector
	if building_data:
		initialize(building_data)

func initialize(data: BuildingData):
	building_data = data
	current_health = data.max_health
	
	# Store grid position for later reference
	grid_position = BuildingManager.world_to_grid(global_position)

func take_damage(amount: int, hit_pos: Vector2) -> void:
	print(self.name, ": I got hit for %s damage" % amount)
	current_health -= amount
	
	# Visual feedback (flash white or shake)
	damage_feedback()
	
	if current_health <= 0:
		destroy()

func damage_feedback():
	#Simple white flash effect
	var original_modulate = modulate
	modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = original_modulate

func destroy():
	# Drop resources (partial refund)
	drop_resources()
	
	# Unregister from BuildingManager
	BuildingManager.unregister_building(self)
	
	#Destruction effect (optional - add particles, sound etc.)
	destruction_effect()
	
	queue_free()

func drop_resources():
	if not building_data or not building_data.drop_resources_on_destroy:
		return
	
	# Calculate drop percentage based on building type
	var drop_percent = building_data.get_grop_percentage()
	
	var wood_drop = int(building_data.wood_cost * drop_percent)
	var stone_drop = int(building_data.stone_cost * drop_percent)
	var energy_drop = int(building_data.energy_cost * drop_percent)
	
	# Spawn resource pickups at this position
	if wood_drop > 0:
		spawn_resource_pickup("wood", wood_drop)
	if stone_drop > 0:
		spawn_resource_pickup("stone", stone_drop)
	if energy_drop > 0:
		spawn_resource_pickup("energy", energy_drop)

func spawn_resource_pickup(resource_type: String, amount: int):
	var resource_data = InventoryManager.get_resource_by_name(resource_type)
	if not resource_data or not resource_data.pickup_scene:
		push_warning("PlacedBuilding: Cannot spawn pickup for '%s' - missing resource data or pickup scene" % resource_type)
		return
	
	# Spawn each pickup with slight random offset
	for i in range(amount):
		var pickup = resource_data.pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		
		#Random offset so pickups don't stack perfectly
		var offset = Vector2(randf_range(-20,20), randf_range(-20,20))
		pickup.global_position = global_position + offset
		
		if pickup.has_method("setup"):
			pickup.setup(resource_data)

func destruction_effect():
	# Placeholder for now
	pass
	
# Optional: Add method to repair/heal the building
func repair(amount: float):
	pass
