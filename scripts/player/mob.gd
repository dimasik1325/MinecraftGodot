extends CharacterBody3D

@export var health := 10.0
@export var speed := 2.0
@export var chase_range := 15.0
@export var is_hostile := true

func _physics_process(delta):
    var player := get_tree().current_scene.get_node_or_null("World/Player")
    if player:
        var direction: Vector3 = (player.global_position - global_position).normalized()
        if is_hostile and global_position.distance_to(player.global_position) < chase_range:
            velocity = direction * speed
        else:
            # wander
            velocity = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized() * speed * 0.3
    velocity.y -= 10.0 * delta
    move_and_slide()
