extends CharacterBody2D

@export_category("Player Management")
@export var player_id := 1 ##Which player number this is.


@export_category("DebugUI")
@onready var current_state_label: Label = $"DebugUI/CurrentState"
@onready var misc_label: Label = $"DebugUI/MiscLabel"

@export_category("Components")
@export var sprite : Sprite2D
@export var collider : CollisionShape2D
@export var anim : AnimationPlayer

@export_category("Hitboxes")
@export var hitboxes_root: Node2D

@export_category(" Horizontal Movement")
@export var walk_speed := 350.0 ##Base walking speed
@export var run_speed := 575.0 ##Speed when run button is held
@export var acceleration := 3000.0 ##How fast player can accelerate
@export var air_acceleration := 1100.0 ##Amount of control player has while in the air. Higher number = snappier movement
@export var friction := 3000.0 ##Friction player has with ground. Lower number = more slippy
var last_direction := 1 #1 = right, -1 = left
var input_dir := Vector2(0,0)

@export_category("Jumping")
@export var gravity := 2000.0 ##Base amount of gravity.
var target_gravity := gravity
var applied_gravity
@export var fall_gravity_multiplier := 1.6 ##Makes falling slightly faster than rising. Allows for snappier jumps.
@export var jump_release_gravity_multiplier := 2.2 ##Adds artificial gravity when character releases jump button before reaching apex.
#Optional smoothing (very subtle, helps predicability)
@export var jump_velocity := -1000.0 ##How high the player can jump
@export var jump_cut_multiplier := 0.4
@export var coyote_time := 0.2 ##Amount of time (in seconds) player has to jump after they have left the ground.
var coyote_timer := 0.0

@export_category("Wall Sliding/Jumping")
@export var wall_jump_velocity := 800.0 ##Jump power when attached to a wall
@export var wall_jump_angle := 70.0 ##The angle of the jump from a wall. 0 is the wall normal's direction.
@export var wall_slide_gravity_multiplier := 0.25 ##Artifically reduces gravity while player is attached to a wall. Lower number = slower slide
@export var max_wall_slide_speed := 120.0 ##The max speed at which the player slides while attached to a wall.
@export var wall_coyote_time := 0.12 ##Amount of time (in seconds) player has to jump after they have left a wall
var wall_coyote_timer := 0.0

enum State {IDLE, MOVE, JUMP, FALL, CROUCH, UP, SLIDE, HIT}
var current_state := State.IDLE

signal look_dir_changed(input_dir: Vector2)
enum LookDir {LEFT, RIGHT, UP, DOWN}
var look_dir := LookDir.RIGHT:
	set(value):
		if look_dir == value:
			return
		look_dir = value
		look_dir_changed.emit(look_dir)

@export_category("Combat Stuff")
var can_hit : bool = true
var hit_targets: Array = []
@export var stun_timer : Timer
@export var invincibility_timer : Timer
var stunned := false
var invincible := false

signal hit_action()
signal restore_health()

func _physics_process(delta: float) -> void:
	update_states()
	update_coyote_time(delta)
	handle_movement(delta)
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
	if input_dir != Vector2.ZERO:
		if input_dir.y == 0:
			if input_dir.x < 0:
				look_dir = LookDir.LEFT
			if input_dir.x > 0:
				look_dir = LookDir.RIGHT
		if input_dir.y < 0:
			look_dir = LookDir.UP
		if input_dir.y > 0:
			look_dir = LookDir.DOWN
	else:
		if last_direction < 0:
			look_dir = LookDir.LEFT
		if last_direction > 0:
			look_dir = LookDir.RIGHT

#region Basic Movement
func handle_movement(delta: float) -> void:
	#Sets direction of movement/looking from input
	input_dir = get_vector("left", "right", "up", "down")
	var target_speed := 0.0
	
	#Flips X of all hitboxes according to movement
	if input_dir.x != 0 and !stunned:
		last_direction = sign(input_dir.x)
	#hitboxes_root.scale.x = last_direction
	
	#Move horizontally
	if !stunned:
		if current_state != State.CROUCH and current_state != State.UP: #Only allows movement if not looking up or down
			if input_dir.x != 0:
				var speed := run_speed if is_pressed("run") else walk_speed
				target_speed = input_dir.x * speed
				var accel := acceleration if is_on_floor() else air_acceleration
				velocity.x = move_toward(velocity.x, target_speed, accel * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else: velocity.x = move_toward(velocity.x, 0.0, (friction/1.5) * delta)
	
	#Look vertically
	if !stunned:
		if is_pressed("down") and is_on_floor():
			current_state = State.CROUCH
			velocity.x = move_toward(velocity.x, 0.0, friction/2.5 * delta)
		if is_pressed("up") and is_on_floor():
			current_state = State.UP
			velocity.x = move_toward(velocity.x, 0.0, friction/2.5 * delta)
		
func handle_jump() -> void:
	#Standard jumping
	if is_just_pressed("jump") and coyote_timer > 0 and !stunned:
		velocity.y = jump_velocity
		coyote_timer = 0
		current_state = State.JUMP
	
	#Wall jumping
	if is_just_pressed("jump") and current_state == State.SLIDE:
		if wall_coyote_timer > 0:
			var wall_normal := get_wall_normal()
			var jump_dir := get_wall_jump_direction(wall_normal)
			velocity = jump_dir * wall_jump_velocity
			wall_coyote_timer = 0
		
	#Variable jump height
	if is_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
#endregion

func apply_gravity(delta: float) -> void:
	var gravity_scale := 1.0

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

func handle_hits(delta) -> void:
	if is_pressed("hit") and can_hit:
		can_hit = false
		anim.play("hit")
		hit_action.emit()
		for i in hit_targets:
			if i.has_method("hit") and hit_targets.size() > 0:
				i.hit(self.global_position)

func stun():
	stunned = true
	print("stunned!")
	stun_timer.start()

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

func get_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	return Input.get_vector(action(neg_x), action(pos_x), action(neg_y), action(pos_y))
	#endregion

func update_dev_labels():
	current_state_label.text = str("State: ", State.find_key(current_state))

func _on_hit_data(objects_to_hit: Array) -> void:
	hit_targets = objects_to_hit

func _on_stun_timer_timeout() -> void:
	stunned = false
	restore_health.emit()
	invincible = true
	invincibility_timer.start()

func _on_invincibility_timer_timeout() -> void:
		invincible = false
