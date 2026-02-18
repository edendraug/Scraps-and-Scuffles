extends PlacedBuilding

@onready var info_label: Label = $Label


@export var fall_speed: float = 200.0
@export var gravity: float = 980.0
@export var bounce_strength_min: float = 150.0
@export var bounce_strength_max: float = 300.0
@export var bounce_damage: int = 2

var target_position: Vector2
var is_falling = true
var physics_enabled: bool = false
var velocity: Vector2 = Vector2.ZERO

# Rock sprite (randomly selected variant)
var rock_sprite: Sprite2D

# Track last hit to avoid repeated damage
var last_hit_object: Node = null
var hit_cooldown: float = 0.0
var wait_timer: float = 0.0

func _ready():
	super._ready()
	
	#We're a StaticBody2D, but we'll simulate physics during fall
	# Disable collision initially
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true

func initialize_rock(target: Vector2, data: BuildingData):
	if particle_emitter and data.particle_texture:
		particle_emitter.texture = data.particle_texture
	
	target_position = target
	building_data = data
	
	# Instantiate the rock scene
	var rock_instance = data.building_scene.instantiate()
	# Grab its sprite and re-parent it to this node
	for child in rock_instance.get_children():
		if child is Sprite2D:
			rock_sprite = child.duplicate()
			add_child(rock_sprite)
			break
	
	rock_instance.queue_free()
	
	# Apply random variant frame
	if rock_sprite and not data.building_variants.is_empty():
		rock_sprite.frame_coords = data.get_random_building_variant()
	
	rock_sprite.frame_coords.x -= 3
	print("frame_coords(", rock_sprite.frame_coords, ")")
	
	building_sprite = rock_sprite
	
	# Start falling
	velocity = Vector2(0, fall_speed)
	is_falling = true
	
	initialized = true

func _physics_process(delta):
	if not is_falling:
		return
	
	update_label()
	
	# Update hit cooldown
	if hit_cooldown > 0:
		hit_cooldown -= delta
	
	if hit_cooldown < 0:
		last_hit_object = null
	
	if is_falling:
		wait_timer += delta
	
	# Store old position for collision detection
	var old_pos = global_position
	
	if wait_timer > NaturalResourceSpawner.bounds_wait_time:
		# Apply gravity
		velocity.y += gravity * delta
		# Move manually (we're a StaticBody2D, can't use move_and_slide)
		global_position += velocity * delta
	
	if not physics_enabled:
		# Check if we've been interuupted by player or building
		check_for_inturruption()
	else:
		# If physics enabled, check for bounces
		check_for_bounce(old_pos)
		target_position.x = global_position.x
	
	# Check if reached target
	if global_position.y >= target_position.y:
		# If we're within horizontal range of target, land
		#if abs(global_position.x - target_position.x) < 50:
		land_at_target(global_position.x)
		if not physics_enabled:
			# Fell past target without physics - land anyway
			land_at_target()

func check_for_inturruption():	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + velocity.normalized() * 20
	)
	query.collision_mask = 0b1000 | 0b0010 # Layer4 (players) and layer 2 (buildings)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		enable_physics()
		bounce(result.collider)

func check_for_bounce(old_pos: Vector2):
	# Check if we hit something while physics is enabled
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		old_pos,
		global_position
	)
	query.collision_mask = 3 | 4 # Check all layers
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		bounce(result.collider)

func bounce(hit_object: Node):
	# Bounce upward
	velocity.y = -randf_range(bounce_strength_min, bounce_strength_max)
	
	# Small random horizontal variation
	velocity.x = randf_range(-50,50)
	
	# Damage what we hit (if it can take damage)
	if hit_cooldown <= 0:
		#if hit_object != last_hit_object:
		if hit_object.has_method("take_damage"):
			hit_object.take_damage(bounce_damage, global_position, 2000)
		
		last_hit_object = hit_object
		hit_cooldown = 0.2 # Cooldown to prevent rapid repeated hits

func enable_physics():
	physics_enabled = true
	
	# Enable collision
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false
	
	#Enable full collision
	collision_mask = 0b1111 # Collide with everything
	collision_layer = 1 # Be on layer 1

func land_at_target(x_offset: float = 0):
	print("frame_coords before landing: ", rock_sprite.frame_coords)
	is_falling = false
	rock_sprite.frame_coords.x += 3
	
	#Snap to target position
	global_position = target_position
	velocity = Vector2.ZERO
	
	# Enable collision
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false
	
	collision_mask = 1
	collision_layer = 3 # Be on layer 1
	
	if building_data:
		current_health = building_data.max_health
		grid_position = BuildingManager.world_to_grid(global_position)
		
		# Setup damage shader if available
		if has_method("setup_shader"):
			setup_shader()
	
	tree_exited.connect(_on_rock_destroyed)
	
	await get_tree().create_timer(2.0).timeout
	if find_child("OffscreenMarker"):
		var offscreen_marker = find_child("OffscreenMarker")
		offscreen_marker.enabled = false
		offscreen_marker.queue_free()

func _on_rock_destroyed():
	# Handled by NaturalResourceSpawner
	pass

func update_label():
	info_label.text = str(snapped(hit_cooldown, .05), ", ", last_hit_object)
