extends Control

func _ready():
    pass

func _on_play_pressed():
    get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_settings_pressed():
    get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_pressed():
    get_tree().quit()
