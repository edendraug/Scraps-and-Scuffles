extends Control

@export var start_with_resources: bool = true

@export var give_rsc_wood: Button
@export var give_rsc_stone: Button
@export var give_rsc_energy: Button

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
		give_wood(wood_rsc, 100)
		give_stone(stone_rsc, 100)
		give_energy(energy_rsc, 100)

func _process(delta: float) -> void:
	if InputManager.is_action_pressed(0, "dev_key"):
		visible = true
	else: visible = false

func give_wood(resource: CraftableResource, amount: int) -> void:
	inventory.add_resource(wood_rsc, 100)

func give_stone(resource: CraftableResource, amount: int) -> void:
	inventory.add_resource(stone_rsc, 100)

func give_energy(resource: CraftableResource, amount: int) -> void:
	inventory.add_resource(energy_rsc, 100)
	
func _on_give_wood_pressed() -> void:
	give_wood(wood_rsc, 100)

func _on_give_stone_pressed() -> void:
	give_stone(stone_rsc, 100)

func _on_give_energy_pressed() -> void:
	give_energy(energy_rsc, 100)

func _on_give_each_pressed() -> void:
	give_wood(wood_rsc, 100)
	give_stone(stone_rsc, 100)
	give_energy(energy_rsc, 100)
