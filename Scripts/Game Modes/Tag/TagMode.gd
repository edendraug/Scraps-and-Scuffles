extends GameMode
class_name TagMode

# Tag state
var tagged_player_id: int = -1
var tag_immunity_timer: float = 0.0
var initial_grace_timer: float = 0.0

# Tag settings - These are set by GameSettings
var points_drain_per_second: float = 1.0
var tag_immunity_duration: float = 2.0 # Seconds of immunity after being tagged
var initial_grace_period: float = 5.0 # Grace period before tag

# Visual indicator
var tag_indicator: Node2D = null

# Signals
signal player_tagged(player_id: int)
signal tag_transferred(from_player_id: int, to_player_id: int)

func setup():
	print("Setting up Tag mode")
	
	# Initialize all players with target score
	player_scores.clear()
	for i in range(active_players.size()):
		player_scores[i] = match_settings.score_target
	
	# No one is tagged initially
	tagged_player_id = -1
	initial_grace_timer = initial_grace_period
	tag_immunity_timer = 0.0
	
	# Connect to player hit signals
	for player in active_players:
		if player.hit_manager.has_signal("player_hit_player"):
			player.hit_manager.player_hit_player.connect(_on_player_hit_player)
	
	print("All players start with ", match_settings.score_target, " points")
	print("Grace period: ", initial_grace_period, " seconds before tagging begins")

func update_mode(delta: float):
	# Handle initial grace period
	if initial_grace_timer > 0.0:
		initial_grace_timer -= delta
		
		if initial_grace_timer <= 0.0:
			print("Grace period over - tagging enabled!")
		
		return
	
	# Update immunity timer
	if tag_immunity_timer > 0.0:
		tag_immunity_timer -= delta
	
	# Drain points from tagged player
	if tagged_player_id != -1:
		drain_tagged_player_points(delta)
		update_tag_indicator_position()

func drain_tagged_player_points(delta: float):
	if tagged_player_id == -1:
		return
	
	# Drain points
	player_scores[tagged_player_id] -= points_drain_per_second * delta
	
	# Emit score update
	score_updated.emit(tagged_player_id, int(player_scores[tagged_player_id]))
	
	# Check if player reached zero
	if player_scores[tagged_player_id] <= 0:
		player_scores[tagged_player_id] = 0
		end_game_with_tagged_out()

func _on_player_hit_player(attacker_id: int, victim_id: int):
	# Skip if grace period is active
	if initial_grace_timer > 0.0:
		return
	
	# Skip if attacker has immunity
	if attacker_id == tagged_player_id and tag_immunity_timer > 0.0:
		return
	
	if tagged_player_id == -1:
		tag_player(victim_id)
		return
	
	# Transfer tag - tagged player hits someone else
	if attacker_id == tagged_player_id:
		transfer_tag(attacker_id, victim_id)


#func check_for_tag_transfers():
	## Only check if grace period is over
	#if initial_grace_timer > 0.0:
		#return
	#
	## Check all players for hits
	#for i in range(active_players.size()):
		#var player = active_players[i]
		#
		## Skip if this player has immunity
		#if i == tagged_player_id and tag_immunity_timer > 0.0:
			#continue
		#
		## Check if player hit someone (using hittable_objects array)
		#if "hittable_objects" in player and "hitting" in player:
			#if player.hitting and not player.hittable_objects.is_empty():
				## Player is attacking and has targets in range
				#for target in player.hittable_objects:
					## Check if target is a player
					#if not target.is_in_group("Players"):
						#continue
					#
					#var target_id = get_player_id_from_node(target)
					#
					#if target_id == -1:
						#continue
					#
					## First tag - if no one is tagged yet
					#if tagged_player_id == -1:
						#tag_player(target_id)
						#return
					#
					## Transfer tag - tagged player hits someone else
					#elif i == tagged_player_id and target_id != tagged_player_id:
						#transfer_tag(i, target_id)
						#return

func tag_player(player_id: int):
	# Initial tag - mark this player as it
	tagged_player_id = player_id
	tag_immunity_timer = tag_immunity_duration
	
	print("Player ", player_id, " has been tagged! They are now IT!")
	player_tagged.emit(player_id)
	
	# Create visual indicator
	create_tag_indicator()

func transfer_tag(from_player_id: int, to_player_id: int):
	# Transfer tag from one player to another
	print("Tag transferred from Player ", from_player_id, " to Player ", to_player_id)
	
	tagged_player_id = to_player_id
	tag_immunity_timer = tag_immunity_duration
	
	tag_transferred.emit(from_player_id, to_player_id)
	
	# Update indicator to follow new player
	update_tag_indicator_position()

func create_tag_indicator():
	print("Creating tag indicator for player ", tagged_player_id)
	# Create a visual indicator above the tagged player
	if tag_indicator:
		tag_indicator.queue_free()
	
	tag_indicator = Node2D.new()
	tag_indicator.name = "TagIndicator"
	
	# Add to the first player's parent(Level/World)
	if tagged_player_id < active_players.size() and active_players[tagged_player_id]:
		var player = active_players[tagged_player_id]
		player.get_parent().add_child(tag_indicator)
	
	print("Tag indicator added to scene tree: ", tag_indicator.is_inside_tree())
	
	# Create a simple sprite/icon
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg") # TODO Replaced with actual icon
	sprite.scale = Vector2(0.3, 0.3)
	sprite.position = Vector2(0, -90) # Above players head
	sprite.modulate = Color(1.0, 0.3, 0.3) # Red tint for now
	tag_indicator.add_child(sprite)
	
	print("Sprite added, indicator position: ", tag_indicator.global_position)
	
	var tween = tag_indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(0.35, 0.35), 0.5)
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.5)
	
	update_tag_indicator_position()
	print("Final indicator position: ", tag_indicator.global_position)

func update_tag_indicator_position():
	# Move indicator to follow tagged player
	if not tag_indicator or tagged_player_id == -1:
		return
	
	if tagged_player_id >= active_players.size():
		return
	
	var tagged_player = active_players[tagged_player_id]
	if tagged_player:
		tag_indicator.global_position = tagged_player.global_position

func get_player_id_from_node(node: Node) -> int:
	# Get player_id from a player node
	for i in range(active_players.size()):
		if active_players[i] == node:
			return i
	return -1

func end_game_with_tagged_out():
	# End game when tagged player reaches 0 points
	print("Player ", tagged_player_id, " reached 0 points!")
	
	# Find winner (highest score)
	var winner_id = get_highest_score_player()
	
	mode_ended.emit(winner_id)

func cleanup():
	# Remove tag indicator
	if tag_indicator:
		tag_indicator.queue_free()
		tag_indicator = null
	
	tagged_player_id = -1
	tag_immunity_timer = 0.0
	initial_grace_timer = 0.0
	
	
