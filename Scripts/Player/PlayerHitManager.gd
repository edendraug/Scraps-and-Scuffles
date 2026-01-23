extends Node2D

@export var player: CharacterBody2D

@export_category("Hitboxes")
@export var hurtbox: Area2D
@export var hitbox_left: Area2D
@export var hitbox_right: Area2D
@export var hitbox_up: Area2D
@export var hitbox_down: Area2D

@onready var hitboxes := {
	"left": hitbox_left,
	"right": hitbox_right,
	"up": hitbox_up,
	"down": hitbox_down
}

var look_dir := 1:
	set(value):
		if look_dir == value:
			return
		look_dir = value
		update_hitboxes()

@export_category("Dev Stuff")
@export var misc_label: Label

func _ready() -> void:
	update_hitboxes()

func _process(delta: float) -> void:
	update_labels()

func update_hitboxes() -> void:	
	hitboxes["left"].monitoring = false
	hitboxes["right"].monitoring = false
	hitboxes["up"].monitoring = false
	hitboxes["down"].monitoring = false
	
	hitboxes["left"].visible = false
	hitboxes["right"].visible = false
	hitboxes["up"].visible = false
	hitboxes["down"].visible = false
	
	match look_dir:
		0:
			hitboxes["left"].monitoring = true
		1:
			hitboxes["right"].monitoring = true
		2:
			hitboxes["up"].monitoring = true
		3:
			hitboxes["down"].monitoring = true
			
	#CAN REMOVE LATER (TOGGLES HITBOX VISIBILITY FOR DEV
	match look_dir:
		0:
			hitboxes["left"].visible = true
		1:
			hitboxes["right"].visible = true
		2:
			hitboxes["up"].visible = true
		3:
			hitboxes["down"].visible = true

#region === HITBOX ENTERED/EXITED ===
#region === ENTERED ===
func _on_left_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not player.hittable_objects.has(target):
		player.hittable_objects.append(target)

func _on_right_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not player.hittable_objects.has(target):
		player.hittable_objects.append(target)

func _on_up_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not player.hittable_objects.has(target):
		player.hittable_objects.append(target)

func _on_down_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not player.hittable_objects.has(target):
		player.hittable_objects.append(target)
#endregion 

#region === EXITED ===
func _on_left_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	player.hittable_objects.erase(target)
func _on_right_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	player.hittable_objects.erase(target)

func _on_up_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	player.hittable_objects.erase(target)

func _on_down_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	player.hittable_objects.erase(target)
#endregion
#endregion

func update_labels() -> void:
	#pass
	misc_label.text = str(player.hittable_objects)

func _on_player_look_dir_changed(new_look_dir: int) -> void:
	look_dir = new_look_dir
