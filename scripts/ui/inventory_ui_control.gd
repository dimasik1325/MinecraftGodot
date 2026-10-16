extends Control

func _ready():
    pass

func _on_close_pressed():
    get_tree().current_scene.get_node("World/Player").emit_signal("open_inventory")
