extends Node

@export var day_length := 240.0

var time_of_day := 30.0  # 0-240, dawn around 30, noon 60, sunset 120, night 180

func _process(delta):
    time_of_day += delta * (240.0 / day_length)
    if time_of_day >= 240.0:
        time_of_day = 0.0
    update_environment()

func update_environment():
    # Update directional light color/energy based on time
    var light := get_tree().current_scene.get_node_or_null("World/DirectionalLight3D")
    if light:
        if time_of_day < 30:
            light.light_color = Color(0.2, 0.2, 0.4)
            light.light_energy = 0.2
        elif time_of_day < 120:
            var t := (time_of_day - 30) / 90.0
            light.light_color = Color(1.0, 0.9, 0.7).lerp(Color(0.3, 0.4, 0.8), 1.0 - t)
            light.light_energy = 0.2 + 1.0 * t
        elif time_of_day < 180:
            var t := (time_of_day - 120) / 60.0
            light.light_color = Color(0.3, 0.4, 0.8).lerp(Color(0.05, 0.05, 0.15), t)
            light.light_energy = 1.0 * (1.0 - t)
        else:
            light.light_color = Color(0.05, 0.05, 0.15)
            light.light_energy = 0.05
