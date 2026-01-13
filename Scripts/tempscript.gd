extends CharacterBody2D

@export var player_id := 1

@export var sprite : Sprite2D
@export var collider : CollisionShape2D
@export var anim : AnimationPlayer
@export var hit_cooldown : Timer

@onready var hitboxes_root: Node2D = $HitBoxesRoot
@onready var hitbox_side: Area2D = $HitBoxes/HitBoxSide
@onready var hitbox_up: Area2D = $HitBoxes/HitBoxUp
@onready var hitbox_down: Area2D = $HitBoxes/HitBoxDown

@onready var hitboxes := {
	"side": hitbox_side,
	"up": hitbox_up,
	"down": hitbox_down
}


@export_category(" Horizontal Movement")
@export var walk_speed := 350.0
@export var run_speed := 575.0
@export var acceleration := 3000.0
@export var air_acceleration := 1100.0
@export var friction := 3000.0
var last_direction := 1 #1 = right, -1 = left

@export_category("Jumping")
@export var gravity := 2000.0
var target_gravity := gravity
var applied_gravity
@export var fall_gravity_multiplier := 1.6
@export var jump_release_gravity_multiplier := 2.2
#Optional smoothing (very subtle, helps predicability)
@export var jump_release_blend := 0.25
@export var jump_velocity := -1000.0
@export var jump_cut_multiplier := 0.4
@export var coyote_time := 0.2
var coyote_timer := 0.0

@export_category("Wall Sliding/Jumping")
@export var wall_jump_velocity := 800.0
@export var wall_jump_angle := 70.0
@export var wall_slide_gravity_multiplier := 0.25
@export var max_wall_slide_speed := 120.0
@export var wall_coyote_time := 0.12
var wall_coyote_timer := 0.0

enum State {IDLE, MOVE, JUMP, FALL, CROUCH, UP, SLIDE, HIT}
var current_state := State.IDLE
@export var can_hit : bool = true

@export_category("Dev Stuff")
@onready var current_state_label: Label = $Node2D/CurrentState
@onready var misc_label: Label = $Node2D/MiscLabel


func _physics_process(delta: float) -> void:
	update_states()
	update_coyote_time(delta)
	handle_horizontal(delta)
	handle_vertical(delta)
	apply_gravity(delta)
	handle_jump()
	handle_hits(delta)
	move_and_slide()
	update_animations()
	update_dev_labels()

func update_states() -> void:
	match current_state:
		State.IDLE when velocity.x != 0:
			current_state = State.MOVE
		State.MOVE:
			if velocity.x == 0:
				current_state = State.IDLE
			if not is_on_floor() and velocity.y > 0:
				current_state = State.FALL
		State.JUMP when velocity.y > 0:
			current_state = State.FALL
		State.FALL when is_on_floor():
			if velocity.x == 0:
				current_state = State.IDLE
			else: current_state = State.MOVE
		State.FALL when not is_on_floor() and is_on_wall():
			current_state = State.SLIDE
		State.SLIDE:
			if is_on_floor():
				current_state = State.IDLE
			if not is_on_floor() and not is_on_wall():
				if velocity.y < 0:
					current_state = State.JUMP
				if velocity.y > 0 and wall_coyote_timer <= 0:
					current_state = State.FALL
		State.CROUCH: 
			if is_just_released("down"):
				current_state = State.IDLE
			if velocity.y < 0:
				current_state = State.JUMP
		State.UP:
			if is_just_released("up"):
				current_state = State.IDLE
			if velocity.y < 0:
				current_state = State.JUMP

func handle_horizontal(delta: float) -> void:
	var input_dir := get_axis("left", "right")
	var target_speed := 0.0
	
	#Flips X of all hitboxes
	if input_dir != 0:
		last_direction = sign(input_dir)
	hitboxes_root.scale.x = last_direction	
	
	if current_state != State.CROUCH and current_state != State.UP:
		if input_dir != 0:
			var speed := run_speed if is_pressed("run") else walk_speed
			target_speed = input_dir * speed
			var accel := acceleration if is_on_floor() else air_acceleration
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func handle_vertical(delta) -> void:
	if is_pressed("down") and is_on_floor():
		current_state = State.CROUCH
		velocity.x = move_toward(velocity.x, 0.0, friction/2.5 * delta)
	if is_pressed("up") and is_on_floor():
		current_state = State.UP
		velocity.x = move_toward(velocity.x, 0.0, friction/2.5 * delta)

func apply_gravity(delta: float) -> void:
	var gravity_scale := 1.0
	#target_gravity = gravity
	
	match current_state:
		State.SLIDE:
			gravity_scale = wall_slide_gravity_multiplier
		State.JUMP:
			if not is_pressed("jump"):
				gravity_scale = jump_release_gravity_multiplier
		State.FALL:
			gravity_scale = fall_gravity_multiplier
		
	velocity.y += gravity * gravity_scale * delta
	
	if current_state == State.SLIDE:
		velocity.y = min(velocity.y, max_wall_slide_speed)

func update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if is_on_wall() and not is_on_floor():
		wall_coyote_timer = wall_coyote_time
	elif not is_on_wall() and not is_on_floor():
		wall_coyote_timer -= delta

func get_wall_jump_direction(wall_normal: Vector2) -> Vector2:
	#Convert degrees to radians
	var angle_rad := deg_to_rad(wall_jump_angle)
	#Build direction pointing right at the given angle
	var dir := Vector2(cos(angle_rad), -sin(angle_rad))
	#Flip direction based on which wall we're on
	dir.x *= sign(wall_normal.x)
	return dir.normalized()

func handle_jump() -> void:
	if is_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity
		coyote_timer = 0
		current_state = State.JUMP

	if is_just_pressed("jump") and current_state == State.SLIDE:
		if wall_coyote_timer > 0:
			var wall_normal := get_wall_normal()
			var jump_dir := get_wall_jump_direction(wall_normal)
			velocity = jump_dir * wall_jump_velocity
			wall_coyote_timer = 0
		
	#Variable jump height
	if is_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

func handle_hits(delta) -> void:
	if is_pressed("hit") and can_hit:
		hit_cooldown.start()
		can_hit = false
		anim.play("hit")


func update_animations() -> void:
	sprite.flip_h = last_direction < 0
	if can_hit:
		match current_state:
			State.IDLE:
				anim.play("idle")
			State.MOVE:
				anim.play("move")
			State.JUMP: 
				anim.play("jump")
			State.FALL:
				anim.play("fall")
			State.CROUCH:
				anim.play("crouch")
			State.UP:
				anim.play("up")
			State.SLIDE:
				anim.play("slide")

#region Input Access
func action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]

func is_pressed(action_name: String) -> bool:
	return Input.is_action_pressed(action(action_name))

func is_just_pressed(action_name: String) -> bool:
	return Input.is_action_just_pressed(action(action_name))

func is_just_released(action_name: String) -> bool:
	return Input.is_action_just_released(action(action_name))

func get_axis(neg: String, pos: String) -> float:
	return Input.get_axis(action(neg), action(pos))
	#endregion

#func _on_hit_cooldown_timeout() -> void:
	#print("can hit again")
	#can_hit = true

func update_dev_labels():
	current_state_label.text = str("State: ", State.find_key(current_state))
	misc_label.text = str(can_hit, hit_cooldown.time_left)
