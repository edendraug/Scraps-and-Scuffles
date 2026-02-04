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

@export_category("Game Speed Buttons")
@export var half_speed_btn: Button
@export var normal_speed_btn: Button
@export var double_speed_btn: Button

@export var camera_zoom_slider: HSlider

var player: CharacterBody2D
var inventory: InventoryManager
@onready var camera: Camera2D = $"../../Level Camera"

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
	
	# Setup Camera Zoom Slider
	#camera_zoom_slider.min_value = camera.max_zoom
	#camera_zoom_slider.max_value = camera.min_zoom

func _process(delta: float) -> void:
	if InputManager.is_action_pressed(0, "dev_key"):
		visible = true
	else: visible = false
	
	update_labels()
	
	handle_camera()

func handle_camera():
	camera.zoom_modifier = camera_zoom_slider.value

func update_labels() -> void:
	timer_label.text = str(DEV_GameManager.convert_time_to_string())

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


func _on_half_speed_button_down() -> void:
	Engine.time_scale = 0.5


func _on_normal_speed_button_down() -> void:
	Engine.time_scale = 1.0


func _on_double_speed_button_down() -> void:
	Engine.time_scale = 2
