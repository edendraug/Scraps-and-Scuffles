extends CharacterBody2D

@export_category("Player Management")
@export var player_id := 0 ##Which player number this is.
@export var max_health := 6
var current_health: int

@export_category("DebugUI")
@onready var current_state_label: Label = $DebugUI/CurrentState
@onready var misc_label: Label = $DebugUI/MiscLabel

@export_category("Components")
@export var sprite_manager : Node2D
@export var collider : CollisionShape2D
@export var hit_manager: Node2D
@export var building_placer: BuildingPlacer
@export var shader: Shader


@export_category(" Horizontal Movement")
@export var walk_speed := 350.0 ##Base walking speed
@export var run_speed := 575.0 ##Speed when run button is held
@export var acceleration := 3000.0 ##How fast player can accelerate
@export var air_acceleration := 1100.0 ##Amount of control player has while in the air. Higher number = snappier movement
@export var friction := 3000.0 ##Friction player has with ground. Lower number = more slippy
var last_direction := 1 #1 = right, -1 = left
var input_dir : Vector2

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

enum State {IDLE, MOVE, JUMP, FALL, SLIDE, HIT, LOOK_UP, CROUCH}
var current_state := State.IDLE
var is_building := false

@export_category("Combat Stuff")
@export var hit_force: float = 1000.0
var can_hit : bool = true
@export var hitting : bool = false
var hittable_objects: Array = []
var hit_targets: Array = []
@export var stun_timer : Timer
@export var invincibility_timer : Timer
@export var attack_cooldown_timer : Timer
var stunned := false
var invincible := false

signal look_dir_changed(new_look_dir: int)
var look_dir: int = 1:
	set(value):
		if look_dir == value:
			return
		look_dir = value
		look_dir_changed.emit(look_dir)
	get: return look_dir
signal player_just_hit

func _ready() -> void:
	InputManager.register_player(player_id)
	current_health = max_health
	

func _process(delta: float) -> void:
	update_states()
	update_look_dir()
	handle_input()
	apply_gravity(delta)
	handle_movement(delta)
	
	update_coyote_time(delta)
	update_animations()
	update_dev_labels()

func update_states():
	if not is_on_floor() and not is_on_wall():
		if velocity.y < 0:
			current_state = State.JUMP
	elif not is_on_floor() and is_on_wall():
		current_state = State.SLIDE
	
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
		State.SLIDE:
			if is_on_floor():
				current_state = State.IDLE
			if not is_on_floor() and not is_on_wall():
				if velocity.y < 0:
					current_state = State.JUMP
				if velocity.y > 0 and wall_coyote_timer <= 0:
					current_state = State.FALL
		State.LOOK_UP when input_dir.y == 0:
			if velocity.x == 0:
				current_state = State.IDLE
			elif velocity.x != 0:
				current_state = State.MOVE
		State.CROUCH when input_dir.y == 0:
			if velocity.x == 0:
				current_state = State.IDLE
			elif velocity.x != 0:
				current_state = State.MOVE

func update_look_dir():
	# Vertical look overrides facing
	if input_dir.y > 0:
		look_dir = 2 # Up
	elif input_dir.y < 0:
		look_dir = 3 # Down
	# Horizontal facing only
	else:
		if last_direction < 0:
			look_dir = 0 # Left
		else:
			look_dir = 1 # Right

func handle_input():
	input_dir = InputManager.get_vector(
		player_id,
		"move_left", "move_right",
		"look_up", "look_down"
	)
	
	if InputManager.is_action_just_pressed(player_id, "jump"):
		jump(true, false) if current_state != State.SLIDE else jump(true, true)
	if InputManager.is_action_just_released(player_id, "jump"):
		jump(false, false) if current_state != State.SLIDE else jump(true, false)
	

	if InputManager.is_action_pressed(player_id, "attack") and !is_building:
		attack()

#region === MOVEMENT AND PHYSICS ===
func apply_gravity(delta: float) -> void:
	#velocity.y += gravity * delta
	var gravity_scale := 1.0

	match current_state:
		#SLIDE CAUSES ISSUES FOR SOME REASON, BUT IT"S NOT NECESSARY
		#State.SLIDE:
			#gravity_scale = wall_slide_gravity_multiplier
		State.JUMP:
			if  InputManager.is_action_just_released(player_id, "jump"):
				gravity_scale = jump_release_gravity_multiplier
		State.FALL:
			gravity_scale = fall_gravity_multiplier
		
	velocity.y += gravity * gravity_scale * delta
	
	if current_state == State.SLIDE and not InputManager.is_action_pressed(player_id, "look_down"):
		velocity.y = min(velocity.y, max_wall_slide_speed)

