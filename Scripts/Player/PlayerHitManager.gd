extends Node2D

@export var player: CharacterBody2D

@export_group("Hitboxes")
@export var hurtbox: Area2D
@export var hitbox_horizontal: Area2D
@export var hitbox_vertical: Area2D

@export_group("Raycast")
@export var wall_raycast: RayCast2D

@onready var hitboxes := {
	"horizontal": hitbox_horizontal,
	"vertical": hitbox_vertical
}

signal player_hit_player(attacker_id: int, victim_id: int)

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

func get_wall_normal() -> Vector2:
	if wall_raycast.is_colliding():
		var normal = wall_raycast.get_collision_normal().normalized()
		return normal
	return Vector2.ZERO

func is_on_wall() -> bool:
	var margin = player.wall_angle_margin
	if wall_raycast.is_colliding():
		#var normal = wall_raycast.get_collision_normal()
		var wall_angle = abs(wall_raycast.get_collision_normal().dot(Vector2.UP))
		if wall_angle < margin:
			return true
	return false

func update_hitboxes() -> void:	
	hitboxes["horizontal"].monitoring = false
	hitboxes["vertical"].monitoring = false
	
	hitboxes["horizontal"].visible = false
	hitboxes["vertical"].visible = false
	
	match look_dir:
		0: # Left
			hitboxes["horizontal"].monitoring = true
			hitboxes["horizontal"].scale.x = -1
			wall_raycast.scale.x = -1
		1: # Right
			hitboxes["horizontal"].monitoring = true
			hitboxes["horizontal"].scale.x = 1
			wall_raycast.scale.x = 1
		2: # Up
			hitboxes["vertical"].monitoring = true
			hitboxes["vertical"].scale.y = 1
		3: # Down
			hitboxes["vertical"].monitoring = true
			hitboxes["vertical"].scale.y = -1
			
	#CAN REMOVE LATER (TOGGLES HITBOX VISIBILITY FOR DEV
	match look_dir:
		0:
			hitboxes["horizontal"].visible = true
		1:
			hitboxes["horizontal"].visible = true
		2:
			hitboxes["vertical"].visible = true
		3:
			hitboxes["vertical"].visible = true

func take_damage(amount: int = 1, attacker_id: int = -1, hit_pos: Vector2 = Vector2.ZERO, force: float = 1000.0) -> void:
	var force_dir := (global_position - hit_pos).normalized()
	
	if !player.stunned and !player.invincible:
		player.velocity = force_dir * force
		if player.current_health > 0:
			player.current_health -= amount
		else: 
			player.current_health = 0
			player.stun()
		print("Player %d: I got hit by Player %d" % [self.player.player_id, attacker_id])
		player_hit_player.emit(attacker_id, self.player.player_id)

#region === HITBOX ENTERED/EXITED ===
func _on_horizontal_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	update_targets(area, true)

func _on_vertical_area_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	update_targets(area, true)

func _on_vertical_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	update_targets(area, false)

func _on_horizontal_area_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	update_targets(area, false)

func update_targets(area: Area2D, add: bool):
	# Add areas to hittable_targets
	if add:
		if area == hurtbox:
			return
		if not area.get_parent():
			return
		
		var target := area.get_parent()
		if not player.hittable_objects.has(target):
			player.hittable_objects.append(target)
	# Remove areas from array
	else:
		if not is_instance_valid(area):
			return
		
		var target := area.get_parent()
		player.hittable_objects.erase(target)
#endregion

func update_labels() -> void:
	#pass
	misc_label.text = str(player.hittable_objects)

func _on_player_look_dir_changed(new_look_dir: int) -> void:
	look_dir = new_look_dir
