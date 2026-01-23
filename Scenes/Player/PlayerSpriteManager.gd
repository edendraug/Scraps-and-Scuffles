extends Node2D

var player : CharacterBody2D
var body_anim : AnimationPlayer
var arm_anim : AnimationPlayer

func _ready() -> void:
	player = get_parent()
	body_anim = get_node("AnimationPlayer")
	arm_anim = get_node("ArmsAnimationPlayer")
	

func _process(delta: float) -> void:
	update_body_animations()
	if !player.hitting:
		update_arm_animations()
	else:
		update_hitting_animations()


func update_body_animations():
	match player.current_state:
		player.State.IDLE:
			body_anim.play("idle")
		player.State.MOVE:
			if InputManager.is_action_pressed(player.player_id, "run"):
				body_anim.play("move", -1, 2)
			else:
				body_anim.play("move")
		player.State.JUMP:
			body_anim.play("jump")
		player.State.FALL:
			body_anim.play("fall")
		player.State.SLIDE:
			body_anim.play("slide")
		player.State.CROUCH:
			body_anim.play("crouch")
		player.State.LOOK_UP:
			body_anim.play("look_up")
func update_arm_animations():
	match player.current_state:
		player.State.IDLE:
			arm_anim.play("idle")
		player.State.MOVE:
			arm_anim.play("move")
		player.State.JUMP:
			arm_anim.play("jump")
		player.State.FALL:
			arm_anim.play("fall")
		player.State.SLIDE:
			arm_anim.play("slide")
		player.State.CROUCH:
			arm_anim.play("crouch")
		player.State.LOOK_UP:
			arm_anim.play("look_up")
func update_hitting_animations():
		match player.current_state:
			player.State.CROUCH:
				arm_anim.play("hit_down")
			player.State.LOOK_UP:
				arm_anim.play("hit_up")
			player.State.IDLE:
				arm_anim.play("hit_side")
			player.State.MOVE:
				arm_anim.play("hit_side")
			player.State.JUMP:
				arm_anim.play("hit_side")
			player.State.FALL:
				arm_anim.play("hit_side")
			player.State.SLIDE:
				arm_anim.play("hit_side")