func handle_movement(delta) -> void:
	var target_speed := 0.0
	
	if input_dir.x != 0 and !stunned:
		last_direction = sign(input_dir.x)
	
	if input_dir.y != 0 and is_on_floor():
		halt_movement(input_dir.y)
	# Update State to MOVE
	if input_dir.x != 0 and !stunned:
		var speed := run_speed if InputManager.is_action_pressed(player_id, "run") else walk_speed
		target_speed = input_dir.x * speed
		var accel := acceleration if is_on_floor() else air_acceleration
		
		# If not looking up or down
		if input_dir.y == 0:
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:		
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	
	move_and_slide()

func halt_movement(facing: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction/2)
	if facing > 0:
		current_state = State.LOOK_UP
	elif facing < 0:
		current_state = State.CROUCH

func jump(is_pressed: bool, is_sliding: bool) -> void:	
	# Standard jumping
	if !is_sliding: 
		if is_pressed and coyote_timer > 0:
			velocity.y = jump_velocity
			coyote_timer = 0
			current_state = State.JUMP
	# Wall jumping
	if is_sliding and wall_coyote_timer > 0:
		var wall_normal := get_wall_normal()
		var jump_dir := get_wall_jump_direction(wall_normal)
		velocity = jump_dir * wall_jump_velocity
		wall_coyote_timer = 0
		current_state = State.JUMP
	
	# Cancel jump
	if !is_pressed and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
#endregion

#region === OTHER FEATURES ===
func attack():
	if !hitting:
		hitting = true
		player_just_hit.emit()
		attack_cooldown_timer.start()
		for i in hittable_objects:
			if i.get_parent().has_method("take_damage"):
				i.get_parent().take_damage(1, self.global_position)
			elif i.has_method("take_damage"):
				i.take_damage(1, self.global_position)

func take_damage(amount: int, hit_pos: Vector2) -> void:	
	var force_dir := (global_position - hit_pos).normalized()
	
	if !stunned and !invincible:
		velocity = force_dir * hit_force
		if current_health > 1:
			current_health -= 1
		else: 
			current_health = 0
			stun()
		print(name, ": I got hit!",)

func stun():
	update_shader(Color.WHITE)
	halt_movement(0)
	stunned = true
	print("stunned!")
	stun_timer.start()

func restore_health():
	current_health = max_health
	
#endregion

#region === HELPER FUNCTIONS ===
func get_wall_jump_direction(wall_normal: Vector2) -> Vector2:
	#Convert degrees to radians
	var angle_rad := deg_to_rad(wall_jump_angle)
	#Build direction pointing right at the given angle
	var dir := Vector2(cos(angle_rad), -sin(angle_rad))
	#Flip direction based on which wall we're on
	dir.x *= sign(wall_normal.x)
	return dir.normalized()

func update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if is_on_wall() and not is_on_floor():
		wall_coyote_timer = wall_coyote_time
	elif not is_on_wall() and not is_on_floor():
		wall_coyote_timer -= delta

func update_animations():
	sprite_manager.scale.x = last_direction

# PLACEHOLDER SHADER STUFF FOR LATER VISUALS
func update_shader(color):
	sprite_manager.rendered_sprite.material = sprite_manager.rendered_sprite.material.duplicate()
	sprite_manager.rendered_sprite.material.set_shader_parameter("line_color", color)
#endregion

#region === SIGNALS ===
func _on_stun_timer_timeout() -> void:
	stunned = false
	restore_health()
	invincible = true
	invincibility_timer.start()

func _on_invincibility_timer_timeout() -> void:
	invincible = false
	update_shader(Color.WHITE)
	

func _on_attack_cooldown_timer_timeout() -> void:
	hitting = false
	is_building = false
#endregion

#region === DEV STUFF ===
func update_dev_labels():
	current_state_label.text = str("State: ", State.find_key(current_state))
#endregion
