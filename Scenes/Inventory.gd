extends Node

class_name Inventory

@export var debug_labels_root: NodePath

@export var wood_resource: CraftableResource
@export var stone_resource: CraftableResource
@export var energy_resource: CraftableResource

@onready var wood_label: Label = $"../DebugUI/LabelsContainer/WoodLabel"
@onready var stone_label: Label = $"../DebugUI/LabelsContainer/StoneLabel"
@onready var energy_label: Label = $"../DebugUI/LabelsContainer/EnergyLabel"

var resources := {
	wood_resource: 0,
	stone_resource: 0,
	energy_resource: 0
} # Dictionary[CraftableResource, int]

func update_debug_ui() -> void:
	wood_label.text = "%s: %d" % [wood_resource.display_name, get_amount(wood_resource)]
	stone_label.text = "%s: %d" % [stone_resource.display_name, get_amount(stone_resource)]
	energy_label.text = "%s: %d" % [energy_resource.display_name, get_amount(energy_resource)]
		
func add_resource(resource: CraftableResource, amount: int = 1) -> void:
	if amount <= 0:
		return
		
	resources[resource] = resources.get(resource, 0) + amount
	update_debug_ui()
	

func remove_resource(resource: CraftableResource, amount: int = 1) -> bool:
	if not resources.has(resource):
		return false
	if resources[resource] < amount:
		return false
	
	resources[resource] -= amount
	if resources[resource] <= 0:
		resources.erase(resource)
	
	update_debug_ui()
	return true

func get_amount(resource: CraftableResource) -> int:
	return resources.get(resource, 0)

func has_resource(resource: CraftableResource, amount: int = 1) -> bool:
	return get_amount(resource) >= amount
