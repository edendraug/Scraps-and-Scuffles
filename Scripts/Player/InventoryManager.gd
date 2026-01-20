extends Node
class_name InventoryManager

# Resource references (assign in Inspector)
@export var wood_resource: CraftableResource
@export var stone_resource: CraftableResource
@export var energy_resource: CraftableResource

# Debug UI (optional)
@export var show_debug_ui: bool = true
@export var wood_label: Label
@export var stone_label: Label
@export var energy_label: Label

# Internal storage using CraftableResource as keys
var resources := {}

# String-to-resource lookup for building system
var resource_lookup := {}

static var instance: InventoryManager

func _ready():
	instance = self
	
	# Initialize storage
	if wood_resource:
		resources[wood_resource] = 0
		resource_lookup["wood"] = wood_resource
	if stone_resource:
		resources[stone_resource] = 0
		resource_lookup["stone"] = stone_resource
	if energy_resource:
		resources[energy_resource] = 0
		resource_lookup["energy"] = energy_resource
	
	update_debug_ui()

# Get CraftableResource by string name (for spawning pickups)
static func get_resource_by_name(resource_name: String) -> CraftableResource:
	if instance and instance.resource_lookup.has(resource_name):
		return instance.resource_lookup[resource_name]
	return null

#region === PICKUP SYSTEM METHODS (CraftableResource-based ) ===
func add_resource(resource: CraftableResource, amount: int = 1) -> void:
	if amount <= 0 or not resource:
		return
	
	resources[resource] = resources.get(resource, 0) + amount
	update_debug_ui()
	resource_collected(resource, amount)

func remove_resource(resource: CraftableResource, amount: int = 1) -> bool:
	if not resources.has(resource):
		return false
	if resources[resource] < amount:
		return false
	
	resources[resource] -= amount
	update_debug_ui()
	return true

func get_amount(resource: CraftableResource) -> int:
	return resources.get(resource, 0)

func has_resource(resource: CraftableResource, amount: int = 1) -> bool:
	return get_amount(resource) >= amount
#endregion

#region === BUILDING SYSTEM MEHTODS (String-based)===
func get_resources() -> Dictionary:
	return {
		"wood": get_amount(wood_resource) if wood_resource else 0,
		"stone": get_amount(stone_resource) if stone_resource else 0,
		"energy": get_amount(energy_resource) if energy_resource else 0
	}

# Deducts resources for building costs
func remove_resources(wood: int, stone: int, energy: int) -> bool:
	# Check if we have enough of all resource first
	if wood > 0 and not has_resource(wood_resource, wood):
		return false
	if stone > 0 and not has_resource(stone_resource, stone):
		return false
	if energy > 0 and not has_resource(energy_resource, energy):
		return false
	
	# Deduct all resources
	if wood > 0:
		remove_resource(wood_resource, wood)
	if stone > 0:
		remove_resource(stone_resource, stone)
	if energy > 0:
		remove_resource(energy_resource, energy)
	
	return true

# Add resources by string name (useful for debug/testing)
func add_resources_by_name(resource_name: String, amount: int = 1) -> void:
	if resource_lookup.has(resource_name):
		add_resource(resource_lookup[resource_name], amount)
#endregion

#region === DEBUG UI ===
func update_debug_ui() -> void:
	if not show_debug_ui:
		return
	
	if wood_label and wood_resource:
		wood_label.text = "%s: %d" % [wood_resource.display_name, get_amount(wood_resource)]
	if stone_label and stone_resource:
		stone_label.text = "%s: %d" % [stone_resource.display_name, get_amount(stone_resource)]
	if energy_label and energy_resource:
		energy_label.text = "%s: %d" % [energy_resource.display_name, get_amount(energy_resource)]
#endregion

#region === SINGALS & FEEDBACK ===
signal resource_added(resource: CraftableResource, amount: int)

func resource_collected(resource: CraftableResource, amount: int) -> void:
	resource_added.emit(resource, amount)
	# TODO: Add particle effects, sound, UI popup here
	# Example: spawn_pickip_feedback(resource, amount)

func spawn_pickup_feedback(resource: CraftableResource, amount: int) -> void:
	# Placeholder for visual/audio feedback
	# You can add particles, sounds, floating text, etc.
	pass
#endregion
