extends CharacterBody3D

@export var speed := 4.5
@export var jump_force := 8.0
@export var gravity := 20.0
@export var reach_distance := 5.0

var health := 20.0
var max_health := 20.0
var hunger := 20.0
var max_hunger := 20.0
var is_creative := false

@onready var camera := $Head/Camera3D
@onready var ray := $Head/Camera3D/RayCast3D
@onready var inventory := preload("res://scripts/inventory/inventory.gd").new()

var selected_slot := 0
var break_timer := 0.0

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    print("Player ready")

func _input(event):
    if event.is_action_pressed("pause"):
        get_tree().paused = not get_tree().paused
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
    if event.is_action_pressed("inventory"):
        emit_signal("open_inventory")
    if event.is_action_pressed("crafting"):
        emit_signal("open_crafting")
    if event.is_action_pressed("hotbar_1"): selected_slot = 0
    if event.is_action_pressed("hotbar_2"): selected_slot = 1
    if event.is_action_pressed("hotbar_3"): selected_slot = 2
    if event.is_action_pressed("hotbar_4"): selected_slot = 3
    if event.is_action_pressed("hotbar_5"): selected_slot = 4
    if event.is_action_pressed("hotbar_6"): selected_slot = 5
    if event.is_action_pressed("hotbar_7"): selected_slot = 6
    if event.is_action_pressed("hotbar_8"): selected_slot = 7
    if event.is_action_pressed("hotbar_9"): selected_slot = 8
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * 0.002)
        camera.rotation.x = clamp(camera.rotation.x - event.relative.y * 0.002, deg_to_rad(-80), deg_to_rad(80))

func _process(delta):
    # Movement
    var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction: Vector3 = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
    if dir.length() > 0:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = 0
        velocity.z = 0
    # Gravity and jump
    if is_on_floor():
        if Input.is_action_just_pressed("ui_accept"):
            velocity.y = jump_force
    else:
        velocity.y -= gravity * delta
    # Creative flight
    if is_creative:
        if Input.is_action_pressed("ui_up"):
            velocity.y = speed
        elif Input.is_action_pressed("ui_down"):
            velocity.y = -speed
    move_and_slide()
    # Interaction
    if Input.is_action_pressed("break_block"):
        break_timer += delta
        if break_timer > 0.15:
            break_timer = 0.0
            try_break()
    if Input.is_action_pressed("place_block"):
        try_place()

func try_break():
    ray.force_raycast_update()
    if ray.is_colliding():
        var pos := ray.get_collision_point()
        var hit_normal: Vector3 = ray.get_collision_normal()
        # approximate block position (simplified: floor to int near point)
        # For demo we use a simple block coordinate from world
        var world := get_tree().current_scene.get_node("World")
        if world:
            var block_pos := Vector3(floor(pos.x), floor(pos.y), floor(pos.z))
            # get chunk manager
            var cm := world.get_node("ChunkManager")
            if cm:
                var id := cm.get_block_world(int(block_pos.x), int(block_pos.y), int(block_pos.z))
                if id != 0 and id != 11:
                    cm.set_block_world(int(block_pos.x), int(block_pos.y), int(block_pos.z), 0)
                    # drop item
                    var db := preload("res://scripts/world/block_database.gd").new()
                    var drop_name: String = db.get_drop(id)
                    if drop_name != "none" and drop_name != "":
                        # spawn item entity (simplified: add to inventory)
                        inventory.add_item(drop_name, 1)

func try_place():
    ray.force_raycast_update()
    if ray.is_colliding():
        var pos := ray.get_collision_point()
        var hit_normal: Vector3 = ray.get_collision_normal()
        var block_pos := Vector3(floor(pos.x + hit_normal.x*0.5), floor(pos.y + hit_normal.y*0.5), floor(pos.z + hit_normal.z*0.5))
        # check not inside player
        if (block_pos - global_position).length() < 1.2: return
        var world := get_tree().current_scene.get_node("World")
        if world:
            var cm := world.get_node("ChunkManager")
            if cm:
                var current := cm.get_block_world(int(block_pos.x), int(block_pos.y), int(block_pos.z))
                if current == 0:
                    # get selected item
                    var item_name := inventory.get_slot_name(selected_slot) if inventory else ""
                    if item_name != "":
                        # map item to block id roughly
                        var block_id := 1  # default dirt
                        # simple mapping
                        if item_name == "grass_block": block_id = 1
                        elif item_name == "dirt": block_id = 2
                        elif item_name == "cobblestone": block_id = 3
                        elif item_name == "sand": block_id = 5
                        elif item_name == "planks": block_id = 9
                        elif item_name == "glass": block_id = 10
                        elif item_name == "torch": block_id = 18
                        elif item_name == "crafting_table": block_id = 16
                        elif item_name == "furnace": block_id = 17
                        elif item_name == "log_oak": block_id = 7
                        else: block_id = 1
                        cm.set_block_world(int(block_pos.x), int(block_pos.y), int(block_pos.z), block_id)
                        inventory.remove_slot_amount(selected_slot, 1)

func take_damage(amount: float):
    if is_creative: return
    health -= amount
    if health <= 0:
        health = max_health
        global_position = Vector3(0, 40, 0)
        # spawn death particles (simplified)

func restore_health(amount: float):
    health = min(health + amount, max_health)

func get_inventory() -> RefCounted:
    return inventory

signal open_inventory
signal open_crafting
