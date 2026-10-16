extends HBoxContainer

@export var slot_texture := preload("res://assets/textures/planks_oak.png")

var slots := []
var selected := 0

func _ready():
    for i in range(9):
        var btn := Button.new()
        btn.name = "Slot" + str(i)
        btn.custom_minimum_size = Vector2(48, 48)
        btn.text = ""
        btn.pressed.connect(_on_slot_pressed.bind(i))
        add_child(btn)
        slots.append(btn)
    update_display()

func update_display():
    for i in range(9):
        var btn := slots[i]
        btn.modulate = Color(1,1,1) if i == selected else Color(0.7,0.7,0.7)
        # amount text via label not implemented for brevity; rely on tooltip or external UI

func set_selected(i: int):
    selected = i
    update_display()

func _on_slot_pressed(i: int):
    selected = i
    update_display()
    # notify player
    var player := get_tree().current_scene.get_node("World/Player")
    if player:
        player.selected_slot = i
