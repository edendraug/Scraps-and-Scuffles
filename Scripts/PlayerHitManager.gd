extends Node2D

@export var player: CharacterBody2D
@export var max_health := 6
var current_health : int
enum LookDir {LEFT, RIGHT, UP, DOWN}
var look_dir := LookDir.RIGHT:
	set(value):
		if look_dir == value:
			return
		look_dir = value
		update_hitboxes()
		
@export var hit_force: float = 1000.0

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

var hittable_objects: Array[Node] = []

@export_category("Dev Stuff")
@export var misc_label: Label

signal hit_data(objects_to_hit: Array)

func _ready() -> void:
	current_health = max_health
	if player:
		player.look_dir_changed.connect(_on_look_dir_changed)
		player.hit_action.connect(_on_hit_action)
		player.restore_health.connect(_on_restore_health)
	update_hitboxes()

func _process(delta: float) -> void:
	update_labels()
	handle_hits()

func handle_hits():
	pass

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
		LookDir.LEFT:
			hitboxes["left"].monitoring = true
		LookDir.RIGHT:
			hitboxes["right"].monitoring = true
		LookDir.UP:
			hitboxes["up"].monitoring = true
		LookDir.DOWN:
			hitboxes["down"].monitoring = true
			
	#CAN REMOVE LATER (TOGGLES HITBOX VISIBILITY FOR DEV
	match look_dir:
		LookDir.LEFT:
			hitboxes["left"].visible = true
		LookDir.RIGHT:
			hitboxes["right"].visible = true
		LookDir.UP:
			hitboxes["up"].visible = true
		LookDir.DOWN:
			hitboxes["down"].visible = true

func _on_look_dir_changed(dir: int) -> void:
	look_dir = dir

func _on_hit_action() -> void:
	hit_data.emit(hittable_objects)

func hit(hit_pos: Vector2) -> void:	
	var force_dir := (self.player.global_position - hit_pos).normalized()
	
	if self.player.stunned == false and self.player.invincible == false:
		player.velocity = force_dir * hit_force
		
		if self.current_health > 1:
			current_health -= 1
		else: 
			current_health = 0
			self.player.stun()
		
		print(self.name, ": I got hit!",)

func _on_restore_health() -> void:
	current_health = max_health


#region HITBOX ENTERED/EXITED
#region ENTERED
func _on_left_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not hittable_objects.has(target):
		hittable_objects.append(target)
	
func _on_right_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not hittable_objects.has(target):
		hittable_objects.append(target)
	
func _on_up_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not hittable_objects.has(target):
		hittable_objects.append(target)

func _on_down_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == hurtbox:
		return
	if not area.get_parent():
		return
	var target := area.get_parent()
	if not hittable_objects.has(target):
		hittable_objects.append(target)
#endregion

#region EXITED
func _on_left_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	hittable_objects.erase(target)
func _on_right_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	hittable_objects.erase(target)

func _on_up_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	hittable_objects.erase(target)

func _on_down_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not is_instance_valid(area):
		return
	var target := area.get_parent()
	hittable_objects.erase(target)
#endregion
#endregion

func update_labels() -> void:
	misc_label.text = str(current_health)
