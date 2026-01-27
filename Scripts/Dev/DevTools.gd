extends Control

@export var start_with_resources: bool = true
@export var timer_label: Label
@export_category("Resource Buttons")
@export var give_rsc_wood: Button
@export var give_rsc_stone: Button
@export var give_rsc_energy: Button

@export_category("Resources")
@export var wood_rsc: CraftableResource
@export var stone_rsc: CraftableResource
@export var energy_rsc: CraftableResource

var player: CharacterBody2D
var inventory: InventoryManager

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Players")
	inventory = get_tree().get_first_node_in_group("Players").get_node("InventoryManager")
	
	if inventory:
		print("DevTools: Grab inventory success")
	else:
		print("DevTools: Failed to grab inventory")
	
	hide()
	await get_tree().process_frame
	if start_with_resources:
		give_resource(wood_rsc, 100)
		give_resource(stone_rsc, 100)
		give_resource(energy_rsc, 100)

func _process(delta: float) -> void:
	if InputManager.is_action_pressed(0, "dev_key"):
		visible = true
	else: visible = false
	
	update_labels()

func update_labels() -> void:
	timer_label.text = str(GameManager.convert_time_to_string())

func give_resource(resource: CraftableResource, amount: int) -> void:
	inventory.add_resource(resource, 100)
	
func _on_give_wood_pressed() -> void:
	give_resource(wood_rsc, 100)

func _on_give_stone_pressed() -> void:
	give_resource(stone_rsc, 100)

func _on_give_energy_pressed() -> void:
	give_resource(energy_rsc, 100)

func _on_give_each_pressed() -> void:
	give_resource(wood_rsc, 100)
	give_resource(stone_rsc, 100)
	give_resource(energy_rsc, 100)
